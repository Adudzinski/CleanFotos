import 'dart:async';
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

  Future<void>? _initFuture;
  InterstitialAd? _interstitial;

  /// Whether we're allowed to request ads at all. False until consent has been
  /// gathered; in the EEA it stays false if the user declines. Outside the EEA
  /// it becomes true automatically (no form shown).
  bool _canRequestAds = false;
  bool get canRequestAds => _canRequestAds;

  /// Whether a "Privacy options" entry point must be offered so EEA users can
  /// change their ad-consent choices later. Drives the Settings row.
  bool _privacyOptionsRequired = false;
  bool get isPrivacyOptionsRequired => _privacyOptionsRequired;

  /// Completes once consent has been resolved and the SDK initialized. Widgets
  /// (e.g. the banner) await this before trying to load an ad.
  Future<void> get ready => _initFuture ?? Future<void>.value();

  // Frequency cap: show an interstitial at most once per this interval.
  static const Duration _interstitialCooldown = Duration(minutes: 4);
  DateTime? _lastInterstitial;

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

  /// Gather consent (UMP), initialize the SDK, and pre-load an interstitial.
  /// Idempotent — safe to call more than once (runs at most once).
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    await _gatherConsent();
    await MobileAds.instance.initialize();
    // Start the cooldown now so the user gets an ad-free first few minutes.
    _lastInterstitial = DateTime.now();
    if (_canRequestAds) _loadInterstitial();
  }

  /// Run Google's User Messaging Platform flow: request the latest consent
  /// info, and if a form is required (EEA/UK), load and show it. Outside the
  /// EEA this is a no-op and [canRequestAds] simply becomes true.
  Future<void> _gatherConsent() async {
    final params = ConsentRequestParameters(
      // In debug you can force the EEA experience to test the form by adding
      // your device's test id below (printed in logcat on first run):
      //   consentDebugSettings: ConsentDebugSettings(
      //     debugGeography: DebugGeography.debugGeographyEea,
      //     testIdentifiers: ['YOUR_TEST_DEVICE_ID'],
      //   ),
    );

    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        // Shows the form only if required; fires the callback immediately if
        // not. Either way we then know whether ads can be requested.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Never block app start indefinitely on a slow network.
    await completer.future
        .timeout(const Duration(seconds: 12), onTimeout: () {});

    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      // If the consent check fails, fall back to requesting (non-personalized)
      // ads so the app still earns outside regulated regions.
      _canRequestAds = true;
    }
  }

  /// Re-open the consent form so the user can change their choices. Call this
  /// from a "Privacy options" entry in Settings (only when
  /// [isPrivacyOptionsRequired] is true).
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {}
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

  /// Show a full-screen ad if one is ready AND the cooldown has elapsed, then
  /// pre-load the next. No-op if not ready or shown too recently.
  void showInterstitial() {
    if (!_canRequestAds) return;
    final last = _lastInterstitial;
    if (last != null &&
        DateTime.now().difference(last) < _interstitialCooldown) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) return;
    _lastInterstitial = DateTime.now();
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
