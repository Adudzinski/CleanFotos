import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../utils/asset_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_card.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/idle_gesture_hint.dart';
import '../l10n/strings.dart';

/// Picture Group's accent — a deeper rose, same family as Picture Swipe's pink.
const Color kPictureGroupAccent = Color(0xFFE8537A);

class GroupReviewScreen extends StatefulWidget {
  final List<PhotoGroup> groups;

  const GroupReviewScreen({super.key, required this.groups});

  @override
  State<GroupReviewScreen> createState() => _GroupReviewScreenState();
}

class _GroupReviewScreenState extends State<GroupReviewScreen> {
  late List<PhotoGroup> _groups;
  int _currentIndex = 0;

  /// All photos in the current group (scrollable). Shrinks as photos are deleted.
  final List<AssetEntity> _photos = [];
  /// Selected for deletion
  final Set<String> _selectedIds = {};

  /// See note in home_screen: CelebrationOverlay.of() looks up the tree, so
  /// a GlobalKey is required to reach the overlay this screen builds.
  final GlobalKey<CelebrationOverlayState> _celebrationKey =
      GlobalKey<CelebrationOverlayState>();

  /// Photos marked across ALL groups, deleted in one batch when leaving.
  final List<AssetEntity> _pendingDelete = [];
  bool _deletionsCommitted = false;

  /// Grid scrolling + how far the user has pulled past either end.
  final ScrollController _scroll = ScrollController();
  double _overscroll = 0;
  /// Guards against the iOS bounce re-triggering navigation.
  bool _navLock = false;

  /// How far past the edge you must pull to flip to the next/previous group.
  static const double _kOverscrollTrigger = 90;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _loadGroup(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadGroup(int index) {
    if (index >= _groups.length) return;
    _selectedIds.clear();
    _photos
      ..clear()
      ..addAll(_groups[index].assets);
  }

  PhotoGroup get _currentGroup => _groups[_currentIndex];

  bool get _hasMore => _currentIndex < _groups.length - 1;

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selectedIds.contains(asset.id)) {
        _selectedIds.remove(asset.id);
      } else {
        _selectedIds.add(asset.id);
      }
    });
  }

  /// Queue whatever is selected in this group for deletion. Nothing is removed
  /// from the device yet — everything is committed in ONE system prompt when
  /// the user leaves (see [_commitDeletions]), which is what keeps the flow
  /// fast instead of firing an OS dialog per group.
  void _queueSelected() {
    if (_selectedIds.isEmpty) return;
    final picked =
        _photos.where((a) => _selectedIds.contains(a.id)).toList();
    if (picked.isEmpty) return;

    _pendingDelete.addAll(picked);
    final s = AppStrings.of(context.read<AppProvider>().languageCode);
    _celebrationKey.currentState?.celebrate(
        s.freedLabel(_formatBytes(picked.length * kAvgPhotoBytes)));

    setState(() {
      final queued = Set<String>.from(_selectedIds);
      _photos.removeWhere((a) => queued.contains(a.id));
      _selectedIds.clear();
    });
  }

  /// Delete everything queued across all groups in a single batch.
  Future<void> _commitDeletions() async {
    if (_deletionsCommitted || _pendingDelete.isEmpty) return;
    _deletionsCommitted = true;
    final provider = context.read<AppProvider>();
    final batch = List<AssetEntity>.from(_pendingDelete);
    _pendingDelete.clear();
    await provider.deleteAssets(batch);
    // A declined prompt is final — the photos simply stay in the library.
  }

  /// Leave Group Review, committing queued deletions first.
  Future<void> _exitGroupReview() async {
    await _commitDeletions();
    if (mounted) Navigator.of(context).pop();
  }

  /// Move to the next group, queueing anything selected on the way out.
  void _advanceGroup() {
    _queueSelected();
    if (_hasMore) {
      setState(() {
        _currentIndex++;
        _loadGroup(_currentIndex);
      });
      _resetScroll();
    } else {
      _exitGroupReview();
    }
  }

  /// Move back to the previous group, queueing anything selected first.
  void _previousGroup() {
    _queueSelected();
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      _loadGroup(_currentIndex);
    });
    _resetScroll();
  }

  void _resetScroll() {
    _overscroll = 0;
    _navLock = false;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Detect a pull past either end of the grid and turn it into group
  /// navigation. This must handle BOTH scroll physics:
  ///
  ///  • Android (ClampingScrollPhysics) never scrolls past the edge and instead
  ///    reports OverscrollNotification deltas.
  ///  • iOS (BouncingScrollPhysics) lets the position travel beyond the edge
  ///    and emits almost no overscroll notifications — so we measure how far
  ///    past the extent we are instead. Without this, the gesture silently did
  ///    nothing on iPhone.
  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollEndNotification) {
      _overscroll = 0;
      _navLock = false;
      return false;
    }
    if (_navLock) return false;

    final m = n.metrics;
    double past = 0;
    if (m.pixels > m.maxScrollExtent) {
      past = m.pixels - m.maxScrollExtent;
    } else if (m.pixels < m.minScrollExtent) {
      past = m.pixels - m.minScrollExtent;
    }

    if (past != 0) {
      _overscroll = past; // iOS: absolute overshoot
    } else if (n is OverscrollNotification) {
      _overscroll += n.overscroll; // Android: accumulated deltas
    }

    if (_overscroll > _kOverscrollTrigger) {
      _overscroll = 0;
      _navLock = true; // don't re-fire while the bounce settles
      _advanceGroup();
    } else if (_overscroll < -_kOverscrollTrigger) {
      _overscroll = 0;
      _navLock = true;
      _previousGroup();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    if (_groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.groupMode)),
        body: Center(child: Text(s.allClean)),
      );
    }

    final group = _currentGroup;
    final remaining = _photos.length;
    final totalInGroup = group.totalCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitGroupReview();
      },
      child: CelebrationOverlay(
      key: _celebrationKey,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(context, s),
        body: IdleGestureHint(
          tapHint: s.idleTapHintPhotos,
          swipeHint: s.idleSwipeHint,
          child: Column(
          children: [
            // Progress
            _buildProgressBar(context, s),

            // Group info bar
            _buildGroupInfo(context, group, totalInGroup, remaining, s),

            // Photo grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildPhotoGrid(context, s),
              ),
            ),

            // Bottom action bar
            _buildActionBar(context, s),
          ],
        ),
        ),
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppStrings s) {
    return AppBar(
      title: Text(s.groupMode),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitGroupReview,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AppStrings s) {
    final progress = _groups.isEmpty
        ? 1.0
        : (_currentIndex + 1) / widget.groups.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.groupOf(
                    _currentIndex + 1, widget.groups.length),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kPictureGroupAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kPictureGroupAccent.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kPictureGroupAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, PhotoGroup group,
      int totalInGroup, int remaining, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(_groupDisplayDate(group)),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (group.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(group.location!,
                          style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, AppStrings s) {
    // All photos in the group, in a scrollable grid (same tile size as before).
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: GridView.builder(
      controller: _scroll,
      // Always scrollable so an overscroll gesture exists even when the group
      // has too few photos to fill the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _photos.length,
      itemBuilder: (context, i) {
        final asset = _photos[i];
        final selected = _selectedIds.contains(asset.id);
        return PhotoCard(
          asset: asset,
          selected: selected,
          onTap: () => _toggleSelect(asset),
          onLongPress: () => PhotoDetailDialog.show(context, asset),
        );
      },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppStrings s) {
    final selectedCount = _selectedIds.length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.recoverHint,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          // One action only. "Next" is gone: swipe right, or pull past the
          // top/bottom of the grid, to move between groups — anything marked
          // is queued automatically.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasSelection ? _advanceGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.danger.withOpacity(0.4),
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasSelection ? s.deleteCount(selectedCount) : s.deleteBtn,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _groupDisplayDate(PhotoGroup group) {
    return group.assets
        .map(librarySortTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
