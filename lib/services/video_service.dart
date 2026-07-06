import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// Level of access we have to the device's videos.
enum VideoAccess {
  /// Full access — all videos are readable.
  granted,

  /// Android 14 "Selected" / partial access — only user-picked media is visible.
  limited,

  /// No access.
  denied,
}

/// Loads video assets. Kept separate from the photo pipeline: videos aren't
/// grouped (they're rarely near-duplicates) — the user just swipes through them
/// newest-first.
class VideoService {
  static const int maxVideosToScan = 20000;

  /// Request/check video access and report the level. On Android 13+ this is the
  /// separate READ_MEDIA_VIDEO permission — photo_manager won't prompt for it
  /// when photos are already granted, so we go through permission_handler.
  Future<VideoAccess> ensureAccess() async {
    var status = await Permission.videos.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.videos.request();
    }

    if (status.isGranted || status.isLimited) {
      // OS permission in hand — tell photo_manager to query MediaStore directly
      // instead of blocking on its own (image-only) permission cache.
      await PhotoManager.setIgnorePermissionCheck(true);
      return status.isLimited ? VideoAccess.limited : VideoAccess.granted;
    }

    // Older Android: Permission.videos maps to storage.
    final st = await PhotoManager.requestPermissionExtend();
    if (st == PermissionState.authorized || st == PermissionState.limited) {
      await PhotoManager.setIgnorePermissionCheck(true);
      return st == PermissionState.limited
          ? VideoAccess.limited
          : VideoAccess.granted;
    }
    return VideoAccess.denied;
  }

  /// Open the app's system settings page (so the user can switch to "Allow all").
  Future<void> openSettings() => openAppSettings();

  /// Number of video assets (metadata only — fast).
  Future<int> totalCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    if (albums.isEmpty) return 0;
    return albums.first.assetCountAsync;
  }

  /// All videos, newest first (metadata only). Merges every video album, since
  /// the primary "all" album can be empty on some devices while videos live in
  /// other albums (Camera, Downloads, WhatsApp, …).
  Future<List<AssetEntity>> loadAllVideos() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    if (albums.isEmpty) return [];

    final seen = <String>{};
    final result = <AssetEntity>[];
    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count == 0) continue;
      final end = count < maxVideosToScan ? count : maxVideosToScan;
      final assets = await album.getAssetListRange(start: 0, end: end);
      for (final a in assets) {
        if (seen.add(a.id)) result.add(a);
      }
      if (result.length >= maxVideosToScan) break;
    }
    result.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return result;
  }
}
