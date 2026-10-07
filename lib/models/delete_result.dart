import 'milestone.dart';

/// What a cleanup mode was reviewing — picks the noun on the Finished screen.
enum MediaKind { photos, videos, items }

/// The honest outcome of one system delete prompt (REDESIGN_1.3_PLAN.md §4.1).
///
/// Counts and bytes only include items the OS confirmed are gone.
class DeleteResult {
  /// Items we asked the OS to delete.
  final int requested;

  /// Items confirmed gone afterwards.
  final int deleted;

  /// Bytes freed by [deleted]: measured file sizes where we could read them
  /// (Android), the per-type average otherwise (iOS, unreadable files).
  final int bytes;

  /// The user said no — or nothing was deleted for another reason.
  final bool declined;

  /// Android's moveToTrash fallback ran (changes the summary wording).
  final bool usedTrash;

  /// The highest milestone this deletion newly crossed, if any.
  final Milestone? newMilestone;

  const DeleteResult({
    required this.requested,
    required this.deleted,
    required this.bytes,
    required this.declined,
    this.usedTrash = false,
    this.newMilestone,
  });

  /// Nothing was asked: the queue was empty, or every item was already gone.
  static const DeleteResult none = DeleteResult(
    requested: 0,
    deleted: 0,
    bytes: 0,
    declined: false,
  );

  bool get confirmed => deleted > 0;
}
