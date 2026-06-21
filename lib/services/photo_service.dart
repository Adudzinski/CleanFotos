import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';

/// Loads photos and groups similar ones together.
///
/// **Fast by design:** grouping uses only photo metadata (capture time) — it
/// does NOT read photo files, which on Android means copying each file and is
/// very slow. Sizes are estimated ([kAvgPhotoBytes]); the visual hash is only
/// used to split unusually large bursts.
class PhotoService {
  /// Photos within this many minutes are treated as the same moment.
  static const int timeWindowMinutes = 5;

  /// Only run the visual hash when a time cluster is larger than this.
  static const int visualSplitThreshold = 12;

  /// dHash is 64 bits; two photos are "similar" if at most this many bits
  /// differ (lenient → keeps groups together).
  static const int maxHammingDistance = 20;

  /// Safety cap on how many photos to scan.
  static const int maxPhotosToScan = 50000;

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state == PermissionState.authorized ||
        state == PermissionState.limited;
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

  /// Group assets by time, refining only large bursts with a visual hash.
  /// No file reads → fast. [assets] need not be pre-sorted.
  Future<List<PhotoGroup>> groupAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return [];

    final sorted = [...assets]
      ..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    // Time-window clustering (the primary signal).
    final List<List<AssetEntity>> timeClusters = [];
    List<AssetEntity> current = [sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      final diff = current.last.createDateTime
          .difference(sorted[i].createDateTime)
          .abs();
      if (diff.inMinutes <= timeWindowMinutes) {
        current.add(sorted[i]);
      } else {
        if (current.length > 1) timeClusters.add(current);
        current = [sorted[i]];
      }
    }
    if (current.length > 1) timeClusters.add(current);

    final List<PhotoGroup> groups = [];
    int gi = 0;
    for (final cluster in timeClusters) {
      groups.addAll(await _refineCluster(cluster, gi));
      gi++;
    }
    return groups.where((g) => g.assets.length >= 2).toList();
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

  // ─── Grouping internals ─────────────────────────────────────────────────────

  Future<List<PhotoGroup>> _refineCluster(
      List<AssetEntity> cluster, int baseIndex) async {
    // Small/medium clusters: the whole time cluster is one group (no decoding).
    if (cluster.length <= visualSplitThreshold) {
      return [
        PhotoGroup(
          id: 'group_$baseIndex',
          assets: cluster,
          groupDate: cluster.first.createDateTime,
          sizeBytes: cluster.length * kAvgPhotoBytes,
          similarityScore: 0.95,
        ),
      ];
    }

    // Large burst: sub-split by a lenient visual hash so unrelated runs don't
    // collapse into one giant group.
    final hashes = <String, List<int>?>{};
    for (final a in cluster) {
      hashes[a.id] = await _computeDHash(a);
    }

    final grouped = List<bool>.filled(cluster.length, false);
    final result = <PhotoGroup>[];
    int subIdx = 0;
    for (int i = 0; i < cluster.length; i++) {
      if (grouped[i]) continue;
      final group = [cluster[i]];
      grouped[i] = true;
      for (int j = i + 1; j < cluster.length; j++) {
        if (grouped[j]) continue;
        final ha = hashes[cluster[i].id];
        final hb = hashes[cluster[j].id];
        final similar =
            (ha == null || hb == null) ? true : _hamming(ha, hb) <= maxHammingDistance;
        if (similar) {
          group.add(cluster[j]);
          grouped[j] = true;
        }
      }
      if (group.length >= 2) {
        result.add(PhotoGroup(
          id: 'group_${baseIndex}_$subIdx',
          assets: group,
          groupDate: group.first.createDateTime,
          sizeBytes: group.length * kAvgPhotoBytes,
          similarityScore: 0.85,
        ));
        subIdx++;
      }
    }
    return result;
  }

  /// 64-bit perceptual "difference hash" from a small thumbnail.
  Future<List<int>?> _computeDHash(AssetEntity asset) async {
    try {
      final Uint8List? data =
          await asset.thumbnailDataWithSize(const ThumbnailSize(72, 72));
      if (data == null) return null;
      final decoded = img.decodeImage(data);
      if (decoded == null) return null;
      final resized = img.copyResize(decoded, width: 9, height: 8);
      final bits = <int>[];
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = img.getLuminance(resized.getPixel(x, y));
          final right = img.getLuminance(resized.getPixel(x + 1, y));
          bits.add(left < right ? 1 : 0);
        }
      }
      return bits;
    } catch (_) {
      return null;
    }
  }

  int _hamming(List<int> a, List<int> b) {
    if (a.length != b.length) return 64;
    int d = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) d++;
    }
    return d;
  }
}
