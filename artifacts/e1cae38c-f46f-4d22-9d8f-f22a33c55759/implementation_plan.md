# Fix Google Play Services Visibility

The error `java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'` is likely caused by Android 11+ package visibility restrictions. The app attempts to interact with Google Play Services but hasn't declared permission to "see" that package.

## Proposed Changes

### Android
#### [MODIFY] [AndroidManifest.xml](file:///home/sam/Projects/wordlearn/flutter/android/app/src/main/AndroidManifest.xml)
- Add `<package android:name="com.google.android.gms" />` to the `<queries>` block.

## Verification Plan

### Manual Verification
1.  Run `flutter clean`.
2.  Run `flutter run`.
3.  Observe logs to see if the `SecurityException` persists.
