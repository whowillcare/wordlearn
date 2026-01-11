import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdController {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // TODO: Replace with your actual Ad Unit IDs
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Android Test ID for Rewarded Video
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID

  void loadAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadAd(); // Preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isAdLoaded = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showAd({required Function(int amount) onUserEarnedReward}) {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Default to 50 if reward.amount is not reliable or small
          // Google Test Ads return 10
          // logic can override this.
          onUserEarnedReward(50);
        },
      );
      _rewardedAd = null;
      _isAdLoaded = false;
    } else {
      print('Rewarded ad is not yet loaded.');
      // Optionally try to load one now
      loadAd();
    }
  }

  bool get isLoaded => _isAdLoaded;

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
