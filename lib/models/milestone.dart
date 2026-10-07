/// Lifetime "space freed" milestones (REDESIGN_1.3_PLAN.md §4.2).
///
/// Only confirmed deletions count towards them, and each tier is celebrated
/// once — the highest one reached is persisted as `milestone_index`.
class Milestone {
  /// Position on the [ladder], 0-based.
  final int index;

  /// Threshold in bytes (binary units: 1 MB = 1024 × 1024).
  final int bytes;

  const Milestone._(this.index, this.bytes);

  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * _mb;

  static const List<Milestone> ladder = [
    Milestone._(0, 100 * _mb),
    Milestone._(1, 250 * _mb),
    Milestone._(2, 500 * _mb),
    Milestone._(3, 1 * _gb),
    Milestone._(4, 2 * _gb),
    Milestone._(5, 5 * _gb),
    Milestone._(6, 10 * _gb),
    Milestone._(7, 25 * _gb),
    Milestone._(8, 50 * _gb),
  ];

  bool get isGb => bytes >= _gb;

  /// The number on the badge: "100", "250", "1", "50".
  String get valueLabel => isGb ? '${bytes ~/ _gb}' : '${bytes ~/ _mb}';

  /// The unit under it: "MB" or "GB".
  String get unitLabel => isGb ? 'GB' : 'MB';

  /// "100 MB", "1 GB".
  String get label => '$valueLabel $unitLabel';

  /// Index of the highest tier [freedBytes] has reached, or −1 for none.
  static int reachedIndex(int freedBytes) {
    var reached = -1;
    for (final m in ladder) {
      if (freedBytes >= m.bytes) reached = m.index;
    }
    return reached;
  }

  /// The next tier above [reachedIdx], or null when every tier is reached.
  static Milestone? after(int reachedIdx) =>
      reachedIdx + 1 < ladder.length ? ladder[reachedIdx + 1] : null;

  @override
  bool operator ==(Object other) =>
      other is Milestone && other.index == index;

  @override
  int get hashCode => index;
}
