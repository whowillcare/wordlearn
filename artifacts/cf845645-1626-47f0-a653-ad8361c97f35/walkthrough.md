# Walkthrough - Wordament Update

## New Features
### 1. Grid Search Game (Wordament)
A new mini-game mode has been added!
- **Grid Generation**: Uses Boggle-like dice distribution to create 4x4 grids.
- **Gameplay**: Swipe across the grid (horizontal, vertical, diagonal) to form words.
- **Validation**:
    - Validates formed words against the local dictionary.
    - Prevents duplicate finds.
    - Ensures valid paths (can't use same cell twice in one word).
    - **Stats**: Attempts are logged once per game start. Wins/Solves are logged only upon successfully completing all words.
    - **Persistence**: Uses `SharedPreferences` to track `daily_solved_YYYY-MM-DD`.
    - **Notifications**: Scheduled daily local notification (9:00 AM) to remind users of new words.
- **Scoring**: Points awarded based on word length.
- **Timer**: 2-minute countdown (placeholder).

### 3. Flashcards (Interactive)
- **Features**: Definition/Synonym questions, Quiz engine.
- **Refinement**: Added interactive review mode (tap words after answering to see definitions).

### 4. Spelling Bee (TTS)
- **Features**: Hear word, type spelling.
- **Refinement**: Added Hints (Reveal Definition, Reveal Letters) costing diamonds.

### 5. Standardizations & Refinements
- **Wordament**: Tuned difficulty by filtering for common words only.
- **Global**: All mini-games now respect global difficulty/category settings.
- **Economy**: Standardized hint costs and rewards.

### 6. Anagram Bonus
- **Feature**: Finding a valid dictionary word that is *not* the target word now rewards **1 Diamond** and displays a "Bonus!" message.
- **Prevention**: Tracks found bonus words to prevent farming the same word.

## Technical Details
- **`WordamentBloc`**: Handles DFS solving and common word filtering.
- **`FlashcardsBloc`**: Manages quiz state and fetching rich content (definitions/synonyms).
- **`SpellingBeeBloc`**: Integrates `flutter_tts` and handles progressive hint logic.
- **`WordRepository`**: Expanded with `getAllWords(onlyCommon)`, `getFlashcardQuestions`, and `getWords`.

## Visuals
*(Screenshots to be added by user after run)*
