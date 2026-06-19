import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/photo_group.dart';
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

  // Persistent
  int freedBytes = 0;
  int deletedCount = 0;
  String languageCode = 'en';
  bool isPro = false;
  bool remindersEnabled = true;

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
    remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
    notifyListeners();

    // Set up in-app purchases; unlock Pro when a purchase/restore completes.
    PurchaseService.instance.init(onPurchased: () => setPro(true));

    // Schedule (or clear) the monthly cleanup reminder.
    _setupReminders();
  }

  /// The phone's language if we support it, otherwise English.
  String _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return kSupportedLanguages.contains(code) ? code : 'en';
  }

  Future<void> _setupReminders() async {
    if (!remindersEnabled) {
      await NotificationService.instance.cancelMonthlyReminder();
      return;
    }
    await NotificationService.instance.requestPermissions();
    final s = AppStrings.of(languageCode);
    await NotificationService.instance.scheduleMonthlyReminder(
      title: s.reminderTitle,
      body: s.reminderBody,
    );
  }

  Future<void> setReminders(bool value) async {
    remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', value);
    notifyListeners();
    await _setupReminders();
  }

  Future<void> setPro(bool value) async {
    isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  // ─── Permission + Load ────────────────────────────────────────────────────

  Future<void> loadPhotos() async {
    state = AppState.loading;
    notifyListeners();

    final granted = await _service.requestPermission();
    if (!granted) {
      state = AppState.permissionDenied;
      notifyListeners();
      return;
    }

    try {
      groups = await _service.loadGroups();
      stats = await _service.loadStats(groups);
      state = AppState.ready;
    } catch (e) {
      state = AppState.error;
    }
    notifyListeners();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Delete selected assets from a group.
  /// Returns bytes freed.
  Future<int> deleteAssets(List<AssetEntity> toDelete) async {
    int freed = 0;
    for (final asset in toDelete) {
      final file = await asset.file;
      if (file != null) freed += await file.length();
    }

    await PhotoManager.editor.deleteWithIds(
      toDelete.map((a) => a.id).toList(),
    );

    freedBytes += freed;
    deletedCount += toDelete.length;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('freed_bytes', freedBytes);
    await prefs.setInt('deleted_count', deletedCount);

    // Remove deleted assets from groups
    groups = groups
        .map((g) {
          final remaining =
              g.assets.where((a) => !toDelete.contains(a)).toList();
          return g.copyWith(assets: remaining);
        })
        .where((g) => g.assets.length >= 2)
        .toList();

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
