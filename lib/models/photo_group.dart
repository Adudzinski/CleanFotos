import 'package:photo_manager/photo_manager.dart';

/// A group of visually/temporally similar photos.
class PhotoGroup {
  final String id;
  final List<AssetEntity> assets;
  final DateTime groupDate;
  final String? location;
  final double similarityScore; // 0.0 – 1.0

  PhotoGroup({
    required this.id,
    required this.assets,
    required this.groupDate,
    this.location,
    this.similarityScore = 1.0,
  });

  int get totalCount => assets.length;

  /// Size in bytes, summed across all assets.
  Future<int> get totalSizeBytes async {
    int total = 0;
    for (final a in assets) {
      final file = await a.file;
      if (file != null) {
        total += await file.length();
      }
    }
    return total;
  }

  PhotoGroup copyWith({List<AssetEntity>? assets}) {
    return PhotoGroup(
      id: id,
      assets: assets ?? this.assets,
      groupDate: groupDate,
      location: location,
      similarityScore: similarityScore,
    );
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
