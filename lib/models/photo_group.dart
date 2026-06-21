import 'package:photo_manager/photo_manager.dart';

/// Average photo size used for fast size/savings estimates (~3.5 MB), so we
/// never have to read photo files (which is slow on Android).
const int kAvgPhotoBytes = 3670016;

/// A group of visually/temporally similar photos.
class PhotoGroup {
  final String id;
  final List<AssetEntity> assets;
  final DateTime groupDate;
  final String? location;
  final double similarityScore; // 0.0 – 1.0

  /// Total size in bytes of all assets in the group (computed at load time).
  final int sizeBytes;

  PhotoGroup({
    required this.id,
    required this.assets,
    required this.groupDate,
    this.location,
    this.similarityScore = 1.0,
    this.sizeBytes = 0,
  });

  int get totalCount => assets.length;

  /// Bytes the user would reclaim by keeping just one photo from this group.
  /// Photos in a group are near-identical, so an average-per-photo estimate is
  /// accurate enough for a motivational label.
  int get savingsBytes {
    if (assets.length <= 1 || sizeBytes <= 0) return 0;
    return (sizeBytes * (assets.length - 1) / assets.length).round();
  }

  String get sizeFormatted => formatBytes(sizeBytes);
  String get savingsFormatted => formatBytes(savingsBytes);

  PhotoGroup copyWith({List<AssetEntity>? assets}) {
    final newAssets = assets ?? this.assets;
    // Scale the cached size proportionally when assets are removed.
    final scaledSize = this.assets.isEmpty
        ? 0
        : (sizeBytes * newAssets.length / this.assets.length).round();
    return PhotoGroup(
      id: id,
      assets: newAssets,
      groupDate: groupDate,
      location: location,
      similarityScore: similarityScore,
      sizeBytes: scaledSize,
    );
  }

  /// Shared byte formatter (KB/MB/GB).
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Statistics about the user's photo library.
class LibraryStats {
  final int totalPhotos;
  final int totalSizeBytes;
  final int duplicateGroups;
  final int potentialSavingsBytes;

  const LibraryStats({
    required this.totalPhotos,
    required this.totalSizeBytes,
    required this.duplicateGroups,
    required this.potentialSavingsBytes,
  });

  static const empty = LibraryStats(
    totalPhotos: 0,
    totalSizeBytes: 0,
    duplicateGroups: 0,
    potentialSavingsBytes: 0,
  );

  String get totalSizeFormatted => _formatBytes(totalSizeBytes);
  String get savingsFormatted => _formatBytes(potentialSavingsBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
