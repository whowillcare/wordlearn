import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdController {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // TODO: Replace with your actual Ad Unit IDs
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android Test ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID

  void loadAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              // Optionally reload here if you want to chain them,
              // but for GameScreen usually one per session is enough or reload next time.
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isAdLoaded = false;
        },
      ),
    );
  }

  static int _attempts = 0;

  void showAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _attempts++;
      // Show ad every 3rd attempt
      if (_attempts % 3 == 0) {
        _interstitialAd!.show();
        _interstitialAd = null;
        _isAdLoaded = false;
        // Preload next
        loadAd();
      } else {
        print('Interstitial ad skipped (Capping: $_attempts)');
        // Check if we need to reload? No, keep it for next time.
      }
    } else {
      print('Interstitial ad is not yet loaded.');
      loadAd(); // Try ensuring it loads for next time
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
