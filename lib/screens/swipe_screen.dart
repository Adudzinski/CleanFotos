import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../l10n/strings.dart';
import '../models/delete_result.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../services/feedback_service.dart';
import '../theme/noir.dart';
import '../utils/asset_utils.dart';
import '../utils/format.dart';
import '../utils/video_utils.dart';
import '../widgets/noir/noir_widgets.dart';
import 'session.dart';

/// "Swipe" — every photo (or video), newest first, one card at a time
/// (REDESIGN_1.3_PLAN.md §5.3).
///
/// Swipe left / Delete marks the item; right / Keep moves on. Marks are
/// persisted immediately (a force-quit can't lose them) and deleted in ONE
/// system prompt when the user finishes. Undo walks back up to 50 decisions.
class SwipeScreen extends StatefulWidget {
  /// Newest first (sorted by the provider).
  final List<AssetEntity> photos;
  final int startIndex;
  final MediaKind kind;

  /// Started at the newest item (rather than "Continue from …"); see
  /// AppProvider.recordProgress.
  final bool fromNewest;

  const SwipeScreen({
    super.key,
    required this.photos,
    this.startIndex = 0,
    this.kind = MediaKind.photos,
    this.fromNewest = true,
  });

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _Decision {
  final int index;
  final bool deleted;
  const _Decision(this.index, this.deleted);
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  static const double _threshold = 100;
  static const int _maxHistory = 50;
  static const String _kHintSeen = 'swipe_hint_seen';

  late final AppProvider _provider;
  late final List<AssetEntity> _items = List.of(widget.photos);
  late int _current = widget.startIndex.clamp(0, widget.photos.length);

  bool get _isVideo => widget.kind == MediaKind.videos;
  CleanupMode get _mode =>
      _isVideo ? CleanupMode.videoSwipe : CleanupMode.photoSwipe;

  ResumePoint? get _here => _done
      ? null
      : ResumePoint(
          assetId: _items[_current].id,
          time: librarySortTime(_items[_current]));

  /// Save the position so the user can continue here next time — even after
  /// closing the app.
  void _record() {
    if (_items.isEmpty) return;
    unawaited(_provider.recordProgress(
      _mode,
      _here,
      fromNewest: widget.fromNewest,
      top: widget.fromNewest ? librarySortTime(_items.first) : null,
    ));
  }
  bool get _done => _current >= _items.length;

  /// Ids marked this session (also in the provider's persisted queue).
  final Set<String> _marked = {};
  final List<_Decision> _history = [];
  int _reviewed = 0;

  // ── Drag + fly animation ─────────────────────────────────────────────────
  Offset _drag = Offset.zero;
  bool _pastThreshold = false;
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Offset>? _flyAnim;
  bool _busy = false;
  bool _finishing = false;

  Offset get _offset => _flyAnim?.value ?? _drag;

  // ── First-run hint ───────────────────────────────────────────────────────
  bool _showHint = false;

  // ── In-deck native ad ────────────────────────────────────────────────────
  // Every [_adInterval] decisions an ad card is slipped in. Either button or
  // swipe direction just dismisses it — nothing is deleted, nothing counted,
  // and Undo skips it.
  int get _adInterval => _isVideo ? 5 : 12;
  NativeAd? _nativeAd;
  bool _nativeAdLoaded = false;
  bool _showingAd = false;
  int _sinceAd = 0;

  // ── Video ────────────────────────────────────────────────────────────────
  VideoPlayerController? _videoCtrl;
  String? _videoFor;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppProvider>();
    // Holds the background library re-scan back until we're done.
    _provider.inCleanupSession = true;
    _fly.addListener(() => setState(() {}));
    _loadHintFlag();
    if (_provider.adsEnabled) _maybeLoadNativeAd();
    _prepareVideo();
  }

  @override
  void dispose() {
    _provider.inCleanupSession = false;
    _fly.dispose();
    _nativeAd?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  Future<void> _loadHintFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kHintSeen) ?? false) && mounted) {
      setState(() => _showHint = true);
    }
  }

  Future<void> _hideHint() async {
    if (!_showHint) return;
    setState(() => _showHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHintSeen, true);
  }

  // ── Ads ──────────────────────────────────────────────────────────────────

  Future<void> _maybeLoadNativeAd() async {
    await AdService.instance.init();
    if (!mounted || !AdService.instance.canRequestAds) return;
    _loadNativeAd();
  }

  void _loadNativeAd() {
    if (!AdService.instance.canRequestAds || _provider.isPro) return;
    final unitId = AdService.nativeUnitId;
    final ad = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Noir.surface,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Noir.onAccent,
          backgroundColor: Noir.accentStrong,
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Noir.text,
          style: NativeTemplateFontStyle.bold,
          size: 17,
        ),
        secondaryTextStyle:
            NativeTemplateTextStyle(textColor: Noir.muted, size: 15),
        tertiaryTextStyle:
            NativeTemplateTextStyle(textColor: Noir.muted, size: 14),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          debugPrint('[Ads] native loaded ($unitId)');
          if (mounted) setState(() => _nativeAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] native failed ($unitId): $error');
          ad.dispose();
          _nativeAd = null;
          _nativeAdLoaded = false;
        },
      ),
    );
    _nativeAd = ad;
    ad.load();
  }

  void _dismissAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _nativeAdLoaded = false;
    _showingAd = false;
    _loadNativeAd();
  }

  // ── Video ────────────────────────────────────────────────────────────────

  Future<void> _prepareVideo() async {
    if (!_isVideo) return;
    final target = (_done || _showingAd) ? null : _items[_current];
    if (target?.id == _videoFor) return;
    final old = _videoCtrl;
    _videoCtrl = null;
    _videoReady = false;
    _videoFor = target?.id;
    await old?.dispose();
    if (target == null) return;
    try {
      final ctrl = await buildAssetVideoController(target);
      if (ctrl == null) return;
      if (!mounted || _videoFor != target.id) {
        await ctrl.dispose();
        return;
      }
      _videoCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(1.0);
      if (mounted && _videoFor == target.id) {
        setState(() => _videoReady = true);
      }
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  void _play() => _videoCtrl?.play().then((_) {
        if (mounted) setState(() {});
      });

  void _pause() {
    _videoCtrl?.pause();
    if (mounted) setState(() {});
  }

  // ── Decisions ────────────────────────────────────────────────────────────

  Future<void> _animate(Offset from, Offset to) async {
    if (_reduceMotion) return;
    _flyAnim = Tween(begin: from, end: to)
        .animate(CurvedAnimation(parent: _fly, curve: Curves.easeOutCubic));
    await _fly.forward(from: 0);
    _flyAnim = null;
  }

  Future<void> _decide({required bool delete}) async {
    if (_busy || _done || _finishing) return;
    _busy = true;
    final width = MediaQuery.sizeOf(context).width;
    final out = Offset((delete ? -1.4 : 1.4) * width, _drag.dy + 40);

    if (_showingAd) {
      await _animate(_drag, out);
      if (!mounted) return;
      setState(() {
        _dismissAd();
        _drag = Offset.zero;
        _pastThreshold = false;
      });
      _busy = false;
      _prepareVideo();
      return;
    }

    FeedbackService.instance.play(delete ? Fx.delete : Fx.keep);
    _hideHint();
    _pause();
    await _animate(_drag, out);
    if (!mounted) return;

    final asset = _items[_current];
    if (delete) {
      _marked.add(asset.id);
      // Persist the mark right away so a force-quit can't lose it; Home
      // offers to finish the job next launch. Fire-and-forget keeps the swipe
      // instant (the in-memory queue updates synchronously).
      unawaited(_provider.queueForDeletion([asset], notify: false));
    }
    _history.add(_Decision(_current, delete));
    if (_history.length > _maxHistory) _history.removeAt(0);

    setState(() {
      _current++;
      _reviewed++;
      _drag = Offset.zero;
      _pastThreshold = false;
      _sinceAd++;
      if (!_done && _sinceAd >= _adInterval && _nativeAdLoaded) {
        _showingAd = true;
        _sinceAd = 0;
      }
    });
    _busy = false;
    _record();
    _prepareVideo();
    if (_done) _finish();
  }

  Future<void> _undo() async {
    if (_busy || _history.isEmpty || _finishing) return;
    _busy = true;
    final d = _history.removeLast();
    final asset = _items[d.index];
    FeedbackService.instance.play(Fx.undo);
    if (d.deleted) {
      _marked.remove(asset.id);
      unawaited(_provider.unqueueDeletion([asset], notify: false));
    }
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      // An ad card on screen is simply dropped — ads are never undone.
      if (_showingAd) _showingAd = false;
      _current = d.index;
      _reviewed = (_reviewed - 1).clamp(0, _reviewed);
      _drag = Offset.zero;
      _pastThreshold = false;
    });
    _record();
    _prepareVideo();
    // Slide the card back in from the side it left.
    await _animate(Offset((d.deleted ? -1.4 : 1.4) * width, 40), Offset.zero);
    _busy = false;
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _pause();
    final resume = _here;
    await finishSession(context,
        provider: _provider, kind: widget.kind, resume: resume);
    // Still here (e.g. the route wasn't replaced) — allow another try.
    if (mounted) _finishing = false;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_busy) return;
    setState(() => _drag += d.delta);
    final past = _drag.dx.abs() > _threshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      FeedbackService.instance.play(Fx.detent);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_busy) return;
    if (_drag.dx < -_threshold) {
      _decide(delete: true);
    } else if (_drag.dx > _threshold) {
      _decide(delete: false);
    } else {
      // Snap back.
      final from = _drag;
      setState(() {
        _drag = Offset.zero;
        _pastThreshold = false;
      });
      _animate(from, Offset.zero);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);
    final lang = provider.languageCode;
    final avg = _isVideo ? kAvgVideoBytes : provider.avgPhotoBytes;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: Noir.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                NoirHeader(
                  leading: NoirIconButton(
                    icon: Icons.close_rounded,
                    semanticLabel: s.finish,
                    onPressed: _finish,
                  ),
                  title: s.swipe,
                  subtitle: s.reviewed(formatCount(_reviewed, lang)),
                  trailing: NoirIconButton(
                    icon: Icons.undo_rounded,
                    semanticLabel: s.undo,
                    onPressed: _history.isEmpty ? null : _undo,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _marked.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: PendingPill(
                    text: s.markedPending(formatCount(_marked.length, lang),
                        formatBytes(_marked.length * avg, lang)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _done ? const SizedBox.shrink() : _buildStack(s),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: NoirButton.danger(
                        big: true,
                        icon: Icons.delete_outline_rounded,
                        label: s.swipeDelete,
                        onPressed: _done ? null : () => _decide(delete: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NoirButton.secondary(
                        big: true,
                        icon: Icons.check_rounded,
                        label: s.swipeKeep,
                        onPressed: _done ? null : () => _decide(delete: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isVideo ? s.confirmOnceNoteVideos : s.confirmOnceNote,
                  textAlign: TextAlign.center,
                  style: NoirText.caption.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStack(AppStrings s) {
    final showAd = _showingAd && _nativeAd != null;
    // How far the drag (or fly-out) has gone, 0–1, to bring the next card
    // forward as the current one leaves.
    final t = (_offset.dx.abs() / (_threshold * 1.5)).clamp(0.0, 1.0);
    final AssetEntity? behind = showAd
        ? _items[_current]
        : (_current + 1 < _items.length ? _items[_current + 1] : null);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (behind != null)
            Opacity(
              opacity: 0.5 + 0.5 * t,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - t)),
                child: Transform.scale(
                  scale: 0.95 + 0.05 * t,
                  child: _cardFrame(_mediaCard(behind, s, front: false)),
                ),
              ),
            ),
          Transform.translate(
            offset: _offset,
            child: Transform.rotate(
              angle: _offset.dx / 2400,
              child: _cardFrame(
                showAd ? _adCard(s) : _mediaCard(_items[_current], s, front: true),
                shadow: true,
              ),
            ),
          ),
          if (_showHint && !showAd) _hintOverlay(s),
        ],
      ),
    );
  }

  Widget _cardFrame(Widget child, {bool shadow = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Noir.rPhoto),
        color: Noir.surface,
        boxShadow: shadow
            ? const [
                BoxShadow(
                    color: Color(0x47000000),
                    blurRadius: 40,
                    offset: Offset(0, 18)),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _mediaCard(AssetEntity asset, AppStrings s, {required bool front}) {
    final dx = front ? _offset.dx : 0.0;
    final deleteOpacity = dx < 0 ? (-dx / 120).clamp(0.0, 1.0) : 0.0;
    final keepOpacity = dx > 0 ? (dx / 120).clamp(0.0, 1.0) : 0.0;
    final playing = front &&
        _isVideo &&
        _videoReady &&
        _videoFor == asset.id &&
        _videoCtrl != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (playing)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoCtrl!.value.size.width,
              height: _videoCtrl!.value.size.height,
              child: VideoPlayer(_videoCtrl!),
            ),
          )
        else
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(800, 1200),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Noir.surface2,
              child: Icon(
                  _isVideo
                      ? Icons.movie_outlined
                      : Icons.broken_image_outlined,
                  color: Noir.faint,
                  size: 56),
            ),
          ),
        if (deleteOpacity > 0)
          _decisionOverlay(s.swipeDelete.toUpperCase(), Noir.danger,
              deleteOpacity, Alignment.topRight, 0.25),
        if (keepOpacity > 0)
          _decisionOverlay(s.swipeKeep.toUpperCase(), Noir.success, keepOpacity,
              Alignment.topLeft, -0.25),
        // Date chip, bottom-left.
        Positioned(
          left: 14,
          bottom: 14,
          child: _chip(s.shortDate(librarySortTime(asset))),
        ),
        if (_isVideo) ...[
          Positioned(
            top: 14,
            right: 14,
            child: _chip(formatVideoDuration(asset.videoDuration),
                icon: Icons.videocam_rounded),
          ),
          if (front)
            Positioned(
              right: 14,
              bottom: 10,
              child: _holdToPlay(s),
            ),
        ],
      ],
    );
  }

  Widget _chip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: const TextStyle(
                  fontFamily: NoirText.family,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _holdToPlay(AppStrings s) {
    final playing = _videoCtrl?.value.isPlaying ?? false;
    return GestureDetector(
      onTapDown: (_) => _play(),
      onTapUp: (_) => _pause(),
      onTapCancel: _pause,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const ShapeDecoration(
          color: Noir.accentStrong,
          shape: StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Noir.onAccent, size: 20),
            const SizedBox(width: 6),
            Text(playing ? s.playing : s.holdToPlay,
                style: const TextStyle(
                    fontFamily: NoirText.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Noir.onAccent)),
          ],
        ),
      ),
    );
  }

  Widget _decisionOverlay(String label, Color color, double opacity,
      Alignment align, double angle) {
    return Container(
      color: color.withValues(alpha: opacity * 0.3),
      alignment: align,
      padding: const EdgeInsets.all(28),
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                style: TextStyle(
                    fontFamily: NoirText.family,
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _hintOverlay(AppStrings s) {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: ShapeDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swipe_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(s.swipeFirstHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: NoirText.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The native ad as a card, clearly marked as sponsored.
  Widget _adCard(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const ShapeDecoration(
                color: Noir.surface2,
                shape: StadiumBorder(),
              ),
              child: Text(s.sponsored, style: NoirText.caption),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minWidth: 280, minHeight: 320, maxHeight: 400),
                child: AdWidget(ad: _nativeAd!),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(s.adSwipeHint,
              textAlign: TextAlign.center, style: NoirText.secondary),
        ],
      ),
    );
  }
}
