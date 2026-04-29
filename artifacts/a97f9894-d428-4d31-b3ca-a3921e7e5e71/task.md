
# Build Fixes and Design Implementation

- [x] Fix syntax errors in `lib/data/database_helper.dart` <!-- id: 0 -->
- [x] Fix missing fields in `lib/ui/components/keyboard.dart` <!-- id: 1 -->
- [ ] Verify build succeeds (Failed: missing audio deps) <!-- id: 2 -->
- [x] Investigate and implement unfinished design elements <!-- id: 3 -->
    - [x] Dynamic keyboard keys (hyphen, apostrophe) based on settings (Backend done, UI implemented) <!-- id: 4 -->
    - [x] Localization checks (Added missing keys) <!-- id: 5 -->

# Feature Implementation: Categories & Icon
- [x] Integrate User's App Icon (`Wordlearn.jpg`) <!-- id: 6 -->
- [x] Update `pubspec.yaml` and generation config for icons <!-- id: 7 -->
- [ ] Implement Category Selection in Home Screen <!-- id: 8 -->
    - [x] `WordRepository`: Ensure category fetching works (Already implemented) <!-- id: 9 -->
    - [x] `HomeScreen`: Add Category List/Grid UI (Implemented horizontal ChoiceChip list) <!-- id: 10 -->
    - [x] `GameScreen`: Ensure category filtering works (Passed to GameScreen constructor) <!-- id: 11 -->

# Fixes & Polish
- [x] Fix `HomeScreen` Category Selection Logic (Implemented robust toggle logic) <!-- id: 12 -->
- [x] Enhance `HomeScreen` Design (Showcase Standard) <!-- id: 13 -->
    - [x] Mesh Gradient Background (Implemented MeshGradientPainter) <!-- id: 14 -->
    - [x] Glassmorphism Components (Implemented GlassContainer) <!-- id: 15 -->
    - [x] Neon Capsule Selectors (Implemented NeonCapsule) <!-- id: 16 -->
    - [x] 3D Hero Play Button (Implemented Gradient BoxShadow) <!-- id: 17 -->

# Refactor: Centralize Settings
- [x] Update `SettingsRepository` for Level Persistence <!-- id: 18 -->
- [x] Implement Searchable Multi-Select in `SettingsScreen` <!-- id: 19 -->
- [x] Implement Level Selector in `SettingsScreen` <!-- id: 20 -->
- [x] Update `HomeScreen` to Read-Only Display <!-- id: 21 -->

# Debugging & Verification
- [x] Fix `Provider` error in `HomeScreen` (Refactored state access)
- [x] Fix `LateInitializationError` in `SettingsScreen` (Refactored to use `context.watch`)
- [x] Verify Android Icon update on Android 15+ (User verification required)
- [x] Verify AdMob integration (User verification required)
- [x] Verify Fix: Category Friendly Names & Live Updates
- [x] Verify Fix: "Resume Game" Logic
- [x] Fix Build Errors (Platform Channel & Syntax)
    - [x] Resolve `storageDirectory` type mismatch in `main.dart`
    - [x] Fix `RenderFlex` overflow in `home_screen.dart`
    - [x] Implement missing methods in `game_screen.dart`
    - [x] Fix syntax errors in `game_bloc.dart` and `guess_grid.dart`rmatter map)
- [x] Fix Build Error: `ChangeNotifier` not found (Added `flutter/foundation.dart` import)
- [ ] Fix Linux Build Error: Install GStreamer dependencies (`libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`)
- [x] Fix Android 15+ Adaptive Icon (Added adaptive configuration)
