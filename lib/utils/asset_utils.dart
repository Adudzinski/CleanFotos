import 'package:photo_manager/photo_manager.dart';

/// Recency for gallery ordering — the capture date, like the system gallery.
///
/// [AssetEntity.createDateTime] is DATE_TAKEN (when the photo was captured),
/// which is what users think of as "newest". We deliberately do NOT mix in
/// [AssetEntity.modifiedDateTime]: DATE_MODIFIED gets rewritten in bulk by
/// file transfers, backups, and MediaStore re-scans, which shuffles old photos
/// to the front and makes the deck start somewhere random instead of at the
/// newest picture.
///
/// Only when an asset has no usable capture date (some downloads / shared
/// images report the epoch) do we fall back to the modified time, so those
/// don't all sink to 1970 at the bottom.
DateTime librarySortTime(AssetEntity asset) {
  final created = asset.createDateTime;
  if (created.year < 2000) return asset.modifiedDateTime;
  return created;
}

/// Capture time for burst / duplicate grouping (when the shutter fired).
DateTime captureSortTime(AssetEntity asset) => asset.createDateTime;

int compareLibraryNewestFirst(AssetEntity a, AssetEntity b) =>
    librarySortTime(b).compareTo(librarySortTime(a));

void sortAssetsNewestFirst(List<AssetEntity> assets) {
  assets.sort(compareLibraryNewestFirst);
}
