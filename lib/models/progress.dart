/// Where the user is in each cleanup mode, kept across app launches, so
/// someone who has worked back to 2019 can continue in 2019 next time.
library;

/// The four cleanup modes, each with its own saved position.
enum CleanupMode { photoSwipe, photoGroups, videoSwipe, videoGroups }

/// A position in a newest-first list: the first item the user hasn't
/// reviewed yet. The library may have changed in between (re-scan, deletions
/// elsewhere), so lookups go by asset id and fall back to the date.
class ResumePoint {
  final String assetId;
  final DateTime time;
  const ResumePoint({required this.assetId, required this.time});

  Map<String, Object> toJson() =>
      {'id': assetId, 't': time.millisecondsSinceEpoch};

  static ResumePoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final t = json['t'];
    if (id is! String || t is! int) return null;
    return ResumePoint(
        assetId: id, time: DateTime.fromMillisecondsSinceEpoch(t));
  }
}

/// Saved progress for one mode.
class SavedProgress {
  /// The deepest (oldest) point reached and not yet reviewed — "Continue
  /// from" goes here. Null once the whole library has been gone through.
  final ResumePoint? at;

  /// Date of the newest item the user had when they last started from the
  /// newest. Anything newer arrived since — "New since last time".
  final DateTime? top;

  const SavedProgress({this.at, this.top});

  Map<String, Object?> toJson() => {
        'at': at?.toJson(),
        'top': top?.millisecondsSinceEpoch,
      };

  static SavedProgress? fromJson(Object? json) {
    if (json is! Map) return null;
    final top = json['top'];
    return SavedProgress(
      at: ResumePoint.fromJson(json['at']),
      top: top is int ? DateTime.fromMillisecondsSinceEpoch(top) : null,
    );
  }
}
