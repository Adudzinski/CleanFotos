import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin wrapper around Google Mobile Ads + UMP consent.
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

  /// Bumps whenever consent / ad-readiness changes so UI (banner) can reload.
  final StreamController<void> _adsReadyChanges =
      StreamController<void>.broadcast();
  Stream<void> get onAdsReadyChanged => _adsReadyChanges.stream;

  /// Completes once consent has been resolved and the SDK initialized.
  Future<void> get ready => _initFuture ?? Future<void>.value();

  // Frequency cap: show an interstitial at most once per this interval.
  static const Duration _interstitialCooldown = Duration(minutes: 4);
  DateTime? _lastInterstitial;

  // ── Real (production) unit IDs from the AdMob console ───────────────────────
  // Android — do not change; shared codebase with iOS.
  static const _androidBannerProd = 'ca-app-pub-6352577985769083/7886470703';
  static const _androidInterstitialProd = 'ca-app-pub-6352577985769083/8312856434';
  static const _androidNativeProd = 'ca-app-pub-6352577985769083/9710342782';
  // iOS
  static const _iosBannerProd = 'ca-app-pub-6352577985769083/2715012417';
  static const _iosInterstitialProd =
      'ca-app-pub-6352577985769083/1457650921';
  static const _iosNativeProd = 'ca-app-pub-6352577985769083/5587899409';

  // ── Google test unit IDs (used in debug builds) ─────────────────────────────
  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';
  static const _androidNativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosNativeTest = 'ca-app-pub-3940256099942544/3986624511';

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

  static String get nativeUnitId => Platform.isIOS
      ? _pick(_iosNativeProd, _iosNativeTest)
      : _pick(_androidNativeProd, _androidNativeTest);

  /// Gather consent (UMP), initialize the SDK, and pre-load an interstitial.
  /// Idempotent — safe to call more than once (runs at most once).
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    await _gatherConsent();
    await MobileAds.instance.initialize();
    debugPrint(
      '[Ads] init done — canRequestAds=$_canRequestAds '
      'privacyOptions=$_privacyOptionsRequired '
      'banner=$bannerUnitId debug=$kDebugMode',
    );
    if (_canRequestAds) {
      _loadInterstitial();
    } else {
      debugPrint(
        '[Ads] No ads until consent allows it. '
        'AdMob → Privacy & messaging → publish GDPR for the iOS CleanFotos app, '
        'then accept the in-app consent form (or Settings → Ad privacy options).',
      );
    }
    if (!_adsReadyChanges.isClosed) _adsReadyChanges.add(null);
  }

  Future<void> _gatherConsent() async {
    final params = ConsentRequestParameters();

    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) {
            debugPrint('[Ads] consent form error: ${error.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        debugPrint('[Ads] consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future
        .timeout(const Duration(seconds: 12), onTimeout: () {
      debugPrint('[Ads] consent timed out after 12s');
    });

    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
      final consentStatus =
          await ConsentInformation.instance.getConsentStatus();
      debugPrint(
        '[Ads] consentStatus=$consentStatus '
        'canRequestAds=$_canRequestAds '
        'privacyOptionsRequired=$_privacyOptionsRequired',
      );
    } catch (e) {
      debugPrint('[Ads] consent check failed ($e) — allowing non-personalized ads');
      _canRequestAds = true;
    }
  }

  /// Re-open the consent form so the user can change their choices.
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('[Ads] privacy options error: ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    try {
      final before = _canRequestAds;
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      debugPrint('[Ads] after privacy options canRequestAds=$_canRequestAds');
      if (_canRequestAds && !before) _loadInterstitial();
      if (!_adsReadyChanges.isClosed) _adsReadyChanges.add(null);
    } catch (_) {}
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[Ads] interstitial loaded');
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ads] interstitial failed: $error');
          _interstitial = null;
        },
      ),
    );
  }

  /// Show a full-screen ad if one is ready AND the cooldown has elapsed.
  bool showInterstitial() {
    if (!_canRequestAds) return false;
    final last = _lastInterstitial;
    if (last != null &&
        DateTime.now().difference(last) < _interstitialCooldown) {
      return false;
    }
    final ad = _interstitial;
    if (ad == null) return false;
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
    return true;
  }
}
