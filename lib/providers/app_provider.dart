import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_group.dart';
import '../services/photo_service.dart';

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
  bool showAds = true;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    freedBytes = prefs.getInt('freed_bytes') ?? 0;
    deletedCount = prefs.getInt('deleted_count') ?? 0;
    languageCode = prefs.getString('language_code') ?? 'en';
    showAds = prefs.getBool('show_ads') ?? true;
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
  }

  Future<void> setShowAds(bool value) async {
    showAds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_ads', value);
    notifyListeners();
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
