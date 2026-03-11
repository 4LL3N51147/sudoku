import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'adsense_banner.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    // Load AdMob ads on mobile only
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _ad!.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Show AdSense on web (using test ad unit)
      return const AdSenseBanner(
        adClient: 'ca-pub-3940256099942544',
        adSlot: '6300978111',
      );
    }
    return SizedBox(
      height: 50,
      child: _ad != null ? AdWidget(ad: _ad!) : const SizedBox(),
    );
  }
}
