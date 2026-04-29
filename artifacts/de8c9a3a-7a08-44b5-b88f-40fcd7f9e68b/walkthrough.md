# Walkthrough - Social Features & Data Management Refactor

I have successfully implemented the "Social Share" features and refactored the application's data management system to use a pre-built SQLite database.

## Changes

### Social Features
- **Share Victory**: Added a "Share" button to the Victory Dialog.
  - Uses `screenshot` package to capture the game board.
  - Uses `share_plus` to share the image and text "I solved the word [WORD] in [MOVES] guesses!".
- **Ask for Help**: Added a "Share" icon to the AppBar during gameplay.
  - Captures the current game state (guesses/colors).
  - Shares the image with text "Can you help me solve this word?".

### Data Management Refactor
- **Pre-built Database**: Transitioned from parsing thousands of JSON files at runtime to shipping a pre-built `dictionary.db`.
  - Created `dictionary/data` and `dictionary/other` to house source files.
  - Developed `tool/build_db.dart` to generate the database offline, aggregating all word lists and thesaurus data.
  - Usage: `dart run tool/build_db.dart` generates `assets/dictionary.db`.
  - Build script robustly handles mixed JSON structures (`List<String>` vs `Map<String, List>`).
  - **Schema Update**: Added `length` column to `words` table to support efficient filtering (fixed "no such column" error).
- **Optimization**:
  - `DatabaseHelper` now copies the `dictionary.db` from assets to local storage on first run, significantly reducing startup time and complexity.
  - Removed `DataIngester` and runtime parsing logic.
  - Updated `WordRepository` to use `sqflite` API for better performance and compatibility.

### UX Refinements (Game Screen)
- **Auto-Scroll**: Implemented `ScrollController` in `GuessGrid` to automatically scroll to the end of the input as the user types long words.
- **Compact Rows**: Submitted guesses now automatically shrink (using `FittedBox`) and use smaller bubbles (32px vs 50px) to fit within the screen width, reducing the need for vertical scrolling.

### Feature Implementation: Hints, Meanings, Daily Challenge
- **Hint System Overhaul**:
  - **Tier 1 (10 pts)**: Reveal Category (or context).
  - **Tier 2 (20 pts)**: Reveal Synonym. If none, reveals masked definition.
  - **Tier 3 (30 pts)**: Revive Game (grants 3 extra attempts).
  - **UI**: Added a BottomSheet menu for selecting hints with transparent costs.
- **Word Meanings**:
  - Enriched data layer to fetch definitions, synonyms, and POS.
  - **Library**: `WordDetailDialog` now shows full word details.
  - **Post-Win**: Victory dialog displays the word's definition.
- **Daily Challenge**:
  - Automatically selects 3 words daily (Short, Medium, Long) from the database.
  - **Home Screen**: Added a "Daily Challenge" card to play these specific words.

## Verification Results

### Automated Tests
- **Database Generation**: `flutter test test/make_db_test.dart` passed.
  - Verified successful ingestion of 117k+ thesaurus entries and all category word lists.
  - Produced `assets/dictionary.db`.
- **App Compilation & Initialization**: `flutter test test/widget_test.dart` passed.
  - Verified `MyApp` builds correctly with the new `DatabaseHelper` and `WordRepository` logic.
  - Confirmed dependency injection and mock interactions.

### Manual Verification Steps
1. **Daily Challenge**:
   - Check Home Screen for "Daily Challenge" card.
   - Play one of the words (e.g. "Challenge 1"). Verify length matches description.
2. **Hints**:
   - Start a game (or use Daily Challenge).
   - Tap Hint button -> Verify Menu appears with costs.
   - Use "Reveal Letter" (10 pts). Verify points deducted and letter revealed.
   - Use "Reveal Synonym" (20 pts). Verify message shows synonym/definition.
3. **Word Meanings**:
   - Win a game. Verify definition appears in Victory Dialog.
   - Go to Library. Tap a word. Verify definition/synonyms appear.
4. **Revive**:
   - Lose a game. Verify "Revive" dialog says "30 pts".
   - Click Revive (if sufficient points). Verify +3 attempts granted.
5. **Points Display**:
   - Verify points are shown in the Game Screen AppBar (e.g. "150 Pts").
   - Perform actions (Play, Win, Use Hint) and verify points update in real-time.
6. **UI Refinements**:
   - **Game Title**: Tap the "Categories / Level" text in AppBar. Verify a dialog appears with details.
   - **Library**: Open Library. Verify Filter Menu and Item Subtitles show friendly names (e.g. "Grade 1" not "grade-1").
7. **Refinements (Diamonds)**:
   - **Interaction**: Tap the Diamonds badge in Home or Game screen. Verify "Watch Video" / "Shop" dialog appears.
   - **Hints**: Try to use a hint with insufficient diamonds. Verify the "Get Diamonds" dialog appears automatically.
   - **Terminology**: Verify all texts refer to "Diamonds" instead of Points/Coins.
8. **UX Refinements**:
   - **Dynamic Sizing**: Play a level with long words (e.g. "Biology"). Verify bubbles are slightly smaller (40px) to fit more on screen.
   - **Scroll Fade**: If the word is very long, verify the edges of the row fade out to indicate scrolling.
   - **AppBar Menu**: Verify AppBar only shows Points, Share, and "More" (3 dots).
   - **More Actions**: Tap "More" menu. Verify "Word Count" is shown as text and "Keep Screen ON/OFF" is a toggleable option.
   - **Title Dialog**: Tap the "Category/Level" title. Verify the dialog now shows "Word Candidates: X words".
   - **Points Sync**:
       - Verify Points on Home Screen.
       - Enter Game. Verify Points match immediately (no delay/zero blinking).
       - Earn points (play/watch ad). Return to Home. Verify points match immediately.
       - Use a "Letter Hint" (ensure you have Diamonds).
       - Verify the hint reveals a *new* letter (White/Yellow position), avoiding the already known Green ones if possible.
   - **Account & Sync**:
       - Go to Settings. Scroll to "Account".
       - Tap "Connect Account". Follow Google Sign-In flow.
       - Verify your Name/Photo appears and button changes to "Sign Out".
       - Earn points. Re-open app. Verify points persist (Cloud Sync).
