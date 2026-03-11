import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class AdSenseBanner extends StatefulWidget {
  final String adClient;
  final String adSlot;

  const AdSenseBanner({
    super.key,
    required this.adClient,
    required this.adSlot,
  });

  @override
  State<AdSenseBanner> createState() => _AdSenseBannerState();
}

class _AdSenseBannerState extends State<AdSenseBanner> {
  @override
  void initState() {
    super.initState();
    // Load AdSense ad after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  void _loadAd() {
    try {
      // Create container div for the ad
      final containerId = 'adsense-banner-${widget.adSlot}';
      var container = web.document.getElementById(containerId);

      if (container == null) {
        container = web.document.createElement('div');
        container.id = containerId;
        (container as dynamic).style.display = 'flex';
        (container as dynamic).style.justifyContent = 'center';
        (container as dynamic).style.alignItems = 'center';
        (container as dynamic).style.width = '320px';
        (container as dynamic).style.height = '50px';

        web.document.body?.appendChild(container);
      }

      // Create ins element for AdSense
      final ins = web.document.createElement('ins');
      ins.className = 'adsbygoogle';
      (ins as dynamic).style.display = 'block';
      (ins as dynamic).style.width = '320px';
      (ins as dynamic).style.height = '50px';
      ins.setAttribute('data-ad-client', widget.adClient);
      ins.setAttribute('data-ad-slot', widget.adSlot);
      ins.setAttribute('data-ad-format', 'horizontal');

      container.appendChild(ins);

      // Trigger ad load
      final adsbygoogle = web.window['adsbygoogle'];
      (adsbygoogle as dynamic).push([ins]);
    } catch (e) {
      // Silently fail - ads may not load in all environments
    }
  }

  @override
  Widget build(BuildContext context) {
    // This SizedBox reserves space for the ad
    // The actual DOM element is inserted separately
    return const SizedBox(
      height: 50,
      width: 320,
    );
  }
}
