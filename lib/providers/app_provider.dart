import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/photo_group.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';
import '../services/purchase_service.dart';
import '../utils/asset_utils.dart';

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
  /// duplicates). Loaded lazily and cached; cleared on Refresh.
  List<AssetEntity> allPhotos = [];
  bool photosLoaded = false;

  int _totalPhotos = 0;

  // Persistent
  int freedBytes = 0;
  int deletedCount = 0;
  String languageCode = 'en';
  bool isPro = false;
  bool onboardingSeen = false;

  /// Theme preference: 'system' (default), 'light' or 'dark'.
  String themePref = 'system';

  /// Ads show unless the user has unlocked Pro.
  bool get adsEnabled => !isPro;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    freedBytes = prefs.getInt('freed_bytes') ?? 0;
    deletedCount = prefs.getInt('deleted_count') ?? 0;
    // Default to the phone's language on first launch, else the saved choice.
    languageCode = prefs.getString('language_code') ?? _deviceLanguage();
    isPro = prefs.getBool('is_pro') ?? false;
    onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    themePref = prefs.getString('theme_pref') ?? 'system';
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
  // so it resumes there next time. Refresh clears them → start at the newest.
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

    try {
      _totalPhotos = await _service.totalCount();
      stats = _service.estimateStats(_totalPhotos, groups);
      state = AppState.ready;
      notifyListeners();

      // Warm the library up in the background so the first tap on a cleanup
      // mode doesn't sit on a spinner. Fire-and-forget: the home screen is
      // already interactive, and ensurePhotos() is cached + idempotent.
      unawaited(_warmUp());
    } catch (e) {
      state = AppState.error;
      notifyListeners();
    }
  }

  /// Load every photo, newest-first — on demand, cached. Used by Picture Swipe.
  /// Pre-load the photo library (and then the groups) quietly in the
  /// background after the home screen appears. Failures are ignored — the
  /// on-demand path still runs if the user taps before this finishes.
  Future<void> _warmUp() async {
    try {
      await ensurePhotos();
      await ensureGroups();
    } catch (_) {}
  }

  Future<List<AssetEntity>> ensurePhotos() async {
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

  /// Re-scan from scratch: clears caches, re-reads the library from MediaStore,
  /// and re-groups. Always starts every mode at the newest items afterward.
  Future<void> refresh() async {
    state = AppState.loading;
    groups = [];
    groupsLoaded = false;
    videoGroups = [];
    videoGroupsLoaded = false;
    allPhotos = [];
    photosLoaded = false;
    await clearCursors();
    notifyListeners();

    final granted = await _checkPermission();
    if (!granted) {
      state = AppState.permissionDenied;
      notifyListeners();
      return;
    }

    try {
      // Drop photo_manager's cached asset lists so we see deletions/additions.
      await PhotoManager.releaseCache();

      final all = await _service.loadAllAssets();
      _totalPhotos = all.length;
      allPhotos = all;
      photosLoaded = true;
      groups = await _service.groupAssets(all);
      groupsLoaded = true;
      stats = _service.estimateStats(_totalPhotos, groups);
      state = AppState.ready;
    } catch (e) {
      debugPrint('refresh failed: $e');
      state = AppState.error;
    }
    notifyListeners();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Delete the given assets in one batch (one system confirmation dialog).
  /// Returns estimated bytes freed. No-op / 0 if the user denies or deletion
  /// fails — callers must check before updating their local UI.
  Future<int> deleteAssets(List<AssetEntity> toDelete) async {
    if (toDelete.isEmpty) return 0;
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
    if (deletedIds.isEmpty && deleteThrew && Platform.isAndroid) {
      try {
        await PhotoManager.editor.android.moveToTrash(toDelete);
      } catch (e) {
        debugPrint('deleteAssets: moveToTrash fallback failed: $e');
      }
      deletedIds = await _confirmDeleted(requestedIds);
    }

    if (deletedIds.isEmpty) {
      debugPrint(
          'deleteAssets: user denied or nothing deleted (${toDelete.length} requested)');
      return 0;
    }
    debugPrint(
        'deleteAssets: ${deletedIds.length}/${requestedIds.length} confirmed deleted');

    final freed = deletedIds.length * kAvgPhotoBytes;
    freedBytes += freed;
    deletedCount += deletedIds.length;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('freed_bytes', freedBytes);
    await prefs.setInt('deleted_count', deletedCount);

    // The user has now cleaned something up, so this is a much better moment
    // to ask about notifications than a cold first launch.
    unawaited(maybeSetupReminders());

    // Remove the actually-deleted assets from the cached lists.
    final deletedSet = deletedIds.toSet();
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
    return freed;
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

  Future<void> setThemePref(String value) async {
    themePref = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_pref', value);
  }

  /// Called by the app root when the system brightness changes, so screens
  /// rebuild with the updated AppTheme palette.
  void refreshTheme() => notifyListeners();

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
