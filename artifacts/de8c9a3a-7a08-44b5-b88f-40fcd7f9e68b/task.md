# Master Implementation Plan

## Core Infrastructure & Game Logic (Completed)
- [x] **Project Setup**: Flutter project initialized, renamed to "Word-Le-Earn", App ID `com.wit4you.wordlearn`.
- [x] **Dependencies**: Added `flutter_bloc`, `hydrated_bloc`, `google_mobile_ads`, `firebase_core`, `sqflite`.
- [x] **Game Engine (`GameBloc`)**:
    - [x] Word validation and difficulty levels.
    - [x] State management (Playing, Won, Lost).
    - [x] Scoring and timing.
    - [x] **Game Economics**: Cost 5 points to play, Win 10 points.
    - [x] **Keyboard Logic**: Filter words with special chars if keyboard is NOT extended.
    - [x] **Library Integration (Interactive)**:
        - [x] Tap any word (guess or target) to view details.
        - [x] Toggle Library status (Add/Remove) with solid/hollow bookmark.
    - [x] **Hint System (Tiered - All Cost Points)**:
        - [x] **Hint 1**: Reveal Word Categories (10 Points).
        - [x] **Hint 2**: Reveal Synonym or Letter (10/20 Points).
        - [x] **Hint 3**: Revive (30 Points).
    - [ ] **Retry System**: Option to spend points to retry a failed game.
    - [ ] **Social Share**: Share screenshot functionality.
- [x] **Persistence**:
    - [x] `HydratedBloc` for game state (resume capability).
    - [x] `SettingsRepository` for user preferences.
    - [x] `StatisticsRepository` for game history.
- [x] **Data Management**:
    - [x] JSON Data Ingestion (`DataIngester`).
    - [x] SQLite Database (`WordRepository`).
    - [ ] **Content Expansion**:
        - [ ] Add categories: Animals, Plants, Flowers, Biology, Medical.
        - [ ] **Advanced Data**: Extend schema for Synonyms, Antonyms, and Thesaurus tables.
- [x] **Localization Infrastructure**: Support for EN, ZH, FR, ES (UI Strings).
- [ ] **Content Localization**: Translation of actual word lists and definitions.

## User Authentication & Cloud Sync (Refining)
- [x] **Dependencies**: Add `google_sign_in`.
- [x] **Auth Infrastructure**:
    - [x] `AuthRepository`: Implement `signInWithGoogle` and `signOut`.
    - [x] Silent Login: Check for existing user on app start.
- [x] **Auth UI**:
    - [x] **Settings Screen**: Add "Connect Account" / "Sign Out" button.
    - [x] Display User Profile (Photo/Name) in Settings if logged in.
- [x] **Cloud Sync (Firestore)**:
    - [x] **Schema Design**: Use `dev_` prefix for debug, `prod_` for release.
        - [x] Users Collection: `dev_users` vs `prod_users`.
    - [x] **Sync Logic**: Upload local `StatisticsRepository` data to Firestore on login/change.
    - [x] **Merge Logic**: Handle conflicts (server wins or max value wins for high scores).

## UI/UX Implementation (Partial)
- [x] **Home Screen**:
    - [x] Mesh Gradient Background.
    - [x] Resume/Start Logic.
    - [x] Category/Level Summaries.
- [x] **Game Screen**:
    - [x] Word Grid and Keyboard (assumed implemented in `ui/components`).
    - [x] Animations and Transitions.
    - [x] **UX Improvements**:
        - [x] **Auto-Scroll**: Input field scrolls with typing/backspace for user context visibility.
        - [x] **Dynamic Sizing**: For words > 5 letters, shrink input circle and padding to reduce horizontal scrolling.
    - [x] **Scroll Indicators**: Visually indicate (fade/arrow) at screen edges if horizontal scrolling is available.
    - [x] **Screensaver Toggle**:
        - [x] Add `wakelock_plus` dependency.
        - [x] Auto-enable Wakelock on Game Start.
        - [x] Floating Button/Icon to toggle Wakelock (Enable/Disable Screensaver).
    - [x] **AppBar Refactor**:
        - [x] Move "Word Count" and "Disable Screensaver" to "More Actions" (PopupMenu).
        - [x] Add "Word Candidates Count" to Title Info Dialog.
    - [x] **Points System Refactor**:
        - [x] Fixed desync using `BehaviorSubject` (RxDart).
    - [x] **Hint Strategy Improvement**:
        - [x] Logic: Filter candidate indices. Exclude index `i` if any previous guess had `guess[i] == target[i]`.
    - [x] **Compact Rows**: Completed guesses shrink (less gap) to fit screen and reduce scrolling.
- [x] **Settings Screen**: Category and Level selection.
- [x] **Library Screen**: View learnt words.
  - [x] **Refinement**: Ensure "Friendly Names" are used for all categories.
- [ ] **Shop Screen**: currently a placeholder. Needs implementation.
- [ ] **Tutorial/Onboarding**: Guide for new users (if not exists).
- [ ] **Game Power-Ups**:
    - [ ] Implement "Shuffle" button logic in Game Screen.
    - [x] **Hint Cost**: Deduct coins/points when using a hint (refine existing logic).

## UI/UX Refinements (New)
- [x] **Consistent Friendly Names**: Ensure `CategoryUtils.formatName` is used everywhere (Game, Library, Home).
- [x] **Game Screen Improvements**:
    - [x] Display User Points in AppBar.
    - [x] **Title Interaction**: Tap title to show Game Config Dialog (Categories, Level, Length).

## Future Feature: Mini Word Games (To-Do)
- [ ] **Purpose**: Build strong vocabulary through varied gameplay.
- [ ] **Ideas**:
    - [ ] Word Connect / Anagrams.
    - [ ] Flashcards mode.
    - [ ] Spelling Bee.

## Monetization (Ads & IAP) (To-Do)
- [ ] **AdMob Banner**:
    - [ ] Top of Game Screen.
    - [ ] Word Screen (WordDetailDialog/Library).
    - [x] **AdMob Interstitial & Rewarded**:
        - [x] Control showing rate (Frequency Capping).
        - [x] **Rewarded Video**: Option to watch video to earn points.

- [x] **Gamification & Economy (Completed)**:
    - [x] **Economy Design**: Defined costs/rewards (Start: 100, Play: 10, Win: 20).
    - [x] **Daily Bonus**:
        - [x] Track login streaks.
        - [x] Reward +20 coins daily, +100 coins on Day 7.
        - [x] UI: Dialog alerting user of bonus.
    - [x] **Core Game Costs**:
        - [x] Play Cost: 10 points.
        - [x] Win Reward: 20 points.
    - [x] **Sinks (Spending)**:
        - [x] Tier 1 Hint (Category): 10 points.
        - [x] Tier 2 Hint (Letter): 25 points.
        - [x] Tier 3 Hint (Revive): 50 points.
    - [x] **UI Updates**: HomeScreen header reflects real-time Diamonds.
    - [x] **Points Interaction**:
        - [x] Tap Points -> Show Dialog (Watch Ad / Go to Shop).
        - [x] Link "Watch Ad" to Rewarded Video.
        - [x] Link "Go to Shop" to Shop Tab.
        - [x] **Insufficient Funds**: Prompt user with same dialog when attempting hint without funds.
        - [x] **Unification**: Renamed "Points" to "Diamonds" across UI.

- [ ] **Monetization Phase 2: In-App Purchases (IAP)**:
    - [ ] **Store Integration**: Setup `in_app_purchase` package.
    - [ ] **Products**:
        - [ ] Small Point Pack (500 coins).
        - [ ] Medium Point Pack (1500 coins).
        - [ ] **VIP Status** (Remove Ads + Infinite Energy/Points).

- [x] **Social Features**:
    - [x] **Share Screenshot**: Share victory results.
    - [x] **Ask for Help**: Share gameplay screenshot (AppBar).

## Gamification & Retention (To-Do)
- [x] **Daily Challenge Logic**:
    - [x] Implement backing logic for the daily challenge (3/5 words).
    - [x] Persist daily progress (via completed game stats).
- [ ] **VIP Logic**:
    - [ ] Remove hardcoded `const isVip = true`.
    - [ ] Restrict features/show ads based on VIP status.
- [ ] **XP System**: Ensure XP updates are displayed correctly and animated.

## Polish & Platform Specifics
- [x] **Adaptive Icons**: Configured in `pubspec.yaml`.
- [ ] **Sound Assets**: Verify `sounds/success.wav`, `sounds/fail.wav`, `sounds/error.wav` exist in assets.
- [ ] **Linux Build**: Verify build stability on Linux (GStreamer dependencies).

## Hybrid Architecture / API Integration (Future Roadmap)
- [ ] **Dual-Mode Build Option**:
    - [ ] **Local Mode (Default)**: Use independent SQLite database (offline capable).
    - [ ] **API Mode (Thin Client)**:
        - [ ] Develop server-side REST API (getting all DB functions).
        - [ ] Remove local database asset to reduce package size.
        - [ ] Refactor repositories to switch between `LocalDataSource` and `RemoteDataSource` based on build flag.
