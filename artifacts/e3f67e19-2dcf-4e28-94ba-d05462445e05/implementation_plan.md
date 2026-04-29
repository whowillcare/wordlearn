# WordLearn Implementation Plan

The goal is to build a Flutter-based Wordle-like game where users can choose word length (2-20+) and categories (based on existing data in `word/src`).

## User Review Required

> [!IMPORTANT]
> - **Data Source**: I will primarily use the JSON files in `word/src` for word lists and categorization. The `word/mer` directory (HTML files) will be skipped for now as the core mechanics (spelling, length, category) only require the JSON lists.
> - **Platform**: The app will be initialized in the `flutter` directory.
> - **Firebase**: The user mentioned Firebase. I will include `firebase_core` and `firebase_analytics` but will not fully implement Auth/Cloud Firestore unless requested, as the prompt focuses on the game mechanics and local SQLite data.

## Proposed Changes

### Project Initialization
- Initialize a new Flutter project in `wordlearn/flutter`.
- Add dependencies:
    - `flutter_bloc`: State management.
    - `sqlite3` & `sqlite3_flutter_libs`: Local database.
    - `path_provider` & `path`: File system access.
    - `equatable`: Value equality.
    - `firebase_core` (optional setup).

### Data Layer
- **Database Schema**:
    - Table `words`:
        - `id` (INTEGER PRIMARY KEY)
        - `text` (TEXT)
        - `length` (INTEGER)
        - `category` (TEXT) - derived from filename (e.g., "grade-11-arts1")
- **Data Ingestion**:
    - A mechanism to parse JSON files from `word/src` and populate the SQLite database.
    - *Strategy*: Copy relevant JSONs to `flutter/assets/data` during build or read from the absolute path if running strictly locally for dev. **Decision**: I'll add a script to copy `word/src` JSONs to `flutter/assets` so the app is self-contained.

### Game Logic (BLoC)
- **GameBloc**:
    - **Events**:
        - `GameStarted`: Params for Category, Min Length, Max Length.
        - `GuessSubmitted`: User inputs a word.
        - `HintRequested`: User asks for a hint.
    - **States**:
        - `GameInitial`: Configuration screen.
        - `GameInProgress`: Active game loop.
        - `GameWon` / `GameLost`: End states.
    - **Logic**:
        - Filter words from DB based on Category/Length.
        - Randomly select `targetWord`.
        - Validate guesses (must be in dictionary? or just correct length?). *Assumption*: Guesses must be valid words from the DB (or at least the same length).
        - Hint: Reveal a random unrevealed letter in the `targetWord`.

### UI Design
- **HomeScreen**:
    - Dropdown/Wrap for Category selection.
    - Range Slider for Word Length (2-20).
    - "Start Game" button.
- **GameScreen**:
    - **Header**: Current Category/Level.
    - **Grid**: Dynamic grid based on `targetWord.length`.
    - **Keyboard**: On-screen keyboard showing letter states (correct, present, absent).
    - **Footer**: "Hint" button.

## Verification Plan

### Automated Tests
- **Unit Tests**:
    - Test `GameBloc` logic:
        - Start game emits `GameInProgress`.
        - Correct guess emits `GameWon`.
        - Incorrect guess updates attempts/grid.
        - Hint reveals correct letter.
    - Test `WordRepository`:
        - Querying words by category/length returns expected results.

### Manual Verification
1.  **Ingestion**: Run app, verify DB population log. Check if words are queryable.
2.  **Gameplay**:
    - Select "Grade 11" and Length "5".
    - Verify target word is 5 letters and from Grade 11 list.
    - Play a game to completion (Win/Loss).
    - Use Hint button and verify a letter is revealed.

### Learned Library
- **Database**: Add `learnt_words` table (`word` TEXT PRIMARY KEY, `date_added` INTEGER).
- **Logic**:
    - Add `WordSolved` event or handle `GameWon` to trigger insertion.
    - Implement "Solution" button logic -> Triggers `GameLost` (visuals) but marks word as "learnt" (or maybe distinct "revealed" status, user asked "can be added into learnt library").
    - **Decision**: Solving (winning) OR Revealing (solution button) adds to library.
- **UI**:
    - `LibraryScreen`: List of words.
    - `WordDetailScreen`:
        - Shows Word.
        - **Definition**: Load HTML from `word/mer/[word].html` (if available) or use `Dictionary API` as fallback.
        - **Pronunciation**: `flutter_tts`.

