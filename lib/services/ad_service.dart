import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin wrapper around Google Mobile Ads.
///
/// Uses Google's official **test** ad unit IDs. Before publishing, replace
/// [_androidBanner]/[_iosBanner]/[_androidInterstitial]/[_iosInterstitial] with
/// your real unit IDs from the AdMob console, and replace the App IDs in
/// AndroidManifest.xml and ios/Runner/Info.plist.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;

  // ── Test unit IDs (safe to ship while developing) ──────────────────────────
  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerUnitId =>
      Platform.isIOS ? _iosBanner : _androidBanner;
  static String get interstitialUnitId =>
      Platform.isIOS ? _iosInterstitial : _androidInterstitial;

  /// Initialize the SDK and pre-load an interstitial. Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Show a full-screen ad if one is ready, then pre-load the next.
  /// No-op if the SDK isn't initialized or no ad is loaded yet.
  void showInterstitial() {
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }
}
