import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// A single, labeled native ad in the scrollable Explore feed.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.adsReady.addListener(_onAdsReady);
    _onAdsReady();
  }

  void _onAdsReady() {
    if (!mounted ||
        !AdService.instance.adsReady.value ||
        _loading ||
        _ad != null) {
      return;
    }
    final adUnitId = AdService.instance.nativeAdUnitId;
    if (adUnitId.isEmpty) return;
    _loading = true;
    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle:
          NativeTemplateStyle(templateType: TemplateType.small),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _ad = loadedAd as NativeAd;
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('Yerel reklam yüklenemedi: $error');
          failedAd.dispose();
          _loading = false;
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    AdService.instance.adsReady.removeListener(_onAdsReady);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reklam', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          SizedBox(
              height: 100, width: double.infinity, child: AdWidget(ad: _ad!)),
        ],
      ),
    );
  }
}
