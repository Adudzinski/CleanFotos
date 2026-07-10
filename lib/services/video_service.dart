import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../utils/asset_utils.dart';

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

  static final FilterOptionGroup _newestFirstFilter = FilterOptionGroup(
    videoOption: const FilterOption(
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
    // Disable the implicit "epoch .. now()" date filter — it hides assets
    // with future timestamps (see PhotoService._newestFirstFilter).
    createTimeCond: DateTimeCond.def().copyWith(ignore: true),
    updateTimeCond: DateTimeCond.def().copyWith(ignore: true),
    orders: [
      const OrderOption(type: OrderOptionType.createDate, asc: false),
    ],
  );

  /// Request/check video access and report the level. On Android 13+ this is the
  /// separate READ_MEDIA_VIDEO permission — photo_manager won't prompt for it
  /// when photos are already granted, so we go through permission_handler.
  Future<VideoAccess> ensureAccess() async {
    var status = await Permission.videos.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.videos.request();
    }

    if (status.isGranted || status.isLimited) {
      await PhotoManager.requestPermissionExtend();
      return status.isLimited ? VideoAccess.limited : VideoAccess.granted;
    }

    final st = await PhotoManager.requestPermissionExtend();
    if (st == PermissionState.authorized || st == PermissionState.limited) {
      return st == PermissionState.limited
          ? VideoAccess.limited
          : VideoAccess.granted;
    }
    return VideoAccess.denied;
  }

  Future<void> openSettings() => openAppSettings();

  Future<int> totalCount() async {
    final videos = await loadAllVideos();
    return videos.length;
  }

  /// Every video once (deduped), sorted newest-in-library first.
  Future<List<AssetEntity>> loadAllVideos() async {
    await PhotoManager.releaseCache();

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      filterOption: _newestFirstFilter,
    );
    if (albums.isEmpty) return [];

    final seen = <String>{};
    final result = <AssetEntity>[];

    final sortedAlbums = [...albums]
      ..sort((a, b) {
        if (a.isAll == b.isAll) return 0;
        return a.isAll ? -1 : 1;
      });

    for (final album in sortedAlbums) {
      final count = await album.assetCountAsync;
      if (count == 0) continue;
      final end = count < maxVideosToScan ? count : maxVideosToScan;
      final batch = await album.getAssetListRange(start: 0, end: end);
      for (final asset in batch) {
        if (seen.add(asset.id)) result.add(asset);
      }
      if (result.length >= maxVideosToScan) break;
    }

    sortAssetsNewestFirst(result);
    return result;
  }
}
