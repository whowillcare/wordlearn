# Word-Le-Earn Design & Implementation Plan

## Goal Description
Redesign "Word-Le-Earn" to have a dual identity: a compelling **Simple English Game** for engagement and a robust **Learning Tool** for practice. The goal is to maximize user retention through gamification (points, VIP, levels) while providing effective learning utilities (library, flashcards).

## User Review Required
> [!IMPORTANT]
> **Ad Strategy**: confirm if `google_mobile_ads` is the preferred provider.
> **Monetization**: `in_app_purchase` package will be needed for VIP/Points purchasing.
> **Backend**: Firestore structure for user profiles (points, vip, progress) needs to be finalized.

## Proposed Architecture & Design

### 1. App Flow & "Game Feel"
**Concept**: Visual distinction between "Game Mode" and "Tool Mode".
-   **Front Page (Home)**:
    -   **Style**: Playful, colorful, "Game Main Menu" vibe. **Theme**: **Low Key Orange & Purple**. Softer, pastel-like gradient (Light Purple + Yellowish Orange) to avoid harsh brightness while maintaining a premium game feel.
    -   **Title**: "Word-Le-Earn" (replacing old WORDLEARN).
    -   **Elements**:
        -   Big "PLAY" button (Central).
        -   User Stats Bar (Avatar, Points, VIP badge).
        -   "Daily Challenge" or "Continue" card.
        -   Navigation points to: Library (Book icon), Shop/Premium (Gem/Star icon), Settings (Gear).
    -   **Persistence**: Automatically saves incomplete game state on exit.
-   **Game Page**:
    -   **Style**: "Premium Bubble" Aesthetic. Circular bubbles, pill-shaped keys, glassmorphism.
    -   **HUD**: Progress bar, Score/Points, Lives/Hearts (optional).
    -   **Power-up Row**: Located **just above the keyboard/input area**. Contains the 'Hint' button and placeholders for future tools (Shuffle, Skip). This integrates the controls naturally rather than having a floating button.
    -   **Feedback**: Juicier animations (Confetti on win, shake on error, sound effects).
-   **Learnt Library**:
    -   **Style**: Cleaner, "Productivity" aesthetic. White/Light card-based layout.
    -   **Function**: Search bar, filter chips (Tags, Levels), List/Grid view.
    -   **New Games**: Flash Card mode, Fill-in-Blank mode.

### 2. Gamification & Logic System
**Logic**:
-   **User Profile**: Managed via `firebase_auth` & `cloud_firestore`.
    -   `points`: Integer. Earned by playing, watching ads, buying.
    -   `isVip`: Boolean/Date. Removes ads, unlocks advanced filters.
    -   `hints`: Integer (Consumable).
-   **Hint Logic (Tiered)**:
    1.  **Hint 1**: Reveal Word Categories.
    2.  **Hint 2** (if word >= 5 chars): Reveal one un-guessed letter.
    3.  **Hint 3** (if word > 8 chars): Reveal 2 random letters OR Synonyms if avail.
    4.  **Final Hint**: Reveal one more letter.
-   **Shuffle Logic**: Acts as "Skip/Swap" for the current word (cost points).

### 3. Ad Strategy
**Implementation**: Using `google_mobile_ads`.
-   **Banner Ads**:
    -   **Placement**: Dynamically sized container between `AppBar` and `Content`.
    -   **Logic**: `if (!isVip) showBanner()`.
    -   **Responsiveness**: Adaptive banner sizes based on `MediaQuery.width`.
-   **Rewarded Ads**:
    -   **Trigger**: "Out of Hints? Watch Video for +3 Hints" or "Double your level reward".
-   **Interstitials (Optional)**: Between levels (frequency capped).

### 4. Content Organization (Data Layer)
**Database**: `sqlite3` (Local).
**Preparation**: Create a `data_ingester.dart` script to pre-populate the DB from JSON assets (`words.json`, `categories.json`).
-   **Schema Enhancements**:
    -   **`Words` Table**: `id`, `word`, `definition`, `difficulty_level` (1-5), `phonetic`.
    -   **`Categories` Table**: `id`, `tag` (e.g., "Fruit", "Noun", "Grade 1"), `type` (Topic, PartOfSpeech, Grade).
    -   **`WordCategories` Table** (Junction): `word_id`, `category_id`. Supports **Multi-Category Tagging** (e.g., "Apple" -> [Fruit, Noun]).
    -   **`Synonyms` Table**: `word_id`, `synonym_text`. Designed for **Thesaurus Gameplay** and **Deep Hints**.
    -   **`UserProgress` Table**: `word_id`, `status` (New, Learnt, Mastered), `next_review_date`, `synonyms_found_count`.
-   **Content Needs**:
    -   **Oxford 3000/5000** lists.
    -   **Specialized Topics**: Animals, Plants, Medical, Science.

### 6. Internationalization (i18n) & Settings
-   **Framework**: Use `flutter_localizations` with `.arb` files.
-   **Requirement**: NO hardcoded strings. All UI text must be localizable.
-   **Supported Languages**: English (`en`), Chinese (Simplified `zh`), Chinese (Traditional `zh_Hant`), French (`fr`), Spanish (`es`).
-   **Settings**:
    -   **Main Language**: Switchable in App Settings.
    -   **Game Logic Settings**:
        -   **Allow Special Characters**: User toggle to allow/disallow words with `-`, `'`, etc.
        -   **Keyboard Adaptation**: Keyboard layout dynamically adds keys (-, ') if setting is ON.

### 7. Responsive UI Design
-   **Landscape Support**: Game Screen must adapt layout (e.g., Side-by-side Board and Keyboard) to prevent overflow on shorter vertical screens.


## Proposed Changes (File Structure)

### Logic Layer
#### [NEW] [gamification_bloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/gamification_bloc.dart)
-   Manages Points, VIP status, Hint consumption.
#### [NEW] [ad_manager](file:///home/sam/Projects/wordlearn/flutter/lib/logic/ad_manager.dart)
-   Central controller for loading and showing ads.
#### [MODIFY] [game_bloc](file:///home/sam/Projects/wordlearn/flutter/lib/logic/game_bloc.dart)
-   Integrate "Points earning" events.
-   Integrate "Tiered Hint" logic.
-   Implement `HydratedBloc` or persistence for saving state on exit.

### UI Layer
#### [MODIFY] [home_screen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/home_screen.dart)
-   Update Title to "Word-Le-Earn".
-   Implement Game Resume card.
#### [MODIFY] [game_screen](file:///home/sam/Projects/wordlearn/flutter/lib/ui/game_screen.dart)
-   Add AdBanner container (Top/Bottom).
-   Add HUD for points/hints.
#### [NEW] [flashcard_mode](file:///home/sam/Projects/wordlearn/flutter/lib/ui/modes/flashcard_game.dart)
-   New game type implementation in Library.

## Verification Plan

### Automated Tests
-   **Unit Tests**:
    -   Test `GamificationBloc`: Points deduction, Hint logic.
    -   Test `AdManager`: Ensure ad requests are not made if `isVip` is true.
-   **Widget Tests**:
    -   Verify Banner Ad container is 0 height when VIP.
    -   Verify Banner Ad container is visible when Guest.

### Manual Verification
1.  **Game Flow**: Play a level, use a hint (check points deduction), win level (check points notification).
2.  **Ads**: Run on emulator/device. Check Banner visibility. Trigger "Watch Ad" and verify reward callback.
3.  **Library**: Add a word, search for it, filter by "Animals".
