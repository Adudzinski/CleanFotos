import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
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

  // ── Real (production) unit IDs from the AdMob console ───────────────────────
  // Leave a value empty until that unit is created → it falls back to a test ID.
  static const _androidBannerProd = 'ca-app-pub-6352577985769083/7886470703';
  static const _androidInterstitialProd = 'ca-app-pub-6352577985769083/8312856434';
  static const _iosBannerProd = ''; // TODO: create iOS app + units
  static const _iosInterstitialProd = '';

  // ── Google test unit IDs (used in debug builds, or until prod IDs exist) ────
  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';

  /// Returns the prod ID in release builds (if set), otherwise the test ID.
  /// Debug builds always use test ads to protect the account from self-clicks.
  static String _pick(String prod, String test) =>
      (!kDebugMode && prod.isNotEmpty) ? prod : test;

  static String get bannerUnitId => Platform.isIOS
      ? _pick(_iosBannerProd, _iosBannerTest)
      : _pick(_androidBannerProd, _androidBannerTest);

  static String get interstitialUnitId => Platform.isIOS
      ? _pick(_iosInterstitialProd, _iosInterstitialTest)
      : _pick(_androidInterstitialProd, _androidInterstitialTest);

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
