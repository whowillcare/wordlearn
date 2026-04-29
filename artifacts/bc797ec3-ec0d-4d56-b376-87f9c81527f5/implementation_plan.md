# Unifying App ID and Name

## User Review Required
> [!NOTE]
> I am interpreting "Word-Le-Rrn" as **"Word-Le-Earn"** to match your Firebase project name (`word-le-earn`). If this is incorrect, please let me know.

## Proposed Changes

### App ID: `com.wit4you.wordlearn`
### App Name: `Word-Le-Earn`

#### Android
- [x] `android/app/build.gradle` (Already done)
- [ ] `android/app/src/main/AndroidManifest.xml`: Update `android:label`.

#### iOS
- [ ] `ios/Runner/Info.plist`: Update `CFBundleDisplayName` and `CFBundleName`.
- [ ] `ios/Runner.xcodeproj/project.pbxproj`: Update `PRODUCT_BUNDLE_IDENTIFIER`.

#### macOS
- [ ] `macos/Runner/Configs/AppInfo.xcconfig`: Update `PRODUCT_BUNDLE_IDENTIFIER`, `PRODUCT_NAME`, `PRODUCT_COPYRIGHT`.
- [ ] `macos/Runner/Info.plist`: Update `CFBundleName`.

#### Web
- [ ] `web/index.html`: Update `<title>`.
- [ ] `web/manifest.json`: Update `name` and `short_name`.

#### Windows
- [ ] `windows/runner/main.cpp`: Update window title.
- [ ] `windows/runner/Runner.rc`: Update `FileDescription`, `InternalName`, etc. (if easily accessible).

#### Linux
- [ ] `linux/my_application.cc` (or `main.cc`): Update window title.
- [ ] `linux/CMakeLists.txt`: Update binary name (optional, risky).

### Firebase
- [ ] Run `flutterfire configure` to register updated platform IDs.

## Verification
- Check `firebase_options.dart` for correct bundle IDs.
- Launch app on available platforms (Android/Linux) to verify name.
