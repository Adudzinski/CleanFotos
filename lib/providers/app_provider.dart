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
import '../models/photo_group.dart';
import '../services/ad_service.dart';
import '../services/feedback_service.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';
import '../services/purchase_service.dart';
import '../utils/asset_utils.dart';
import '../utils/format.dart' as fmt;

const Set<String> kSupportedLanguages = {'en', 'es', 'de', 'fr', 'pt', 'it', 'pl'};

enum AppState { initial, loading, ready, permissionDenied, error }

class AppProvider extends ChangeNotifier {
  final PhotoService _service = PhotoService();

  AppState state = AppState.initial;
  List<PhotoGroup> groups = [];
  LibraryStats stats = LibraryStats.empty;

  /// Whether the (lazy) photo grouping has actually run yet. Until then we only
  /// know the library size, not how many similar groups exist.
  bool groupsLoaded = false;

  /// True while photos are being loaded + grouped for a cleanup mode.
  bool isLoadingGroups = false;

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
  bool onboardingSeen = false;

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
    // Default to the phone's language on first launch, else the saved choice.
    languageCode = prefs.getString('language_code') ?? _deviceLanguage();
    isPro = prefs.getBool('is_pro') ?? false;
    onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
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
  /// so the request arrives when the app has demonstrated its value.
  Future<void> maybeSetupReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kRemindersSetUp) ?? false) return;
    await prefs.setBool(_kRemindersSetUp, true);
    await _setupReminders();
  }

  Future<void> _setupReminders() async {
    await NotificationService.instance.requestPermissions();
    final s = AppStrings.of(languageCode);
    await NotificationService.instance.scheduleReminders(
      title: s.reminderTitle,
      body: s.reminderBody,
    );
  }

  Future<void> markOnboardingSeen() async {
    if (onboardingSeen) return;
    onboardingSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    notifyListeners();
  }

  // ─── Resume cursors ─────────────────────────────────────────────────────
  // Each swipe/review mode remembers the timestamp of the card the user was on,
  // so it resumes there next time. (Since 1.3 Refresh no longer clears them.)
  static const String kPhotoCursor = 'cursor_photo';
  static const String kVideoCursor = 'cursor_video';
  static const String kGroupCursor = 'cursor_group';

  Future<int?> getCursor(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> setCursor(String key, int millis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, millis);
  }

  /// Resume position for swipe/review modes — stores an asset or group id.
  Future<String?> getCursorId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${key}_id');
  }

  Future<void> setCursorId(String key, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_id', id);
  }

  Future<void> clearCursors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kPhotoCursor);
    await prefs.remove(kVideoCursor);
    await prefs.remove(kGroupCursor);
    await prefs.remove('${kPhotoCursor}_id');
    await prefs.remove('${kVideoCursor}_id');
    await prefs.remove('${kGroupCursor}_id');
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
    // Videos aren't part of the photo scan and are re-read every time a video
    // mode opens; only their grouping is cached, so just drop it.
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
    // granting full access doesn't restart the app.
    await _refreshAccessLevel();
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
        // Video groups rebuild lazily from a fresh video list on next use.
        videoGroups = [];
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
  Future<void> _refreshAccessLevel() async {
    try {
      final ps = await PhotoManager.getPermissionState(
          requestOption: const PermissionRequestOption());
      if (ps != PermissionState.authorized && ps != PermissionState.limited) {
        return;
      }
      final limited = ps == PermissionState.limited;
      if (limited != limitedAccess) {
        limitedAccess = limited;
        notifyListeners();
      }
    } catch (_) {}
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

  /// Load the photo library and group it by time — on demand, and cached so it
  /// only runs once per scan. Call this when the user opens a cleanup mode
  /// (group review / swipe). Returns the resulting groups.
  /// Time-grouped VIDEOS, cached like [ensureGroups]. Reuses the same grouping
  /// algorithm — it works on any asset list, not just photos.
  List<PhotoGroup> videoGroups = [];
  bool videoGroupsLoaded = false;

  Future<List<PhotoGroup>> ensureVideoGroups(List<AssetEntity> videos) async {
    if (videoGroupsLoaded) return videoGroups;
    try {
      videoGroups = await _service.groupAssets(videos);
      videoGroupsLoaded = true;
    } catch (e) {
      debugPrint('ensureVideoGroups failed: $e');
    }
    notifyListeners();
    return videoGroups;
  }

  Future<List<PhotoGroup>> ensureGroups() async {
    await _freshen();
    if (groupsLoaded) return groups;

    isLoadingGroups = true;
    notifyListeners();
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
      isLoadingGroups = false;
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
    for (final a in toDelete) {
      if (!deletedSet.contains(a.id)) continue;
      final isVideo = a.type == AssetType.video;
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

    // The user has now cleaned something up, so this is a much better moment
    // to ask about notifications than a cold first launch.
    unawaited(maybeSetupReminders());

    // Remove the actually-deleted assets from the cached lists.
    if (photosLoaded) {
      allPhotos =
          allPhotos.where((a) => !deletedSet.contains(a.id)).toList();
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
    _totalPhotos = (_totalPhotos - deletedIds.length).clamp(0, _totalPhotos);
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

  /// Skip a group (move to next without deleting).
  void skipGroup(String groupId) {
    groups = groups.where((g) => g.id != groupId).toList();
    notifyListeners();
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  Future<void> setLanguage(String code) async {
    languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
    // Re-schedule the reminder so its text matches the new language.
    await _setupReminders();
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get freedFormatted => _formatBytes(freedBytes);

  static String _formatBytes(int bytes) {
    if (bytes == 0) return '0 MB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
