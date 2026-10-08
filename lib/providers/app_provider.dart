import 'dart:async' show Timer, unawaited;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/delete_result.dart';
import '../models/milestone.dart';
import '../models/progress.dart';
import '../models/photo_group.dart';
import '../services/ad_service.dart';
import '../services/feedback_service.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';
import '../services/purchase_service.dart';
import '../services/video_service.dart';
import '../utils/asset_utils.dart';
import '../utils/format.dart' as fmt;

const Set<String> kSupportedLanguages = {'en', 'es', 'de', 'fr', 'pt', 'it', 'pl'};

enum AppState { initial, loading, ready, permissionDenied, error }

class AppProvider extends ChangeNotifier {
  final PhotoService _service = PhotoService();
  final VideoService _videoService = VideoService();

  AppState state = AppState.initial;
  List<PhotoGroup> groups = [];
  LibraryStats stats = LibraryStats.empty;

  /// Whether the (lazy) photo grouping has actually run yet. Until then we only
  /// know the library size, not how many similar groups exist.
  bool groupsLoaded = false;

  /// True when the OS granted only partial access ("Selected photos" on
  /// Android 14+ / iOS limited library). The app then only sees a subset of
  /// the library — surfaced on the home screen so the user can fix it.
  bool limitedAccess = false;

  /// All photos, newest-first — used by Picture Swipe (every photo, not just
  /// duplicates). Loaded lazily, cached, and re-scanned by [reloadLibrary]
  /// whenever the library changes.
  List<AssetEntity> allPhotos = [];
  bool photosLoaded = false;

  int _totalPhotos = 0;

  // Persistent
  /// Lifetime bytes freed — confirmed deletions only (measured on Android,
  /// estimated on iOS; see PhotoService.assetBytes).
  int freedBytes = 0;
  int deletedCount = 0;

  /// Highest milestone reached (index into Milestone.ladder), −1 for none.
  int milestoneIndex = -1;

  /// Milestone index → when it was reached. Tiers set by the 1.3 migration
  /// have no date.
  Map<int, DateTime> milestoneDates = {};

  /// Running totals of measured photo sizes, for "room for about N photos".
  int _measuredBytes = 0;
  int _measuredCount = 0;
  String languageCode = 'en';
  bool isPro = false;

  /// Settings → Feedback. Both default on; mirrored into FeedbackService.
  bool soundsEnabled = true;
  bool hapticsEnabled = true;

  /// Ads show unless the user has unlocked Pro.
  bool get adsEnabled => !isPro;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    freedBytes = prefs.getInt('freed_bytes') ?? 0;
    deletedCount = prefs.getInt('deleted_count') ?? 0;
    _measuredBytes = prefs.getInt(_kMeasuredBytes) ?? 0;
    _measuredCount = prefs.getInt(_kMeasuredCount) ?? 0;
    await _loadMilestones(prefs);
    _loadProgress(prefs);
    // Default to the phone's language on first launch, else the saved choice.
    languageCode = prefs.getString('language_code') ?? _deviceLanguage();
    isPro = prefs.getBool('is_pro') ?? false;
    soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
    hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
    FeedbackService.instance
      ..soundsEnabled = soundsEnabled
      ..hapticsEnabled = hapticsEnabled;
    // Preload the sounds without holding up startup.
    unawaited(FeedbackService.instance.init());
    await _loadPendingDeletions();
    notifyListeners();

    // Only gather ad consent / initialize ads for non-Pro users. Pro users get
    // no ads, so there's no need to show them a consent form at all.
    if (adsEnabled) {
      AdService.instance.init();
    }

    // Set up in-app purchases; unlock Pro when a purchase/restore completes.
    PurchaseService.instance.init(onPurchased: () => setPro(true));

    // NOTE: we deliberately do NOT ask for notification permission here.
    // Stacking it onto first launch (on top of photo access, ATT and the ad
    // consent form) is a lot of prompts before the user has seen anything.
    // Reminders are set up after the first successful cleanup instead — see
    // [maybeSetupReminders].
  }

  /// The phone's language if we support it, otherwise English.
  String _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return kSupportedLanguages.contains(code) ? code : 'en';
  }

  static const String _kRemindersSetUp = 'reminders_set_up';

  /// Ask for notification permission and schedule the seasonal reminders —
  /// but only once, and only after the user has actually cleaned something up,
  /// so the request arrives when the app has demonstrated its value. Home
  /// calls it after the user leaves the Finished screen, never over it.
  /// Returns true if it asked just now.
  Future<bool> maybeSetupReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kRemindersSetUp) ?? false) return false;
    await prefs.setBool(_kRemindersSetUp, true);
    await _setupReminders();
    return true;
  }

  Future<void> _setupReminders() async {
    await NotificationService.instance.requestPermissions();
    await _scheduleReminders();
  }

  Future<void> _scheduleReminders() async {
    final s = AppStrings.of(languageCode);
    await NotificationService.instance.scheduleReminders(
      title: s.reminderTitle,
      body: s.reminderBody,
    );
  }

  Future<void> setPro(bool value) async {
    isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  // ─── Permission + Load ────────────────────────────────────────────────────

  /// Request/inspect photo access. Records whether access is only partial
  /// ("Selected photos") so the UI can warn that not everything is visible.
  Future<bool> _checkPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    limitedAccess = ps == PermissionState.limited;
    return ps == PermissionState.authorized ||
        ps == PermissionState.limited;
  }

  /// Lightweight startup: ask for permission and read only the photo *count*
  /// (metadata, very fast). We do NOT load every photo or build groups here —
  /// that heavy work is deferred until the user actually enters a cleanup mode
  /// (see [ensureGroups]), which keeps app start snappy even with 10k+ photos.
  Future<void> prepare() async {
    state = AppState.loading;
    notifyListeners();

    final granted = await _checkPermission();
    if (!granted) {
      state = AppState.permissionDenied;
      notifyListeners();
      return;
    }

    _registerChangeListener();

    try {
      _totalPhotos = await _service.totalCount();
      // Best effort: without video access (Android 13+) this is just 0 and
      // the Videos tab shows no count until access is granted.
      try {
        videoCount = await _videoService.totalCount();
      } catch (_) {}
      stats = _service.estimateStats(_totalPhotos, groups);
      state = AppState.ready;
      notifyListeners();

      // Warm the library up in the background so the first tap on a cleanup
      // mode doesn't sit on a spinner. Fire-and-forget: the home screen is
      // already interactive, and the scan is shared with anyone who asks for
      // the library meanwhile (see [_freshen]). Failures are logged and the
      // on-demand paths below still run.
      unawaited(reloadLibrary());
    } catch (e) {
      state = AppState.error;
      notifyListeners();
    }
  }

  // ─── Library freshness ────────────────────────────────────────────────────
  //
  // The scan is cached for the whole process lifetime, and iOS keeps the app
  // alive in the background for days. Before 1.3 nothing ever invalidated it,
  // so photos taken after the first launch didn't show up until the user found
  // and tapped Refresh. Now we listen for library changes, re-check on resume,
  // and re-scan quietly in the background — Home stays usable throughout.

  /// When the library was last fully scanned. Null until the first scan.
  DateTime? lastScanAt;

  /// True while a background re-scan is running (for Home's freshness line).
  bool isRescanning = false;

  /// The library changed — or a re-scan was postponed — since the last scan.
  bool _libraryStale = false;

  /// Cheap summary of the library at the last scan; see
  /// [PhotoService.libraryFingerprint].
  String? _fingerprint;

  bool _changeListenerRegistered = false;
  Timer? _reloadTimer;
  Future<void>? _reloadFuture;

  bool _inCleanupSession = false;

  /// True while a cleanup mode is open. Every mode sets it on enter and clears
  /// it on exit. Re-scans are held back meanwhile — swapping the lists under a
  /// running session would shift the user's place — and run once they're back
  /// on Home.
  ///
  /// Setting it never notifies: modes set it from initState/dispose, where
  /// rebuilding Home isn't allowed.
  bool get inCleanupSession => _inCleanupSession;
  set inCleanupSession(bool value) {
    _inCleanupSession = value;
    if (!value && _libraryStale) _scheduleReload(Duration.zero);
  }

  /// Listen for library changes (new photos, deletions in other apps, a
  /// changed limited-access selection). Registered once per process — it lives
  /// as long as the provider, so it's never removed.
  void _registerChangeListener() {
    if (_changeListenerRegistered) return;
    _changeListenerRegistered = true;
    PhotoManager.addChangeCallback(_onLibraryChanged);
    unawaited(PhotoManager.startChangeNotify());
  }

  void _onLibraryChanged(MethodCall call) {
    _libraryStale = true;
    // Videos aren't part of the photo scan: drop the cached list and grouping
    // so they're re-read on next use (Home re-requests them when visible).
    videosLoaded = false;
    videoGroupsLoaded = false;
    // Changes arrive in bursts (a burst shot, an iCloud sync) — wait for quiet.
    _scheduleReload(const Duration(milliseconds: 1500));
  }

  void _scheduleReload(Duration delay) {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(delay, () => unawaited(reloadLibrary()));
  }

  /// Called by Home when the app comes back to the foreground.
  Future<void> onAppResumed() async {
    if (state != AppState.ready) return;
    // The user may have changed the access level in Settings meanwhile —
    // granting full access doesn't restart the app, and Android sends no
    // library-change event for it, so a changed level means a re-scan.
    if (await _refreshAccessLevel()) _libraryStale = true;
    final last = lastScanAt;
    final old = last == null ||
        DateTime.now().difference(last) > const Duration(seconds: 60);
    if (_libraryStale || old) await reloadLibrary();
  }

  /// Re-scan the library and regroup, without ever putting Home into the
  /// loading state.
  ///
  /// [silent] (the default) is for automatic triggers — change events,
  /// resume, opening a mode. It first compares a cheap fingerprint with the
  /// last scan and skips the full scan when the photos didn't change: iOS
  /// reports a "change" for every iCloud sync batch and edit, and re-reading
  /// 20k+ assets each time would drain the battery. Pass `silent: false` when
  /// the user explicitly asked to look again (pull-to-refresh) to always scan.
  ///
  /// Postponed (marked stale) while a cleanup mode is open or a deletion is
  /// running; one scan runs at a time and concurrent callers share it.
  Future<void> reloadLibrary({bool silent = true}) {
    if (_inCleanupSession || _isFlushing) {
      _libraryStale = true;
      return Future<void>.value();
    }
    return _reloadFuture ??=
        _runReload(silent).whenComplete(() => _reloadFuture = null);
  }

  Future<void> _runReload(bool silent) async {
    // Cleared up front so a change that lands DURING the scan re-marks it and
    // triggers another pass afterwards.
    _libraryStale = false;
    var failed = false;
    try {
      final unchanged = silent &&
          _fingerprint != null &&
          await _service.libraryFingerprint() == _fingerprint;
      if (!unchanged) {
        isRescanning = true;
        notifyListeners();

        await _refreshAccessLevel();
        await PhotoManager.releaseCache();
        final all = await _service.loadAllAssets(); // newest first
        final regrouped = await _service.groupAssets(all);
        final fingerprint = await _service.libraryFingerprint();

        allPhotos = all;
        photosLoaded = true;
        groups = regrouped;
        groupsLoaded = true;
        _totalPhotos = all.length;
        stats = _service.estimateStats(_totalPhotos, groups);
        // Videos are re-read lazily (from a fresh list) on next use.
        videosLoaded = false;
        videoGroupsLoaded = false;
        _fingerprint = fingerprint;
      }
      lastScanAt = DateTime.now();
    } catch (e) {
      failed = true;
      // Leave it stale so the next resume / mode open tries again — but don't
      // reschedule from here, or a persistent failure would loop.
      _libraryStale = true;
      debugPrint('reloadLibrary failed: $e');
    } finally {
      isRescanning = false;
      notifyListeners();
    }
    if (!failed && _libraryStale) {
      _scheduleReload(const Duration(milliseconds: 1500));
    }
  }

  /// Re-read whether access is full or "Selected photos" only, without
  /// prompting. Only revoking access restarts the app, so a change from
  /// limited to full would otherwise go unnoticed until the next launch.
  /// Returns true if the level changed.
  Future<bool> _refreshAccessLevel() async {
    try {
      final ps = await PhotoManager.getPermissionState(
          requestOption: const PermissionRequestOption());
      if (ps != PermissionState.authorized && ps != PermissionState.limited) {
        return false;
      }
      final limited = ps == PermissionState.limited;
      if (limited != limitedAccess) {
        limitedAccess = limited;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Wait for a scan in flight, and re-scan first if the library changed
  /// since — so a mode never opens on a stale cache.
  Future<void> _freshen() async {
    final running = _reloadFuture;
    if (running != null) await running;
    if (_libraryStale) await reloadLibrary();
  }

  /// Load every photo, newest-first — on demand, cached. Used by Picture Swipe.
  Future<List<AssetEntity>> ensurePhotos() async {
    await _freshen();
    if (photosLoaded && allPhotos.isNotEmpty) return allPhotos;
    await PhotoManager.releaseCache();
    allPhotos = await _service.loadAllAssets();
    sortAssetsNewestFirst(allPhotos);
    photosLoaded = true;
    if (allPhotos.length > _totalPhotos) {
      _totalPhotos = allPhotos.length;
      stats = _service.estimateStats(_totalPhotos, groups);
      notifyListeners();
    }
    return allPhotos;
  }

  // ─── Videos ───────────────────────────────────────────────────────────────
  // Videos need their own permission on Android 13+, so they're loaded only
  // once the user opens the Videos tab, then cached like the photos.

  /// Null until the Videos tab asked for access.
  VideoAccess? videoAccess;
  bool get hasVideoAccess =>
      videoAccess == VideoAccess.granted || videoAccess == VideoAccess.limited;

  /// Every video, newest first. Valid while [videosLoaded].
  List<AssetEntity> allVideos = [];
  bool videosLoaded = false;
  int videoCount = 0;
  Future<List<AssetEntity>>? _videosFuture;

  /// Time-grouped videos (same grouping as photos), cached.
  List<PhotoGroup> videoGroups = [];
  bool videoGroupsLoaded = false;

  /// Ask for video access (prompts when needed). Starts loading the videos
  /// when granted.
  Future<VideoAccess> requestVideoAccess() async {
    final access = await _videoService.ensureAccess();
    videoAccess = access;
    notifyListeners();
    if (hasVideoAccess) unawaited(ensureVideos());
    return access;
  }

  Future<void> openVideoSettings() => _videoService.openSettings();

  /// Load every video (cached), then group them. Concurrent callers share one
  /// load.
  Future<List<AssetEntity>> ensureVideos() {
    if (videosLoaded) return Future.value(allVideos);
    return _videosFuture ??= _loadVideos().whenComplete(() => _videosFuture = null);
  }

  Future<List<AssetEntity>> _loadVideos() async {
    try {
      final videos = await _videoService.loadAllVideos();
      allVideos = videos;
      videoCount = videos.length;
      videosLoaded = true;
      videoGroups = await _service.groupAssets(videos);
      videoGroupsLoaded = true;
    } catch (e) {
      debugPrint('ensureVideos failed: $e');
    }
    notifyListeners();
    return allVideos;
  }

  Future<List<PhotoGroup>> ensureVideoGroups() async {
    await ensureVideos();
    if (!videoGroupsLoaded) {
      videoGroups = await _service.groupAssets(allVideos);
      videoGroupsLoaded = true;
    }
    return videoGroups;
  }

  Future<List<PhotoGroup>> ensureGroups() async {
    await _freshen();
    if (groupsLoaded) return groups;

    try {
      // Reuse the already-scanned library if Picture Swipe (or the background
      // warm-up) loaded it — re-scanning 10k+ assets here was pure waste and
      // the main reason opening Group Review felt slow.
      List<AssetEntity> all;
      if (photosLoaded && allPhotos.isNotEmpty) {
        all = allPhotos;
      } else {
        await PhotoManager.releaseCache();
        all = await _service.loadAllAssets();
      }
      _totalPhotos = all.length;
      allPhotos = all;
      photosLoaded = true;
      groups = await _service.groupAssets(all);
      groupsLoaded = true;
      stats = _service.estimateStats(_totalPhotos, groups);
    } catch (e) {
      debugPrint('ensureGroups failed: $e');
    } finally {
      notifyListeners();
    }
    return groups;
  }

  /// Pull-to-refresh on Home — the hidden fallback for when the automatic
  /// re-scan didn't pick something up. Re-checks access (it may have changed
  /// in Settings), then always does a full scan. Home stays on screen: the
  /// pull indicator is the progress, so we don't switch to the loading state.
  Future<void> refresh() async {
    final granted = await _checkPermission();
    if (!granted) {
      state = AppState.permissionDenied;
      notifyListeners();
      return;
    }
    _registerChangeListener();
    await reloadLibrary(silent: false);
  }

  // ─── Saved position per mode ─────────────────────────────────────────────
  //
  // Each mode remembers where the user is, across launches. (1.x had a
  // "resume cursor" API that nothing ever called, so every session started
  // at the newest photo of a possibly stale list.)

  final Map<CleanupMode, SavedProgress> _progress = {};

  static String _progressKey(CleanupMode m) => 'progress_${m.name}';

  void _loadProgress(SharedPreferences prefs) {
    for (final m in CleanupMode.values) {
      final raw = prefs.getString(_progressKey(m));
      if (raw == null) continue;
      try {
        final p = SavedProgress.fromJson(jsonDecode(raw));
        if (p != null) _progress[m] = p;
      } catch (_) {}
    }
  }

  SavedProgress? progressFor(CleanupMode m) => _progress[m];

  /// Record where the user is in mode [m]. [next] is the first item not yet
  /// reviewed, or null when they reached the end.
  ///
  /// [fromNewest] runs (started at the newest item) never move the saved
  /// point *up*: browsing this week's photos must not throw away the 2019
  /// position. They do pass [top], the newest item's date, so photos that
  /// arrive later count as "new since last time".
  Future<void> recordProgress(
    CleanupMode m,
    ResumePoint? next, {
    required bool fromNewest,
    DateTime? top,
  }) async {
    final old = _progress[m];
    ResumePoint? at;
    if (next == null) {
      at = null; // reviewed to the end
    } else if (fromNewest &&
        old?.at != null &&
        next.time.isAfter(old!.at!.time)) {
      at = old.at; // still above the deeper saved point — keep it
    } else {
      at = next;
    }
    DateTime? newTop = old?.top;
    if (top != null && (newTop == null || top.isAfter(newTop))) newTop = top;
    final p = SavedProgress(at: at, top: newTop);
    _progress[m] = p;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey(m), jsonEncode(p.toJson()));
  }

  // ─── Milestones ───────────────────────────────────────────────────────────

  static const String _kMilestoneIndex = 'milestone_index';
  static const String _kMilestoneDates = 'milestone_dates';
  static const String _kMeasuredBytes = 'measured_bytes';
  static const String _kMeasuredCount = 'measured_count';

  Future<void> _loadMilestones(SharedPreferences prefs) async {
    if (!prefs.containsKey(_kMilestoneIndex)) {
      // First launch of 1.3: start from the tier the existing freed_bytes
      // already reached — silently, so upgraders aren't retro-celebrated.
      milestoneIndex = Milestone.reachedIndex(freedBytes);
      await prefs.setInt(_kMilestoneIndex, milestoneIndex);
    } else {
      milestoneIndex = prefs.getInt(_kMilestoneIndex) ?? -1;
    }
    milestoneDates = {};
    final raw = prefs.getString(_kMilestoneDates);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          final i = int.tryParse(k);
          final d = DateTime.tryParse(v as String);
          if (i != null && d != null) milestoneDates[i] = d;
        });
      } catch (_) {}
    }
  }

  /// The next tier to aim for, or null once every tier is reached.
  Milestone? get nextMilestone => Milestone.after(milestoneIndex);

  /// Average photo size: measured when we have measurements, else ~3.5 MB.
  int get avgPhotoBytes =>
      _measuredCount > 0 ? _measuredBytes ~/ _measuredCount : kAvgPhotoBytes;

  /// "Room for about N new photos" for [bytes], to 2 significant figures.
  int photosEquivalent(int bytes) => fmt.roundTo2Sig(bytes / avgPhotoBytes);

  /// Record any tiers newly crossed by the current [freedBytes] and return
  /// the highest one, or null. Each tier is celebrated once.
  Future<Milestone?> _checkMilestones(SharedPreferences prefs) async {
    final reached = Milestone.reachedIndex(freedBytes);
    if (reached <= milestoneIndex) return null;
    final now = DateTime.now();
    for (var i = milestoneIndex + 1; i <= reached; i++) {
      milestoneDates[i] = now;
    }
    milestoneIndex = reached;
    await prefs.setInt(_kMilestoneIndex, milestoneIndex);
    await prefs.setString(
      _kMilestoneDates,
      jsonEncode(milestoneDates
          .map((k, v) => MapEntry('$k', v.toIso8601String()))),
    );
    return Milestone.ladder[reached];
  }

  // ─── Pending deletions (survive the app being closed) ─────────────────────
  //
  // The OS confirmation for deleting media can only be shown by a FOREGROUND
  // app — it can't be pre-granted, and can't be asked once the user has quit.
  // The group modes therefore mark items as they go and commit them in one
  // dialog on exit.
  //
  // If the app dies before that, the marks would be lost silently (nothing is
  // deleted — safe, but the user was already shown "freed"). So we persist the
  // marked ids and offer to finish the job next launch.
  static const String _kPendingDeleteIds = 'pending_delete_ids';
  List<String> _pendingDeleteIds = [];

  /// Guards against two flushes running at once — e.g. app start and the
  /// resume callback both firing, which would stack two system dialogs.
  bool _isFlushing = false;

  bool get hasPendingDeletions => _pendingDeleteIds.isNotEmpty;
  int get pendingDeleteCount => _pendingDeleteIds.length;

  /// Whether [id] is currently marked for deletion.
  bool isQueued(String id) => _pendingDeleteIds.contains(id);

  /// Remember items marked for deletion so a crash/force-quit can't lose them.
  ///
  /// [notify] is opt-out for the swipe decks, which call this once per swipe:
  /// they already rebuild via setState, and nothing on screen reads the pending
  /// count, so an extra notifyListeners() would just double their rebuilds
  /// during a gesture.
  Future<void> queueForDeletion(List<AssetEntity> assets,
      {bool notify = true}) async {
    if (assets.isEmpty) return;
    // De-duplicate: re-marking the same asset must not queue it twice.
    final seen = _pendingDeleteIds.toSet();
    for (final a in assets) {
      if (seen.add(a.id)) _pendingDeleteIds.add(a.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPendingDeleteIds, _pendingDeleteIds);
    if (notify) notifyListeners();
  }

  /// Take items back out of the queue — Undo in the swipe decks.
  Future<void> unqueueDeletion(List<AssetEntity> assets,
      {bool notify = true}) async {
    if (assets.isEmpty) return;
    final ids = assets.map((a) => a.id).toSet();
    _pendingDeleteIds.removeWhere(ids.contains);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPendingDeleteIds, _pendingDeleteIds);
    if (notify) notifyListeners();
  }

  Future<void> _clearPendingDeletions() async {
    _pendingDeleteIds = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingDeleteIds);
    notifyListeners();
  }

  /// Forget the marks without deleting — used when the user answers "keep
  /// them", so we never nag about the same items again.
  Future<void> discardPendingDeletions() => _clearPendingDeletions();

  /// Delete everything currently marked, in a single system prompt.
  /// Safe to call when nothing is pending, and safe to call twice (the second
  /// call returns [DeleteResult.none]).
  Future<DeleteResult> flushPendingDeletions() async {
    if (_isFlushing || _pendingDeleteIds.isEmpty) return DeleteResult.none;
    _isFlushing = true;
    try {
      final ids = List<String>.from(_pendingDeleteIds);
      // Resolve ids back to assets. Anything already gone (deleted elsewhere,
      // moved, or on a detached SD card) resolves to null and is skipped.
      final assets = <AssetEntity>[];
      for (final id in ids) {
        try {
          final a = await AssetEntity.fromId(id);
          if (a != null) assets.add(a);
        } catch (_) {/* unreadable id — drop it */}
      }
      if (assets.isEmpty) {
        // Nothing left to delete (already gone) — drop the marks.
        await _clearPendingDeletions();
        return DeleteResult.none;
      }

      // Measure real sizes BEFORE deleting — afterwards the files are gone.
      final sizes = await _service.measureBytes(assets);
      final result = await deleteAssets(assets, measuredBytes: sizes);

      // Clear only once deleteAssets has RETURNED. Returning means the user
      // actually answered the system prompt — allow or deny — and either way
      // one answer is final, so we must not nag on every launch.
      //
      // Crucially, if the app is killed while that prompt is on screen (the
      // user walks away, the OS reclaims us, they swipe the app away) we never
      // reach this line, so the marks stay on disk and Home can offer to
      // finish the job next launch. Clearing before the prompt would have
      // thrown the marks away in exactly the case they're needed.
      await _clearPendingDeletions();
      return result;
    } finally {
      _isFlushing = false;
      // A re-scan postponed for the delete (the delete itself is a library
      // change) runs now — unless a mode is still open; then it runs on exit.
      if (_libraryStale && !_inCleanupSession) _scheduleReload(Duration.zero);
    }
  }

  /// Restore anything left marked by a previous session.
  Future<void> _loadPendingDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingDeleteIds = prefs.getStringList(_kPendingDeleteIds) ?? [];
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Delete the given assets in one batch (one system confirmation dialog)
  /// and report what really happened. [measuredBytes] (id → size) replaces
  /// the per-type average for the items it covers.
  ///
  /// Nothing is counted until the OS confirms the items are gone: a denial
  /// returns a `declined` result with zero bytes and no progress.
  Future<DeleteResult> deleteAssets(List<AssetEntity> toDelete,
      {Map<String, int> measuredBytes = const {}}) async {
    if (toDelete.isEmpty) return DeleteResult.none;
    final requestedIds = toDelete.map((a) => a.id).toList();

    // Track whether the platform call actually errored. A plain denial
    // returns normally with nothing deleted; only a real failure throws.
    var deleteThrew = false;
    try {
      await PhotoManager.editor.deleteWithIds(requestedIds);
    } catch (e) {
      deleteThrew = true;
      debugPrint('deleteAssets: deleteWithIds threw: $e');
    }

    // Don't trust deleteWithIds' return value: on several Android versions /
    // OEMs it returns an empty list after a successful delete, or a non-empty
    // list without actually deleting. Ask MediaStore which assets are really
    // gone and treat THAT as the result.
    List<String> deletedIds = await _confirmDeleted(requestedIds);

    // Fallback: the delete genuinely FAILED (threw) → try the system trash
    // (Android 11+). We deliberately do NOT run this after a plain denial:
    // moveToTrash opens a second system dialog, so the user was being asked
    // to confirm twice after already saying no.
    var usedTrash = false;
    if (deletedIds.isEmpty && deleteThrew && Platform.isAndroid) {
      try {
        await PhotoManager.editor.android.moveToTrash(toDelete);
      } catch (e) {
        debugPrint('deleteAssets: moveToTrash fallback failed: $e');
      }
      deletedIds = await _confirmDeleted(requestedIds);
      usedTrash = deletedIds.isNotEmpty;
    }

    if (deletedIds.isEmpty) {
      debugPrint(
          'deleteAssets: user denied or nothing deleted (${toDelete.length} requested)');
      return DeleteResult(
        requested: requestedIds.length,
        deleted: 0,
        bytes: 0,
        declined: true,
      );
    }
    debugPrint(
        'deleteAssets: ${deletedIds.length}/${requestedIds.length} confirmed deleted');

    // Sum sizes for the CONFIRMED ids only. Measured where we could read the
    // file, the per-type average otherwise.
    final deletedSet = deletedIds.toSet();
    var freed = 0;
    var measuredPhotoBytes = 0;
    var measuredPhotoCount = 0;
    var deletedPhotos = 0;
    for (final a in toDelete) {
      if (!deletedSet.contains(a.id)) continue;
      final isVideo = a.type == AssetType.video;
      if (!isVideo) deletedPhotos++;
      final measured = measuredBytes[a.id];
      freed += measured ?? (isVideo ? kAvgVideoBytes : avgPhotoBytes);
      if (measured != null && !isVideo) {
        measuredPhotoBytes += measured;
        measuredPhotoCount++;
      }
    }
    freedBytes += freed;
    deletedCount += deletedIds.length;
    _measuredBytes += measuredPhotoBytes;
    _measuredCount += measuredPhotoCount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('freed_bytes', freedBytes);
    await prefs.setInt('deleted_count', deletedCount);
    await prefs.setInt(_kMeasuredBytes, _measuredBytes);
    await prefs.setInt(_kMeasuredCount, _measuredCount);
    final newMilestone = await _checkMilestones(prefs);

    // Remove the actually-deleted assets from the cached lists.
    if (photosLoaded) {
      allPhotos =
          allPhotos.where((a) => !deletedSet.contains(a.id)).toList();
    }
    if (videosLoaded) {
      final before = allVideos.length;
      allVideos =
          allVideos.where((a) => !deletedSet.contains(a.id)).toList();
      videoCount = (videoCount - (before - allVideos.length)).clamp(0, 1 << 31);
    }
    videoGroups = videoGroups
        .map((g) => g.copyWith(
            assets:
                g.assets.where((a) => !deletedSet.contains(a.id)).toList()))
        .where((g) => g.assets.length >= 2)
        .toList();
    groups = groups
        .map((g) {
          final remaining =
              g.assets.where((a) => !deletedSet.contains(a.id)).toList();
          return g.copyWith(assets: remaining);
        })
        .where((g) => g.assets.length >= 2)
        .toList();

    // Keep the library count and stats in sync with what was just removed.
    _totalPhotos = (_totalPhotos - deletedPhotos).clamp(0, _totalPhotos);
    stats = _service.estimateStats(_totalPhotos, groups);

    notifyListeners();
    return DeleteResult(
      requested: requestedIds.length,
      deleted: deletedIds.length,
      bytes: freed,
      declined: false,
      usedTrash: usedTrash,
      newMilestone: newMilestone,
    );
  }

  /// Re-query MediaStore and return the ids that no longer resolve — i.e. the
  /// assets that were really deleted (or trashed). Drops photo_manager's
  /// caches first so we don't get a stale "still exists" answer.
  Future<List<String>> _confirmDeleted(List<String> ids) async {
    try {
      await PhotoManager.releaseCache();
    } catch (_) {}
    final gone = <String>[];
    for (final id in ids) {
      AssetEntity? entity;
      try {
        entity = await AssetEntity.fromId(id);
      } catch (_) {
        entity = null;
      }
      if (entity == null) gone.add(id);
    }
    return gone;
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  Future<void> setLanguage(String code) async {
    languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
    // Re-schedule the reminder so its text matches the new language — only
    // if reminders exist. (This used to request notification permission on
    // every language change, popping the system dialog over Settings.)
    if (prefs.getBool(_kRemindersSetUp) ?? false) {
      await _scheduleReminders();
    }
  }

  Future<void> setSoundsEnabled(bool value) async {
    soundsEnabled = value;
    FeedbackService.instance.soundsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sounds_enabled', value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    FeedbackService.instance.hapticsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', value);
  }
}
