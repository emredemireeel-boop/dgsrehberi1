import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.adsReady.addListener(_onAdsReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AdService.instance.adsReady.value && _bannerAd == null) {
      _loadAd();
    }
  }

  void _onAdsReady() {
    if (mounted && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (!AdService.instance.isSupported ||
        !AdService.instance.adsReady.value ||
        _isLoading ||
        _bannerAd != null) {
      return;
    }

    _isLoading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width,
    );
    final size = adaptiveSize ?? AdSize.banner;

    final ad = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: size,
      request: AdRequest(
        nonPersonalizedAds: defaultTargetPlatform == TargetPlatform.iOS,
      ),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _bannerAd = loadedAd as BannerAd;
            _adSize = size;
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('Banner reklam yüklenemedi: $error');
          failedAd.dispose();
          _isLoading = false;
        },
      ),
    );
    await ad.load();
  }

  @override
  void dispose() {
    AdService.instance.adsReady.removeListener(_onAdsReady);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Center(
        child: SizedBox(
          width: _adSize!.width.toDouble(),
          height: _adSize!.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
