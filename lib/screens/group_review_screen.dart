import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../l10n/strings.dart';
import '../models/delete_result.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../services/feedback_service.dart';
import '../theme/noir.dart';
import '../utils/asset_utils.dart';
import '../utils/format.dart';
import '../utils/video_utils.dart';
import '../widgets/noir/noir_widgets.dart';
import '../widgets/photo_card.dart' show PhotoDetailDialog;
import 'session.dart';

/// "Similar shots" / "Similar clips" — one time-group at a time; tap the
/// items you don't want (REDESIGN_1.3_PLAN.md §5.4).
///
/// Navigation is explicit: "Keep all · Next" / "Delete n · Next" and a
/// Previous button. (The overscroll navigation and idle hints of 1.2 were
/// removed on purpose.) Marks go into the provider's persisted queue when the
/// user moves on, and everything is deleted in ONE system prompt at Finish.
class GroupReviewScreen extends StatefulWidget {
  final List<PhotoGroup> groups;
  final int startIndex;
  final MediaKind kind;

  const GroupReviewScreen({
    super.key,
    required this.groups,
    this.startIndex = 0,
    this.kind = MediaKind.photos,
  });

  @override
  State<GroupReviewScreen> createState() => _GroupReviewScreenState();
}

class _GroupReviewScreenState extends State<GroupReviewScreen> {
  late final AppProvider _provider;
  late final List<PhotoGroup> _groups = List.of(widget.groups);
  late int _index = widget.startIndex.clamp(0, widget.groups.length - 1);

  /// Marked in the current group.
  final Set<String> _selected = {};
  bool _finishing = false;

  bool get _isVideo => widget.kind == MediaKind.videos;
  PhotoGroup get _group => _groups[_index];
  bool get _isLast => _index >= _groups.length - 1;

  final ScrollController _scroll = ScrollController();

  // ── Hold-to-play (videos), inline in the tile ────────────────────────────
  // One player at a time, built on long-press and torn down on release, so
  // we never hold N players in memory.
  String? _playingId;
  VideoPlayerController? _playCtrl;
  bool _playReady = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppProvider>();
    // Holds the background library re-scan back until we're done.
    _provider.inCleanupSession = true;
    _loadGroup();
  }

  @override
  void dispose() {
    _provider.inCleanupSession = false;
    _playCtrl?.removeListener(_onTick);
    _playCtrl?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Show the group with whatever is already queued pre-marked, so going
  /// back to a group shows what will be deleted.
  void _loadGroup() {
    _selected
      ..clear()
      ..addAll(_group.assets.where((a) => _provider.isQueued(a.id)).map((a) => a.id));
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (_selected.remove(asset.id)) {
        FeedbackService.instance.play(Fx.unmark);
      } else {
        _selected.add(asset.id);
        FeedbackService.instance.play(Fx.mark);
      }
    });
  }

  /// Sync this group's marks into the persisted queue: queue what's marked,
  /// take back anything unmarked. Returns how many items are newly queued.
  int _queueSelected() {
    final picked = _group.assets.where((a) => _selected.contains(a.id)).toList();
    final unpicked = _group.assets
        .where((a) => !_selected.contains(a.id) && _provider.isQueued(a.id))
        .toList();
    final fresh = picked.where((a) => !_provider.isQueued(a.id)).length;
    // Persist the marks immediately. The OS confirmation can only be shown by
    // a foreground app, so if the user force-quits mid-session we finish the
    // job on next launch instead of silently losing their work.
    if (picked.isNotEmpty) {
      unawaited(_provider.queueForDeletion(picked, notify: false));
    }
    if (unpicked.isNotEmpty) {
      unawaited(_provider.unqueueDeletion(unpicked, notify: false));
    }
    return fresh;
  }

  Future<void> _next() async {
    if (_finishing) return;
    await _stopPlay();
    final count = _selected.length;
    final fresh = _queueSelected();
    if (count > 0) {
      FeedbackService.instance.play(Fx.groupDone);
      if (fresh > 0 && mounted) {
        final avg = _isVideo ? kAvgVideoBytes : _provider.avgPhotoBytes;
        NoirToast.show(context,
            AppStrings.of(_provider.languageCode).markedToast(
                formatBytes(fresh * avg, _provider.languageCode)));
      }
    } else {
      FeedbackService.instance.play(Fx.groupKeep);
    }
    if (_isLast) {
      await _finish(resume: null);
      return;
    }
    setState(() {
      _index++;
      _loadGroup();
    });
  }

  Future<void> _previous() async {
    if (_index == 0 || _finishing) return;
    await _stopPlay();
    _queueSelected();
    FeedbackService.instance.play(Fx.tap);
    setState(() {
      _index--;
      _loadGroup();
    });
  }

  /// The X / back button. What's marked in the current group counts too —
  /// "finish" means "I'm done, delete what I marked".
  Future<void> _finishFromHeader() async {
    if (_finishing) return;
    await _stopPlay();
    _queueSelected();
    final first = _group.assets.first;
    await _finish(
        resume: ResumePoint(assetId: first.id, time: librarySortTime(first)));
  }

  Future<void> _finish({required ResumePoint? resume}) async {
    if (_finishing) return;
    _finishing = true;
    await finishSession(context,
        provider: _provider, kind: widget.kind, resume: resume);
    if (mounted) _finishing = false;
  }

  // ── Video playback ───────────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);
    final group = _group;
    final newest = group.assets
        .map(librarySortTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final n = group.assets.length;
    final marked = _selected.length;

    final String cta;
    if (marked == 0) {
      cta = _isLast ? s.keepAllFinish : s.keepAllNext;
    } else {
      cta = _isLast ? s.deleteFinish(marked) : s.deleteNext(marked);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finishFromHeader();
      },
      child: Scaffold(
        backgroundColor: Noir.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NoirHeader(
                  leading: NoirIconButton(
                    icon: Icons.close_rounded,
                    semanticLabel: s.finish,
                    onPressed: _finishFromHeader,
                  ),
                  title: s.shortDate(newest, withTime: true),
                  subtitle: _isVideo ? s.similarClipsCount(n) : s.similarCount(n),
                  trailing: Text('${_index + 1} / ${_groups.length}',
                      style: NoirText.caption
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                ProgressTrack(value: (_index + 1) / _groups.length),
                const SizedBox(height: 14),
                Text(_isVideo ? s.tapToMarkVideos : s.tapToMark,
                    style: NoirText.secondary
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: n,
                    itemBuilder: (context, i) {
                      final asset = group.assets[i];
                      final playing = _playingId == asset.id;
                      return _Tile(
                        asset: asset,
                        isVideo: _isVideo,
                        marked: _selected.contains(asset.id),
                        onTap: () => _toggle(asset),
                        onHoldStart: _isVideo
                            ? () => _startPlay(asset)
                            : () => PhotoDetailDialog.show(context, asset),
                        onHoldEnd: _isVideo ? _stopPlay : null,
                        controller: playing && _playReady ? _playCtrl : null,
                        loading: playing && !_playReady,
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    NoirButton.secondary(
                      icon: Icons.chevron_left_rounded,
                      semanticLabel: s.previousGroup,
                      onPressed: _index == 0 ? null : _previous,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: marked == 0
                          ? NoirButton.primary(label: cta, onPressed: _next)
                          : NoirButton.danger(label: cta, onPressed: _next),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square grid tile. Marked = red border, dimmed image, trash badge.
/// Videos play inline while held.
class _Tile extends StatelessWidget {
  final AssetEntity asset;
  final bool isVideo;
  final bool marked;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback? onHoldEnd;
  final VideoPlayerController? controller;
  final bool loading;

  const _Tile({
    required this.asset,
    required this.isVideo,
    required this.marked,
    required this.onTap,
    required this.onHoldStart,
    this.onHoldEnd,
    this.controller,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final playing = controller != null;
    final media = playing
        ? FittedBox(
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
        : AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(400),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Noir.surface2,
              child: Icon(
                  isVideo
                      ? Icons.videocam_off_outlined
                      : Icons.broken_image_outlined,
                  color: Noir.faint),
            ),
          );

    return Semantics(
      button: true,
      selected: marked,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onHoldStart(),
        onLongPressEnd: onHoldEnd == null ? null : (_) => onHoldEnd!(),
        onLongPressCancel: onHoldEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Noir.surface,
            borderRadius: BorderRadius.circular(Noir.rCard),
          ),
          // Painted over the photo, so an unmarked tile has no inset rim.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Noir.rCard),
            border: Border.all(
              color: marked ? Noir.danger : Colors.transparent,
              width: 3,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                opacity: marked && !playing ? 0.45 : 1,
                duration: const Duration(milliseconds: 150),
                child: media,
              ),
              if (isVideo && !playing)
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                  ),
                ),
              if (isVideo)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: ShapeDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(formatVideoDuration(asset.videoDuration),
                        style: const TextStyle(
                            fontFamily: NoirText.family,
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              if (marked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: Noir.danger, shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
