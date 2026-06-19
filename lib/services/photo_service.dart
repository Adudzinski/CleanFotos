import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';

/// Service that loads photos and groups similar ones together.
///
/// **Time is the primary signal.** Photos taken within [timeWindowMinutes] of
/// each other are treated as one group — bursts/selfies shot back-to-back are
/// similar by default, so we don't need a perfect visual match.
///
/// Two lighter signals refine the result:
///   • **Location** – if both photos have GPS, they must be within
///     [locationRadiusMeters] to stay in the same group.
///   • **Visual hash** – only used to break up *unusually large* time clusters
///     (more than [visualSplitThreshold] photos), so a long continuous shooting
///     session doesn't collapse into one giant group. The threshold is
///     deliberately lenient ([maxHammingDistance]) so time stays dominant.
///
/// Groups are returned newest-first.
class PhotoService {
  /// Photos within this many minutes are considered the same moment.
  static const int timeWindowMinutes = 5;

  /// Max GPS distance (meters) for two photos to share a group.
  static const double locationRadiusMeters = 200;

  /// Only run the visual hash when a time cluster has more photos than this.
  static const int visualSplitThreshold = 12;

  /// dHash is 64 bits. When splitting big clusters, two photos count as
  /// similar if at most this many bits differ (lenient → keeps groups together).
  static const int maxHammingDistance = 20;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Request permission and return whether it was granted.
  ///
  /// Accepts both full ("authorized") and partial ("limited") access — on
  /// Android 14+ and iOS, granting access often returns `limited`, which still
  /// lets us read photos.
  Future<bool> requestPermission() async {
    final PermissionState state =
        await PhotoManager.requestPermissionExtend();
    return state == PermissionState.authorized ||
        state == PermissionState.limited;
  }

  /// Load all recent photo groups (newest first).
  Future<List<PhotoGroup>> loadGroups() async {
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

    // Use the "All Photos" album (first result on Android/iOS)
    final allPhotos = albums.first;
    final assets = await allPhotos.getAssetListRange(start: 0, end: 3000);

    if (assets.isEmpty) return [];

    return _groupSimilarAssets(assets);
  }

  /// Compute total library stats.
  Future<LibraryStats> loadStats(List<PhotoGroup> groups) async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    int total = 0;
    if (albums.isNotEmpty) {
      total = await albums.first.assetCountAsync;
    }

    // Reuse the per-group sizes computed during grouping (no re-reading files).
    int totalBytes = 0;
    int savingsBytes = 0;
    for (final g in groups) {
      totalBytes += g.sizeBytes;
      savingsBytes += g.savingsBytes;
    }

    return LibraryStats(
      totalPhotos: total,
      totalSizeBytes: totalBytes,
      duplicateGroups: groups.length,
      potentialSavingsBytes: savingsBytes,
    );
  }

  // ─── Grouping Algorithm ────────────────────────────────────────────────────

  Future<List<PhotoGroup>> _groupSimilarAssets(
      List<AssetEntity> assets) async {
    // Step 1: sort by creation date descending (newest first)
    final sorted = [...assets]..sort(
        (a, b) => b.createDateTime.compareTo(a.createDateTime));

    // Step 2: time-window clustering — the primary signal.
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

    // Step 3: refine each time cluster with location (and, for big clusters,
    // a lenient visual hash).
    final List<PhotoGroup> groups = [];
    int gi = 0;
    for (final cluster in timeClusters) {
      groups.addAll(await _refineCluster(cluster, gi));
      gi++;
    }

    // Only return groups with ≥ 2 photos
    return groups.where((g) => g.assets.length >= 2).toList();
  }

  /// Split a single time cluster into final groups using location, and — only
  /// when the cluster is large — a lenient visual hash.
  Future<List<PhotoGroup>> _refineCluster(
      List<AssetEntity> cluster, int baseIndex) async {
    // Pre-compute GPS coords and file sizes for everyone (no image decode).
    final coords = <String, List<double>?>{};
    final sizes = <String, int>{};
    for (final a in cluster) {
      coords[a.id] = await _coords(a);
      sizes[a.id] = await _fileSize(a);
    }

    // Only decode thumbnails for visual hashing when the cluster is big.
    final useVisual = cluster.length > visualSplitThreshold;
    final hashes = <String, List<int>?>{};
    if (useVisual) {
      for (final a in cluster) {
        hashes[a.id] = await _computeDHash(a);
      }
    }

    final grouped = List<bool>.filled(cluster.length, false);
    final List<PhotoGroup> result = [];
    int subIdx = 0;

    for (int i = 0; i < cluster.length; i++) {
      if (grouped[i]) continue;
      final group = [cluster[i]];
      grouped[i] = true;

      for (int j = i + 1; j < cluster.length; j++) {
        if (grouped[j]) continue;
        if (_belongTogether(cluster[i], cluster[j], coords, hashes, useVisual)) {
          group.add(cluster[j]);
          grouped[j] = true;
        }
      }

      if (group.length >= 2) {
        final groupSize =
            group.fold<int>(0, (sum, a) => sum + (sizes[a.id] ?? 0));
        result.add(PhotoGroup(
          id: 'group_${baseIndex}_$subIdx',
          assets: group,
          groupDate: group.first.createDateTime,
          location: _coordLabel(coords[group.first.id]),
          similarityScore: useVisual ? 0.85 : 0.95,
          sizeBytes: groupSize,
        ));
        subIdx++;
      }
    }

    return result;
  }

  /// Decide whether two photos (already in the same time window) belong in the
  /// same group. Location and visual checks only ever *exclude* — time already
  /// said yes.
  bool _belongTogether(
    AssetEntity a,
    AssetEntity b,
    Map<String, List<double>?> coords,
    Map<String, List<int>?> hashes,
    bool useVisual,
  ) {
    // Location: if both have GPS and they're far apart, separate them.
    final ca = coords[a.id];
    final cb = coords[b.id];
    if (ca != null && cb != null) {
      if (_distanceMeters(ca[0], ca[1], cb[0], cb[1]) > locationRadiusMeters) {
        return false;
      }
    }

    // Visual: only when splitting big clusters, and only excludes clearly
    // different shots (lenient threshold).
    if (useVisual) {
      final ha = hashes[a.id];
      final hb = hashes[b.id];
      if (ha != null && hb != null) {
        if (_hamming(ha, hb) > maxHammingDistance) return false;
      }
    }

    return true;
  }

  /// Compute a 64-bit perceptual "difference hash" (dHash) from a thumbnail.
  Future<List<int>?> _computeDHash(AssetEntity asset) async {
    try {
      final Uint8List? data =
          await asset.thumbnailDataWithSize(const ThumbnailSize(72, 72));
      if (data == null) return null;

      final decoded = img.decodeImage(data);
      if (decoded == null) return null;

      // 9×8 grayscale → compare each pixel with its right neighbour → 64 bits.
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

  /// Number of differing bits between two equal-length hashes.
  int _hamming(List<int> a, List<int> b) {
    if (a.length != b.length) return 64;
    int d = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) d++;
    }
    return d;
  }

  /// File size of an asset in bytes (0 when unavailable).
  Future<int> _fileSize(AssetEntity asset) async {
    try {
      final f = await asset.file;
      return f == null ? 0 : await f.length();
    } catch (_) {
      return 0;
    }
  }

  /// GPS coordinates as [lat, lng], or null when unavailable.
  Future<List<double>?> _coords(AssetEntity asset) async {
    try {
      final ll = await asset.latlngAsync();
      final lat = ll?.latitude;
      final lng = ll?.longitude;
      if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
      return [lat, lng];
    } catch (_) {
      return null;
    }
  }

  String? _coordLabel(List<double>? c) {
    if (c == null) return null;
    return '${c[0].toStringAsFixed(2)}, ${c[1].toStringAsFixed(2)}';
  }

  /// Great-circle distance between two coordinates, in meters (haversine).
  double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
