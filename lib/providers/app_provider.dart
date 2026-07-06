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

const Set<String> kSupportedLanguages = {'en', 'es', 'de', 'fr', 'pt', 'it'};

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

  int _totalPhotos = 0;

  // Persistent
  int freedBytes = 0;
  int deletedCount = 0;
  String languageCode = 'en';
  bool isPro = false;
  bool onboardingSeen = false;

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
    notifyListeners();

    // Only gather ad consent / initialize ads for non-Pro users. Pro users get
    // no ads, so there's no need to show them a consent form at all.
    if (adsEnabled) {
      AdService.instance.init();
    }

    // Set up in-app purchases; unlock Pro when a purchase/restore completes.
    PurchaseService.instance.init(onPurchased: () => setPro(true));

    // Schedule the seasonal cleanup reminders (always on).
    _setupReminders();
  }

  /// The phone's language if we support it, otherwise English.
  String _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return kSupportedLanguages.contains(code) ? code : 'en';
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

  Future<void> setPro(bool value) async {
    isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  // ─── Permission + Load ────────────────────────────────────────────────────

  /// Lightweight startup: ask for permission and read only the photo *count*
  /// (metadata, very fast). We do NOT load every photo or build groups here —
  /// that heavy work is deferred until the user actually enters a cleanup mode
  /// (see [ensureGroups]), which keeps app start snappy even with 10k+ photos.
  Future<void> prepare() async {
    state = AppState.loading;
    notifyListeners();

    final granted = await _service.requestPermission();
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
    } catch (e) {
      state = AppState.error;
      notifyListeners();
    }
  }

  /// Load the photo library and group it by time — on demand, and cached so it
  /// only runs once per scan. Call this when the user opens a cleanup mode
  /// (group review / swipe). Returns the resulting groups.
  Future<List<PhotoGroup>> ensureGroups() async {
    if (groupsLoaded) return groups;

    isLoadingGroups = true;
    notifyListeners();
    try {
      final all = await _service.loadAllAssets();
      _totalPhotos = all.length;
      groups = await _service.groupAssets(all);
      groupsLoaded = true;
      stats = _service.estimateStats(_totalPhotos, groups);
    } catch (_) {
      // Leave groups empty; the caller handles the "nothing to clean" case.
    } finally {
      isLoadingGroups = false;
      notifyListeners();
    }
    return groups;
  }

  /// Re-scan from scratch (clears the cached grouping and refreshes the count).
  Future<void> refresh() async {
    groups = [];
    groupsLoaded = false;
    await prepare();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Delete the given assets in one batch (one system confirmation dialog).
  /// Returns estimated bytes freed. No-op / 0 if the user denies.
  Future<int> deleteAssets(List<AssetEntity> toDelete) async {
    if (toDelete.isEmpty) return 0;

    List<String> deletedIds;
    try {
      deletedIds = await PhotoManager.editor.deleteWithIds(
        toDelete.map((a) => a.id).toList(),
      );
    } catch (_) {
      return 0; // user denied or an error occurred
    }
    if (deletedIds.isEmpty) return 0;

    final freed = deletedIds.length * kAvgPhotoBytes;
    freedBytes += freed;
    deletedCount += deletedIds.length;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('freed_bytes', freedBytes);
    await prefs.setInt('deleted_count', deletedCount);

    // Remove the actually-deleted assets from the groups.
    final deletedSet = deletedIds.toSet();
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
