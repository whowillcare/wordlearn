# Implementation Plan - Daily Challenge Logic

## Goal
Implement a robust Daily Challenge system where all users play the same set of words each day. The system must support self-generation (serverless-like), global statistics, and progress persistence.

## Proposed Changes

### 1. Data Layer
#### [DailyChallengeRepository](file:///home/sam/Projects/wordlearn/flutter/lib/data/daily_challenge_repository.dart) [NEW]
*   **Collection**: Uses `CloudSyncService.collectionName` + `/public/daily_word/{YYYY-MM-DD}`.
*   **Model**: `DailyChallenge`
    *   `date`: String (YYYY-MM-DD)
    *   `words`: List<String> (3 words typically)
    *   `stats`: Map<String, int> (`attempts`, `successes`, `failures`)
*   **Methods**:
    *   `getDailyChallenge()`:
        *   Try `get()` doc.
        *   If existing: Return it.
        *   If missing:
            *   Generate words using `WordRepository.getDailyChallengeWords()`.
            *   Try `set()` (use transaction or robust create to avoid race conditions, or just last-write-wins is acceptable for MVP as same seed/logic usually produces similar output if randomized? No, random needs to be consistent. Race condition: First writer wins).
            *   Return generated challenge.
    *   `incrementStats(String date, bool won)`:
        *   `update()` doc with `FieldValue.increment`.
*   **Local Persistence**:
    *   Store `last_played_date` and `completed` status in `SharedPreferences` or `user_progress` to prevent replay.

### 2. Domain Layer / Logic
#### [DailyChallengeBloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/daily_challenge_bloc.dart) [NEW]
*   **Events**:
    *   `LoadDailyChallenge`: Fetch today's challenge.
    *   `StartDailyGame`: Begin the sequence.
    *   `WordCompleted(word, success)`: Record result, move to next word.
    *   `ChallengeFinished`: Update global stats, show summary.
*   **State**:
    *   `Loading`, `Ready`, `Playing`, `Finished`.
    *   `currentWordIndex`.
    *   `results`: List<bool> (win/loss per word).
    *   `globalStats`: The stats fetched from Firestore.

### 3. UI
#### [HomeScreen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/home_screen.dart)
*   **Update Card**: "Daily Challenge" card should show "Play" or "Completed" based on local persistence.
*   **On Tap**: Navigate to `DailyChallengeScreen`.

#### [DailyChallengeScreen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/daily_challenge_screen.dart) [NEW]
*   **UI**:
    *   Sequential game play (reusing `GameScreen` logic or embedding `GameView`?).
    *   *Simpler*: Pass a "playlist" to `GameScreen`? Or specialized view?
    *   *Decision*: Specialized view that wraps `GameBloc` or simplified game logic might be best, OR modify `GameBloc` to handle "Daily Mode".
    *   *Refined Decision*: Create `DailyChallengeScreen` that instantiates `GameScreen` for each word? Or better, `GameScreen` takes a `GameSession` object.
    *   *Smarter MVP*: `DailyChallengeBloc` manages the flow. It tells the UI "Show Game for Word X". The UI mounts a game widget. When that game finishes, UI notifies Bloc, Bloc updates state to "Word Y".
*   **Summary Screen**:
    *   Shown after all words done.
    *   Display Global Stats (You vs World).

## Verification Plan
*   **Generation**: Run app on fresh date -> Verify doc created in Firestore.
*   **Sync**: Run second instance -> Verify it loads same words.
*   **Stats**: Complete game -> Check Firestore counters increment.
*   **Lockout**: Restart app -> Verify "Completed" state persists.

## Implementation Plan - Mini Game Refinements (User Feedback)

### 1. Wordament (Grid Search)
*   **Goal**: Reduce "impossible/obscure" words.
*   **Changes**:
    *   **[WordRepository](file:///home/sam/Projects/wordlearn/flutter/lib/data/word_repository.dart)**: Update `getAllWords` to accept `bool onlyCommon`.
    *   **[WordamentBloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/wordament_bloc.dart)**: Call `getAllWords(onlyCommon: true)` to ensure only common words are valid/counted.

### 2. Flashcards
*   **Goal**: Allow reviewing words after answering.
*   **Changes**:
    *   **[FlashcardsScreen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/flashcards_screen.dart)**:
        *   Update `_buildOptionCard` to be interactive even after selection.
        *   On tap (post-answer): Show `WordDetailDialog`(add to library/view def).

### 3. Spelling Bee
*   **Goal**: Add Hints (Definition, Reveal Letter).
*   **Changes**:
    *   **[SpellingBeeBloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/spelling_bee_bloc.dart)**:
        *   Add `hintText` (for letters) and `definition` (from DB) to State.
        *   Event `RequestHint`: Deduct points -> Reveal Letter OR Show Definition.
    *   **[SpellingBeeScreen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/spelling_bee_screen.dart)**:
        *   Add "Hint" button (Lightbulb).
        *   First tap: Show Definition (Free or Cheap?).
        *   Long Press / Second Tap: Reveal Letter (Cost 5 Diamonds).

### 4. Anagram / Scramble
*   **Goal**: Enhance hints to match "Wordle" style (standardized).
*   **Changes**:
    *   **[MiniGameBloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/minigame_bloc.dart)**: Ensure `RequestHint` reveals one letter at a cost.
    *   **UI**: Ensure consistent "Hint" button placement.
