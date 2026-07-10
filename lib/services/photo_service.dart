import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';
import '../utils/asset_utils.dart';

/// Loads photos and groups them **purely by capture time** — no file reads and
/// no image decoding. This keeps analysis fast and light even for libraries
/// with tens of thousands of photos.
///
/// Photos taken within [timeWindowSeconds] of each other are treated as the
/// same moment (a burst / near-identical shot) and grouped together.
class PhotoService {
  /// Photos taken within this many seconds of each other are grouped.
  /// 3 minutes: loose enough to catch "retook the same shot a couple times"
  /// without chaining a whole outing into one giant group.
  static const int timeWindowSeconds = 180;

  /// Safety cap on how many photos to scan.
  static const int maxPhotosToScan = 50000;

  static final FilterOptionGroup _newestFirstFilter = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
    // IMPORTANT: FilterOptionGroup silently applies a default createTimeCond
    // of "epoch .. now()", which HIDES every asset whose MediaStore date is in
    // the future (wrong camera clock, OEM millisecond bugs, files copied with
    // odd timestamps). We want every photo, so disable the date conditions.
    createTimeCond: DateTimeCond.def().copyWith(ignore: true),
    updateTimeCond: DateTimeCond.def().copyWith(ignore: true),
    orders: [
      const OrderOption(type: OrderOptionType.createDate, asc: false),
    ],
  );

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state == PermissionState.authorized ||
        state == PermissionState.limited;
  }

  /// Total number of image assets (metadata only — very fast). Used to show
  /// library stats on the home screen without loading every photo.
  Future<int> totalCount() async {
    final assets = await loadAllAssets();
    return assets.length;
  }

  /// Load every image once (deduped), sorted newest-in-library first.
  ///
  /// Some OEMs expose an incomplete "All photos" album, so we merge every
  /// image album and keep the superset.
  Future<List<AssetEntity>> loadAllAssets() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: _newestFirstFilter,
    );
    if (albums.isEmpty) return [];

    final seen = <String>{};
    final result = <AssetEntity>[];

    // Prefer the system "All" album when present, then merge the rest so
    // nothing is missed on Samsung/Xiaomi/etc.
    final sortedAlbums = [...albums]
      ..sort((a, b) {
        if (a.isAll == b.isAll) return 0;
        return a.isAll ? -1 : 1;
      });

    for (final album in sortedAlbums) {
      final count = await album.assetCountAsync;
      if (count == 0) continue;
      final end = count < maxPhotosToScan ? count : maxPhotosToScan;
      final batch = await album.getAssetListRange(start: 0, end: end);
      for (final asset in batch) {
        if (seen.add(asset.id)) result.add(asset);
      }
      if (result.length >= maxPhotosToScan) break;
    }

    sortAssetsNewestFirst(result);
    return result;
  }

  /// Group assets by capture time. No file reads, no decoding → fast.
  Future<List<PhotoGroup>> groupAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return [];

    final sorted = [...assets]
      ..sort((a, b) =>
          captureSortTime(b).compareTo(captureSortTime(a)));

    final List<PhotoGroup> groups = [];
    List<AssetEntity> current = [sorted.first];
    int gi = 0;

    void flush() {
      // A "group" only makes sense with at least two near-simultaneous photos.
      if (current.length >= 2) {
        groups.add(PhotoGroup(
          id: 'group_$gi',
          assets: List.of(current),
          groupDate: captureSortTime(current.first),
          sizeBytes: current.length * kAvgPhotoBytes,
          similarityScore: 0.95,
        ));
        gi++;
      }
    }

    for (int i = 1; i < sorted.length; i++) {
      final diff = captureSortTime(current.last)
          .difference(captureSortTime(sorted[i]))
          .abs();
      if (diff.inSeconds <= timeWindowSeconds) {
        current.add(sorted[i]);
      } else {
        flush();
        current = [sorted[i]];
      }
    }
    flush();

    // Newest groups first (by most recently added/touched photo in the group).
    groups.sort((a, b) {
      final aNewest = a.assets.map(librarySortTime).reduce(
            (x, y) => x.isAfter(y) ? x : y,
          );
      final bNewest = b.assets.map(librarySortTime).reduce(
            (x, y) => x.isAfter(y) ? x : y,
          );
      return bNewest.compareTo(aNewest);
    });

    return groups;
  }

  /// Estimated library statistics (no file reads).
  LibraryStats estimateStats(int totalPhotos, List<PhotoGroup> groups) {
    int savings = 0;
    for (final g in groups) {
      savings += g.savingsBytes;
    }
    return LibraryStats(
      totalPhotos: totalPhotos,
      totalSizeBytes: totalPhotos * kAvgPhotoBytes,
      duplicateGroups: groups.length,
      potentialSavingsBytes: savings,
    );
  }
}
