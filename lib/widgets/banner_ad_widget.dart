import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Adaptive bottom banner. Renders nothing until an ad loads.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  StreamSubscription<void>? _readySub;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _readySub = AdService.instance.onAdsReadyChanged.listen((_) {
      if (mounted && !_loaded) _maybeLoad();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
  }

  Future<void> _maybeLoad() async {
    await AdService.instance.init();
    if (!mounted) return;
    if (!AdService.instance.canRequestAds) {
      debugPrint('[Ads] banner skipped — canRequestAds=false');
      return;
    }
    if (_loaded || _ad != null) return;
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    _loadAttempts++;
    final unitId = AdService.bannerUnitId;

    AdSize size = AdSize.banner;
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (adaptive != null) size = adaptive;
    } catch (_) {}

    final banner = BannerAd(
      size: size,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('[Ads] banner loaded ($unitId)');
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] banner failed ($unitId): $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
          // Retry once — new units / cold start often fail the first request.
          if (_loadAttempts < 2) {
            Future<void>.delayed(const Duration(seconds: 4), () {
              if (mounted && !_loaded) _load();
            });
          }
        },
      ),
    );
    _ad = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _readySub?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
