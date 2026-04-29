# Refactoring, Housekeeping & Release Signing Walkthrough

## Completed Objectives
- **Centralized Logging**: Implemented a `Log` utility in `lib/core/logger.dart` that wraps the `logger` package and automatically reports errors to Firebase Crashlytics.
- **Firebase Crashlytics**: Configured plugin in Android build files and initialized in `main.dart`. Connected to `Log.e` for seamless error reporting.
- **Internationalization (L10n)**:
    - Extracted hardcoded strings from `home_screen.dart` to `lib/l10n/app_en.arb`.
    - Updated `home_screen.dart` to use `AppLocalizations`.
    - Resolved build warnings for missing keys in ES, FR, ZH, ZH_Hant files.
- **Code Refactoring**:
    - Replaced `print` statements in `main.dart`, `AuthRepository`, `GameBloc`, and `DatabaseHelper` with `Log` calls.
- **Release Signing**:
    - Configured `android/app/build.gradle.kts` to sign release builds using `android/keystore.properties`.
    - Verified with a successful `flutter build apk --release`.
- **Debugging & Fixes**:
    - **SHA-1**: Identified missing debug SHA-1 as cause of Google Sign-In failure. User added it to console.
    - **Sync**: Identified missing permission as cause of Firestore failure.

## Key Changes

### 1. Release Signing Configuration
Added logic to `android/app/build.gradle.kts` to load signing keys from `keystore.properties`.

### 2. Log Utility (`lib/core/logger.dart`)
New utility class that handles logging levels and Crashlytics reporting.

### 3. Cloud Sync & Security Rules
The app uses two Firestore collections based on the build mode:
*   `dev_users` (Debug Mode)
*   `prod_users` (Release Mode)

**Required Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development Collection
    match /dev_users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Production Collection
    match /prod_users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Verification Results

### Build Verification
Ran `flutter build apk --release` successfully.
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (80.3MB)
```

### Next Steps (User Action Required)
> [!IMPORTANT]
> **Firestore Rules**: Go to [Firebase Console -> Firestore Database -> Rules](https://console.firebase.google.com/) and paste the rules above to fix the "Permission Denied" error.
> **Google Services**: Ensure you have downloaded the latest `google-services.json` (after adding SHA-1) and replaced the old one in `android/app/`.
