import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';

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

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state == PermissionState.authorized ||
        state == PermissionState.limited;
  }

  /// Total number of image assets (metadata only — very fast). Used to show
  /// library stats on the home screen without loading every photo.
  Future<int> totalCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isEmpty) return 0;
    final count = await albums.first.assetCountAsync;
    return count < maxPhotosToScan ? count : maxPhotosToScan;
  }

  /// Load all image assets (metadata only — fast), newest first.
  Future<List<AssetEntity>> loadAllAssets() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (albums.isEmpty) return [];
    final all = albums.first;
    final count = await all.assetCountAsync;
    final end = count < maxPhotosToScan ? count : maxPhotosToScan;
    return all.getAssetListRange(start: 0, end: end);
  }

  /// Group assets by capture time. No file reads, no decoding → fast.
  /// [assets] need not be pre-sorted.
  Future<List<PhotoGroup>> groupAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return [];

    final sorted = [...assets]
      ..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    final List<PhotoGroup> groups = [];
    List<AssetEntity> current = [sorted.first];
    int gi = 0;

    void flush() {
      // A "group" only makes sense with at least two near-simultaneous photos.
      if (current.length >= 2) {
        groups.add(PhotoGroup(
          id: 'group_$gi',
          assets: List.of(current),
          groupDate: current.first.createDateTime,
          sizeBytes: current.length * kAvgPhotoBytes,
          similarityScore: 0.95,
        ));
        gi++;
      }
    }

    for (int i = 1; i < sorted.length; i++) {
      final diff = current.last.createDateTime
          .difference(sorted[i].createDateTime)
          .abs();
      if (diff.inSeconds <= timeWindowSeconds) {
        current.add(sorted[i]);
      } else {
        flush();
        current = [sorted[i]];
      }
    }
    flush();

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
