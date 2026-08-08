import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../utils/asset_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/idle_gesture_hint.dart';
import '../l10n/strings.dart';
/// Video Group's own accent — deliberately different from Video Swipe's teal.
const Color kVideoGroupAccent = Color(0xFF2563EB);

/// Build a player for a gallery asset.
///
/// `contentUri` is Android-only (content:// URIs). On iOS `getMediaUrl()`
/// hands back a file URL, so we must go through the file API instead —
/// otherwise playback silently fails on iPhone.
Future<VideoPlayerController?> buildAssetVideoController(
    AssetEntity asset) async {
  if (Platform.isAndroid) {
    final url = await asset.getMediaUrl();
    if (url == null) return null;
    return VideoPlayerController.contentUri(Uri.parse(url));
  }
  final f = await asset.file;
  if (f == null) return null;
  return VideoPlayerController.file(f);
}


/// Video Group — the same review model as Picture Group, but each tile is a
/// video with a play badge, and holding a tile opens it full-screen with a
/// real player.
///
/// Interaction (identical to Picture Group so the two feel like one product):
///   • tap a tile to mark it for deletion
///   • pull past the bottom of the grid for the next group, past the top for
///     the previous one — anything marked is queued on the way
///   • everything queued is deleted in ONE system prompt when you leave
class VideoGroupReviewScreen extends StatefulWidget {
  final List<PhotoGroup> groups;

  const VideoGroupReviewScreen({super.key, required this.groups});

  @override
  State<VideoGroupReviewScreen> createState() => _VideoGroupReviewScreenState();
}

class _VideoGroupReviewScreenState extends State<VideoGroupReviewScreen> {
  late List<PhotoGroup> _groups;
  int _currentIndex = 0;

  final List<AssetEntity> _videos = [];
  final Set<String> _selectedIds = {};

  final GlobalKey<CelebrationOverlayState> _celebrationKey =
      GlobalKey<CelebrationOverlayState>();

  /// Marked across ALL groups, deleted in one batch when leaving.
  final List<AssetEntity> _pendingDelete = [];
  bool _deletionsCommitted = false;

  final ScrollController _scroll = ScrollController();
  double _overscroll = 0;
  /// Guards against the iOS bounce re-triggering navigation.
  bool _navLock = false;
  static const double _kOverscrollTrigger = 90;

  // ── Hold-to-play, inline in the tile ──────────────────────────────────────
  // Only one video plays at a time; the controller is built on long-press and
  // torn down on release, so we never hold N players in memory.
  String? _playingId;
  VideoPlayerController? _playCtrl;
  bool _playReady = false;

  Future<void> _startPlay(AssetEntity asset) async {
    await _stopPlay();
    if (!mounted) return;
    setState(() {
      _playingId = asset.id;
      _playReady = false;
    });
    try {
      final ctrl = await buildAssetVideoController(asset);
      if (ctrl == null) return;
      // The user may have let go while the controller was loading.
      if (!mounted || _playingId != asset.id) {
        await ctrl.dispose();
        return;
      }
      _playCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(1.0);
      if (!mounted || _playingId != asset.id) {
        await ctrl.dispose();
        _playCtrl = null;
        return;
      }
      ctrl.addListener(_onTick);
      await ctrl.play();
      if (mounted) setState(() => _playReady = true);
    } catch (_) {
      if (mounted) setState(() => _playReady = false);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _stopPlay() async {
    final c = _playCtrl;
    _playCtrl = null;
    _playReady = false;
    _playingId = null;
    if (c != null) {
      c.removeListener(_onTick);
      await c.pause();
      await c.dispose();
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _loadGroup(0);
  }

  @override
  void dispose() {
    _playCtrl?.removeListener(_onTick);
    _playCtrl?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _loadGroup(int index) {
    if (index >= _groups.length) return;
    _selectedIds.clear();
    _videos
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

  void _queueSelected() {
    if (_selectedIds.isEmpty) return;
    final picked =
        _videos.where((a) => _selectedIds.contains(a.id)).toList();
    if (picked.isEmpty) return;

    _pendingDelete.addAll(picked);
    final s = AppStrings.of(context.read<AppProvider>().languageCode);
    _celebrationKey.currentState?.celebrate(
        s.freedLabel(_formatBytes(picked.length * kAvgVideoBytes)));

    setState(() {
      final queued = Set<String>.from(_selectedIds);
      _videos.removeWhere((a) => queued.contains(a.id));
      _selectedIds.clear();
    });
  }

  Future<void> _commitDeletions() async {
    if (_deletionsCommitted || _pendingDelete.isEmpty) return;
    _deletionsCommitted = true;
    final provider = context.read<AppProvider>();
    final batch = List<AssetEntity>.from(_pendingDelete);
    _pendingDelete.clear();
    await provider.deleteAssets(batch);
  }

  Future<void> _exit() async {
    await _commitDeletions();
    if (mounted) Navigator.of(context).pop();
  }

  void _advanceGroup() {
    _queueSelected();
    if (_hasMore) {
      setState(() {
        _currentIndex++;
        _loadGroup(_currentIndex);
      });
      _resetScroll();
    } else {
      _exit();
    }
  }

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
        appBar: AppBar(title: Text(s.videoGroupMode)),
        body: Center(child: Text(s.allClean)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: CelebrationOverlay(
        key: _celebrationKey,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(s.videoGroupMode),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exit,
            ),
          ),
          body: IdleGestureHint(
            tapHint: s.idleTapHintVideos,
            swipeHint: s.idleSwipeHint,
            child: Column(
              children: [
                _buildProgressBar(s),
                _buildGroupInfo(_currentGroup),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildGrid(),
                  ),
                ),
                _buildActionBar(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(AppStrings s) {
    final progress = (_currentIndex + 1) / widget.groups.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.groupOf(_currentIndex + 1, widget.groups.length),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kVideoGroupAccent)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kVideoGroupAccent.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(kVideoGroupAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(PhotoGroup group) {
    final date = group.assets
        .map(librarySortTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppTheme.surface,
      alignment: Alignment.centerLeft,
      child: Text(
        _formatDate(date),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildGrid() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: _videos.length,
        itemBuilder: (context, i) {
          final asset = _videos[i];
          final isPlaying = _playingId == asset.id;
          return _VideoTile(
            asset: asset,
            selected: _selectedIds.contains(asset.id),
            onTap: () => _toggleSelect(asset),
            onHoldStart: () => _startPlay(asset),
            onHoldEnd: _stopPlay,
            controller: isPlaying && _playReady ? _playCtrl : null,
            loading: isPlaying && !_playReady,
          );
        },
      ),
    );
  }

  Widget _buildActionBar(AppStrings s) {
    final count = _selectedIds.length;
    final hasSelection = count > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasSelection ? _advanceGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.danger.withValues(alpha: 0.4),
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
                  hasSelection ? s.deleteCount(count) : s.deleteBtn,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Grid tile: video thumbnail + play badge + duration.
class _VideoTile extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  /// Non-null while THIS tile is the one playing — the video is rendered
  /// straight into the tile instead of a separate screen.
  final VideoPlayerController? controller;
  final bool loading;

  const _VideoTile({
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
    this.controller,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final playing = controller != null;
    return GestureDetector(
      onTap: onTap,
      // Press and hold plays the video right here in the tile; releasing
      // (or dragging away) stops it.
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      onLongPressCancel: onHoldEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.danger : Colors.transparent,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.danger.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (playing)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.size.width == 0
                        ? 200
                        : controller!.value.size.width,
                    height: controller!.value.size.height == 0
                        ? 200
                        : controller!.value.size.height,
                    child: VideoPlayer(controller!),
                  ),
                )
              else
                AssetEntityImage(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(400),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black26,
                    child: const Icon(Icons.videocam_off_outlined,
                        color: Colors.white70),
                  ),
                ),
              // Play badge — hidden while playing; a spinner shows during load.
              if (!playing)
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 30),
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _duration(asset.videoDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _duration(Duration d) {
    final m = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}
