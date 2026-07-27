import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _prodBannerAndroid =
      'ca-app-pub-2265053267835785/7932661645';
  static const String _prodBannerIos = 'ca-app-pub-6387001035314883/4462266400';

  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _prodInterstitialAndroid =
      'ca-app-pub-2265053267835785/7740864619';
  static const String _prodInterstitialIos =
      'ca-app-pub-6387001035314883/4814308550';

  static const bool _isTest = false;

  bool _mobileAdsStarted = false;
  bool _consentUpdateStarted = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get bannerAdUnitId {
    if (!isSupported) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _isTest ? _testBannerAndroid : _prodBannerAndroid;
    }
    return _isTest ? _testBannerIos : _prodBannerIos;
  }

  String get interstitialAdUnitId {
    if (!isSupported) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _isTest ? _testInterstitialAndroid : _prodInterstitialAndroid;
    }
    return _isTest ? _testInterstitialIos : _prodInterstitialIos;
  }

  Future<void> initialize() async {
    if (!isSupported || _consentUpdateStarted) return;
    _consentUpdateStarted = true;

    final parameters = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      parameters,
      () async {
        await _refreshPrivacyOptionsRequirement();
        await _startAdsIfAllowed();

        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            debugPrint(
              'Gizlilik formu gösterilemedi: '
              '${formError.errorCode} ${formError.message}',
            );
          }
          await _refreshPrivacyOptionsRequirement();
          await _startAdsIfAllowed();
        });
      },
      (formError) async {
        debugPrint(
          'Gizlilik bilgisi alınamadı: '
          '${formError.errorCode} ${formError.message}',
        );
        await _refreshPrivacyOptionsRequirement();
        await _startAdsIfAllowed();
      },
    );
  }

  Future<void> _startAdsIfAllowed() async {
    if (_mobileAdsStarted ||
        !await ConsentInformation.instance.canRequestAds()) {
      return;
    }

    _mobileAdsStarted = true;
    await MobileAds.instance.initialize();
    if (_isTest) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: const ['EMULATOR']),
      );
    }
    adsReady.value = true;
    loadInterstitialAd();
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    privacyOptionsRequired.value = await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<FormError?> showPrivacyOptionsForm() {
    final completer = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm((formError) async {
      if (formError != null) {
        debugPrint(
          'Gizlilik seçenekleri gösterilemedi: '
          '${formError.errorCode} ${formError.message}',
        );
      }
      await _refreshPrivacyOptionsRequirement();
      await _startAdsIfAllowed();
      completer.complete(formError);
    });
    return completer.future;
  }

  void loadInterstitialAd() {
    if (!isSupported ||
        !adsReady.value ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('Geçiş reklamı yüklendi.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('Geçiş reklamı yüklenemedi: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (!isSupported || !adsReady.value || _interstitialAd == null) {
      onAdDismissed?.call();
      loadInterstitialAd();
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.setImmersiveMode(true);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        onAdDismissed?.call();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('Geçiş reklamı gösterilemedi: $error');
        shownAd.dispose();
        onAdDismissed?.call();
        loadInterstitialAd();
      },
    );

    await ad.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    adsReady.dispose();
    privacyOptionsRequired.dispose();
  }
}
