import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../l10n/strings.dart';

/// Distinct accent for the video-cleanup mode.
const Color kVideoAccent = Color(0xFF16BFA6);

/// Insert a native ad card after every this-many videos.
const int _adEvery = 5;

enum _ItemType { video, ad }

class _DeckItem {
  final _ItemType type;
  final AssetEntity? asset;
  const _DeckItem.video(this.asset) : type = _ItemType.video;
  const _DeckItem.ad()
      : type = _ItemType.ad,
        asset = null;
}

class VideoSwipeScreen extends StatefulWidget {
  final List<AssetEntity> videos;
  const VideoSwipeScreen({super.key, required this.videos});

  @override
  State<VideoSwipeScreen> createState() => _VideoSwipeScreenState();
}

class _VideoSwipeScreenState extends State<VideoSwipeScreen> {
  late final List<_DeckItem> _deck;
  late final AppProvider _provider;
  int _current = 0;

  double _dragX = 0;
  double _dragY = 0;

  final List<AssetEntity> _pendingDelete = [];
  int _deletedCount = 0;
  int _freedBytes = 0;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  NativeAd? _nativeAd;
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppProvider>();

    // Build the deck: video, video, video, video, [ad], video, ...
    // Only interleave ads for non-Pro users when ads may be served.
    final showAds = !_provider.isPro && AdService.instance.canRequestAds;
    _deck = [];
    int since = 0;
    for (final v in widget.videos) {
      _deck.add(_DeckItem.video(v));
      since++;
      if (showAds && since == _adEvery) {
        _deck.add(const _DeckItem.ad());
        since = 0;
      }
    }
    _prepareCurrent();
  }

  @override
  void dispose() {
    _commitDeletions();
    _videoCtrl?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  bool get _done => _current >= _deck.length;

  void _prepareCurrent() {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    _adReady = false;

    if (_done) return;
    final item = _deck[_current];
    if (item.type == _ItemType.video) {
      _loadVideo(item.asset!);
    } else {
      _loadAd();
    }
  }

  Future<void> _loadVideo(AssetEntity asset) async {
    try {
      final url = await asset.getMediaUrl();
      if (url == null || !mounted) return;
      final ctrl = VideoPlayerController.contentUri(Uri.parse(url));
      _videoCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(1.0); // play with sound
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  void _loadAd() {
    if (!AdService.instance.canRequestAds) return;
    final ad = NativeAd(
      adUnitId: AdService.nativeUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adReady = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _adReady = false);
        },
      ),
    );
    _nativeAd = ad;
    ad.load();
  }

  Future<void> _commitDeletions() async {
    if (_pendingDelete.isEmpty) return;
    final batch = List<AssetEntity>.from(_pendingDelete);
    _pendingDelete.clear();
    await _provider.deleteAssets(batch);
  }

  void _advance() {
    setState(() {
      _current++;
      _dragX = 0;
      _dragY = 0;
    });
    _prepareCurrent();
    if (_done) _commitDeletions();
  }

  void _deleteCurrent() {
    final item = _deck[_current];
    if (item.type == _ItemType.video) {
      _pendingDelete.add(item.asset!);
      _deletedCount++;
      _freedBytes += kAvgVideoBytes;
      final s = AppStrings.of(_provider.languageCode);
      CelebrationOverlay.of(context)
          ?.celebrate(s.deleted(1, _formatBytes(kAvgVideoBytes)));
    }
    _advance();
  }

  void _onDragEnd(DragEndDetails d) {
    const threshold = 100.0;
    if (_dragX < -threshold) {
      _deleteCurrent(); // left = delete (ads just advance)
    } else if (_dragX > threshold) {
      _advance(); // right = keep / skip
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    return CelebrationOverlay(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(s.videoMode,
              style: const TextStyle(color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_remainingVideos()} ${s.remaining}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        body: _done ? _buildDone(context, s) : _buildDeck(context, s),
      ),
    );
  }

  int _remainingVideos() =>
      _deck.skip(_current).where((i) => i.type == _ItemType.video).length;

  Widget _buildDeck(BuildContext context, AppStrings s) {
    final item = _deck[_current];
    final deleteOpacity =
        (_dragX < 0 ? (-_dragX / 120).clamp(0.0, 1.0) : 0.0);
    final keepOpacity = (_dragX > 0 ? (_dragX / 120).clamp(0.0, 1.0) : 0.0);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() {
              _dragX += d.delta.dx;
              _dragY += d.delta.dy;
            }),
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(_dragX, _dragY)
                    ..rotateZ(_dragX / 2000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: item.type == _ItemType.video
                        ? _buildVideoCard(item.asset!, deleteOpacity, keepOpacity)
                        : _buildAdCard(),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(context, s, item.type == _ItemType.ad),
      ],
    );
  }

  Widget _buildVideoCard(
      AssetEntity asset, double deleteOpacity, double keepOpacity) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video (once ready) or the thumbnail poster while it loads.
          if (_videoReady && _videoCtrl != null)
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
              thumbnailSize: const ThumbnailSize(600, 900),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade900,
                child: const Icon(Icons.movie_outlined,
                    color: Colors.grey, size: 64),
              ),
            ),

          if (deleteOpacity > 0)
            _decisionOverlay('DELETE', AppTheme.danger, deleteOpacity,
                Alignment.topLeft, -0.3),
          if (keepOpacity > 0)
            _decisionOverlay('KEEP', AppTheme.success, keepOpacity,
                Alignment.topRight, 0.3),

          // Duration badge (top-right)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(_formatDuration(asset.videoDuration),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Hold-to-play button (bottom center)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildHoldButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldButton() {
    final playing = _videoCtrl?.value.isPlaying ?? false;
    return GestureDetector(
      onTapDown: (_) => _videoCtrl?.play().then((_) {
        if (mounted) setState(() {});
      }),
      onTapUp: (_) => _pauseVideo(),
      onTapCancel: _pauseVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: kVideoAccent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kVideoAccent.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(playing ? Icons.pause : Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(playing ? 'Playing…' : 'Hold to play',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _pauseVideo() {
    _videoCtrl?.pause();
    if (mounted) setState(() {});
  }

  Widget _decisionOverlay(String label, Color color, double opacity,
      Alignment align, double angle) {
    return Container(
      color: color.withOpacity(opacity * 0.6),
      alignment: align,
      padding: const EdgeInsets.all(28),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildAdCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (_adReady && _nativeAd != null)
          ? SizedBox(
              width: double.infinity,
              height: 360,
              child: AdWidget(ad: _nativeAd!),
            )
          : const CircularProgressIndicator(color: kVideoAccent),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppStrings s, bool isAd) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
      color: Colors.black,
      child: Column(
        children: [
          Text(
            isAd ? s.swipeAnyToContinue : s.swipeHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            s.recoverHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(
                icon: Icons.delete_outline,
                color: AppTheme.danger,
                onTap: isAd ? _advance : _deleteCurrent,
              ),
              Column(
                children: [
                  Text('$_deletedCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  Text(s.deleted_noun,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
              _actionBtn(
                icon: Icons.check_circle_outline,
                color: AppTheme.success,
                onTap: _advance,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildDone(BuildContext context, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text(s.swipeDone,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              s.deleted(_deletedCount, _formatBytes(_freedBytes)),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kVideoAccent),
              child: Text(s.backHome),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
