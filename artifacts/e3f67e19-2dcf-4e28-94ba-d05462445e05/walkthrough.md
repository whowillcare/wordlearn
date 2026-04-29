# WordLearn Walkthrough

I have implemented the WordLearn application, a Flutter-based word game inspired by Wordle.

## Features Implemented

### 1. Data Layer (`lib/data`)
- **SQLite Database**: `DatabaseHelper` manages a local SQLite database with `words` and **`learnt_words`** tables.
- **Data Ingestion**: `DataIngester` reads JSON files from `assets/data` (migrated from `word/src`) and bulk-inserts them into the database on app startup.
- **Repository**: `WordRepository` provides methods to query words by category and length, track word counts, and manage the learned library.

### 2. Game Logic (`lib/logic`)
- **GameBloc**: Manages the game state using `flutter_bloc`.
    - **States**: `initial`, `playing`, `won`, `lost`.
    - **Events**: `GameStarted` (configures game), `GuessSubmitted` (validates guess), `HintRequested` (reveals a letter), **`SolutionRequested`** (reveals word and saves to library).
    - **Logic**: Handles word selection, guess tracking, hint mechanics, and auto-saving words to the library on win or solution reveal.

### 3. UI Layer (`lib/ui`)
- **HomeScreen**: Allows the user to select a Word Category (dynamically loaded from DB) and Word Length range (2-20). Includes access to the **Learnt Library**.
- **GameScreen**: Displays current game status, target word length, guesses, and hints.
    - Includes a virtual keyboard/input field for guesses.
    - Displays visual feedback (Green/Orange/Grey) for guesses.
    - **Solution Button**: Reveals the word and adds it to the library.
- **LibraryScreen**: Lists all words the user has learned (won or revealed).
- **WordDetailScreen**: Displays the word and a **Pronounce** button (using `flutter_tts`). Includes a placeholder for definition (pending API integration).

## Verification

### Data Ingestion Test
I verified the data ingestion logic with a unit test `test/data_ingester_test.dart`.
- **Result**: Passed. The test confirmed that files are parsed correctly from the AssetManifest and inserted into the mock repository.

```
00:11 +1: All tests passed!
```

### Manual Verification Steps
To run the app and play:
1.  **Run**:
    > [!IMPORTANT]
    > **Linux Build Fix**: The build fails because the compiled `clang` toolchain in the Flutter Snap is missing the `lld` linker.
    > Please run the following command on your host system to fix it:
    > ```bash
    > sudo apt install lld
    > ```
    > Then run:
    > ```bash
    > flutter run -d linux
    > ```
2.  **Ingestion**: Wait for the splash/loading (handled in `main` async). Logs will show "Ingested X words".
3.  **Config**: Select a category (e.g., "grade-11") and length (e.g., 5).
4.  **Play**:
    - Enter words.
    - Use "Get Hint" for help.
    - Use "Solution" to give up and learn the word.
5.  **Library**: Go to Home -> Library Icon -> Tap a word to see detail and hear pronunciation.

## Next Steps
- Implement a real dictionary API for definitions in `WordDetailScreen`.
- Improve error handling for missing assets.
