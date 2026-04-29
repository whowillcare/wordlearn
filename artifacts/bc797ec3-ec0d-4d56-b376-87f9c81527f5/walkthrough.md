
# Migration Walkthrough

## Summary
Successfully migrated the core logic from the old WordLearn app to the new Flutter project. This includes porting the Level definitions, implementing a Statistics system using SharedPreferences, refactoring the UI, and ensuring robust database population.

## Changes Implemented

### 1. Game Levels
**File:** `lib/data/game_levels.dart`
- define `GameLevel` class.
- Ported levels from old app: Casual, Interesting, Classic, Playable, Advanced, Insane.
- Each level defines `minLength`, `maxLength`, and `attempts`.

### 2. Statistics System
**Files:** `lib/data/statistics_repository.dart`, `lib/data/game_score.dart`
- Created `StatisticsRepository` to persist game outcomes.
- Uses `shared_preferences` to store stats per level key.
- Tracks: Games Started, Games Won, Win Streak, Best Win Streak, Average Score/Time.

### 3. Game Logic (BLoC)
**File:** `lib/logic/game_bloc.dart`
- Updated `GameStarted` event to accept `GameLevel`.
- Implemented `recordGame` logic in `_onGuessSubmitted` (Win/Loss conditions).
- Implemented `recordGame` logic in `_onSolutionRequested` (Loss condition).
- Uses `WordRepository` to fetch words based on level constraints.

### 4. UI Refactor
**File:** `lib/ui/home_screen.dart`
- Replaced simple Length Slider with a **Level Dropdown**.
- Users can now select specific difficulty levels.
- **Diagnostics**: Added a startup dialog that displays the status of data ingestion (e.g., "Files Found: 150", "Final Count: 12000") to help troubleshoot missing data issues.

**File:** `lib/ui/game_screen.dart`
- Updated to accept `GameLevel` and pass it to the BLoC.
- Displays standard Wordle-like UI.

**File:** `lib/main.dart`
- Injected `StatisticsRepository` into the widget tree via `MultiRepositoryProvider`.
- Initiates data ingestion on startup and passes the result to `HomeScreen`.

### 5. Database Population Fix
**File:** `lib/data/database_helper.dart`
- Corrected the asset search path from `assets/words/` (legacy) to `assets/data/` (actual location).
- Updated to use `AssetManifest.loadFromAssetBundle` instead of raw JSON parsing to fix Android asset loading errors.

**File:** `lib/data/data_ingester.dart`
- Updated to return detailed `IngestionResult` (success/fail, file count, error list) for UI feedback.
- Switched to `AssetManifest` class to ensure robust file discovery across platforms.

### 6. UI Overhaul (Classic Wordle Style)
**Components:** `lib/ui/components/keyboard.dart`, `lib/ui/components/guess_grid.dart`
- Implemented a reusable `Keyboard` widget with QWERTY layout and special keys (Enter, Delete).
- **Responsiveness**: Refactored Keyboard to use `Expanded` and flex layouts to adapt to any screen width.
- Implemented `GuessGrid` to display past guesses and current typing with color-coded feedback.
- **Scrolling**: Added horizontal scrolling support for words longer than screen width (8-10+ chars).

**Logic:** `lib/logic/game_bloc.dart`, `game_state.dart`
- Refactored `GameBloc` to handle `LetterEntered` and `LetterDeleted` events.
- Added `letterStatus` map to `GameState` to track key coloring based on guess results.
- Promoted `GameState` and `GameEvent` to standalone files for cleaner architecture.

**Screen:** `lib/ui/game_screen.dart`
- Replaced the simple `TextField` and ListView with the new `GuessGrid` and `Keyboard`.
- Wired up keyboard events to the Bloc.

### 7. Phase 2: Features & Infrastructure
**Infrastructure:**
- Added `audioplayers`, `intl`, `flutter_localizations`.
- Created `SettingsRepository` (SharedPreferences) to manage:
    - Sound Enabled
    - VIP Mode
    - Default Category
    - Language Code

**Game Logic & Validation:**
- **Gibberish Check:** `GameBloc` now checks `_repository.isValidWord(guess)` before accepting input.
- **Sound Effects:** Triggers success/error/fail sounds based on game events and settings.
- **Persistence:** default category selection is saved and restored on app launch.

**UI Updates:**
- **Settings Screen:** Toggle Sound/VIP, set Default Category.
- **Home Screen:** Navigation to Settings and Library.
- **Game Screen:** Added `ConfettiWidget` and Victory Dialog for better win experience.
- **Library Screen:**
    - Displays list of learnt words with Category and Date.
    - **Filter:** By Category or "Favorites Only".
    - **Favorites:** Toggle heart icon to save favorite words.
    - **Swipe to Delete:** Supports Undo via SnackBar.
- **I18n:** Basic `app_en.arb` setup and generation hooked up.

## Verification
- **Automated Tests:** API and Widget tests passed (`flutter test` result: `All tests passed!`).
- **Manual Verification:**
    - Verified `LibraryBloc` logic for filtering and undo.
    - Verified `WordRepository` schema migration logic (defensive columns addition).
    - Verified `GameBloc` correctly saves category to Library on win.
    - Verified `SettingsRepository` stores and retrieves multiple categories correctly.

### Phase 3: Rebranding & Cloud Sync
- **Package Name:** Updated to `com.wit4you.wordlearn` (ID) and **"Word-Le-Earn"** (Display Name).
    - **Android**: `build.gradle`, `AndroidManifest.xml`.
    - **iOS**: `Info.plist`, `project.pbxproj`.
    - **macOS**: `AppInfo.xcconfig`.
    - **Web**: `index.html`.
    - **Windows**: `main.cpp`.
    - **Linux**: `my_application.cc`, `CMakeLists.txt`.
- **App Icons:** Generated from `Wordlearn.jpg` for all supported platforms using `flutter_launcher_icons`.
- **Firebase:** Added dependencies. Config (`flutterfire configure`) was interrupted by user request and may need manual resumption.
- **Settings Sync:**
    - Uses **Anonymous Auth** to identify users.
    - Syncs `vip_mode`, `sound_enabled`, `language_code`, and `default_categories` to Firestore `users/{uid}`.
    - Logic handles offline/online automatically via Firestore SDK.
- **Verification:**
    - `SettingsRepository` triggers sync on every setting change.
    - Mocks updated for `syncSettings` method.
