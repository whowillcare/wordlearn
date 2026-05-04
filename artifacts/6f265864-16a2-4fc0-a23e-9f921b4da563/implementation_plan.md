# Resolve Google Sign-In Null Token Error

## Goal Description
The Google Sign-In process fails with a "null token error", meaning `googleAuth.idToken` is null. This typically occurs because the Web Client ID is not properly configured in the app, or the SHA-1 fingerprint is missing from the Firebase Console, preventing Google Play Services from issuing an ID token.

## Analysis of Previous Plans
Based on our review of the artifacts:
- `e1cae38c` successfully fixed the `SecurityException` by updating the `<queries>` in the Android Manifest.
- `edeb2a90` and `d500c597` successfully implemented and debugged the `CloudSyncService` permission issues for "learnt words".
- The "Database Population" from JSON files (`2db7a0cd`) was superseded by a bundled `dictionary.db` which is fully implemented in `database_helper.dart`.
Therefore, resolving this Google Sign-In null token error is the final remaining Immediate Bug.

## Proposed Changes

### 1. Configuration & Dependencies
#### [MODIFY] `lib/data/auth_repository.dart`
- Update the `GoogleSignIn` initialization to explicitly include the `serverClientId` (the Web Client ID from your Firebase project). This explicitly requests an ID token.
```dart
      _googleSignIn = googleSignIn ?? gsi.GoogleSignIn(
        scopes: ['email'],
        // TODO: Replace with the actual Web Client ID from Firebase Console
        // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
      );
```

### 2. User Review Required (Firebase Console)
> [!IMPORTANT]
> You MUST ensure the SHA-1 and SHA-256 fingerprints of your signing key are added to the Firebase Console:
> 1. Run `./gradlew signingReport` in the `android` directory to get your SHA-1.
> 2. Add it to Project Settings > Your Apps > Android App in the Firebase Console.
> 3. Download the updated `google-services.json` and place it in `android/app/`.

## Verification Plan

### Manual Verification
1. Clean the project (`flutter clean` & `flutter pub get`).
2. Run the application (`flutter run`).
3. Attempt to sign in with Google.
4. Verify that `googleAuth.idToken` is no longer null and the user successfully authenticates.
