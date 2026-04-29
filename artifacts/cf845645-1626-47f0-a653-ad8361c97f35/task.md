# Task List

## Completed: Cloud Sync & Schema Refinement
- [x] Verify `CloudSyncService` robustness and error handling <!-- id: 0 -->
- [x] Verify `dev_users` vs `prod_users` separation in practice (by code inspection/test) <!-- id: 1 -->
- [x] Ensure all local data (like `user_progress`) is correctly syncing (bi-directional) <!-- id: 2 -->
- [x] **Refinement**: Ensure explicit timestamp syncing for `user_progress` <!-- id: 76 -->

## Active Task: Gamification & Retention
- [x] **Daily Challenge Logic**: <!-- id: 30 -->
    - [x] **Data Path**: `{collection}/public/daily_word/{YYYY-MM-DD}` (collection = dev_users/prod_users) <!-- id: 51 -->
    - [x] **Logic**: Try fetch. If missing -> Generate 3-5 words -> Create Doc -> Publicize. <!-- id: 31 -->
    - [x] **Persistence**: Track user completion locally and synced in user_progress <!-- id: 45 -->
    - [x] **Global Stats**: Track attempts, successes, failures in the daily doc <!-- id: 56 -->
    - [x] **Bug Fix**: Stats showing 0 solved despite wins. (Re-opened: User reports still failing) <!-- id: 77 -->
    - [x] **UI Fix**: Fix overflow in "Today's Words" card play button <!-- id: 78 -->
- [ ] **Social & Growth** <!-- id: 33 -->
    - [x] **Feature**: Daily Reminder Notification for new challenge <!-- id: 79 -->
- [ ] **VIP Logic**: <!-- id: 32 -->
    - [ ] Remove hardcoded `const isVip = true` <!-- id: 47 -->
    - [ ] Restrict features (e.g. Custom Words, Notes) based on VIP status <!-- id: 48 -->
    - [ ] Show/Hide Ads based on VIP status <!-- id: 49 -->
- [ ] **XP System**: <!-- id: 12 -->
    - [ ] Ensure XP updates are displayed correctly and animated <!-- id: 50 -->

## Core Infrastructure & Game Logic (Backlog)
- [ ] **Retry System**: Option to spend points to retry a failed game <!-- id: 3 -->
- [ ] **Smart Hint Masking**: <!-- id: 41 -->
    - [ ] Logic: Check similarity (>80%) between hint/definition and target word <!-- id: 42 -->
    - [ ] Action: Mask target word in hint (e.g. "To ___ fast") if too similar <!-- id: 43 -->
    - [ ] Scope: Main Game (Wordle) and Mini Games (Anagrams, etc.) <!-- id: 44 -->
- [ ] **Content Expansion**: Add categories (Animals, Plants, Flowers, etc.) and Advanced Data (Synonyms, Antonyms) <!-- id: 4 -->
- [ ] **Content Localization**: Translation of word lists/definitions <!-- id: 5 -->

## UI/UX Refinements (New Requirements)
- [x] **Cross-board App Bar**:
    - [x] Sync User Icon with logged-in user's profile picture <!-- id: 16 -->
    - [x] Make VIP Mode indicator clickable (Open Login/Logout dialog) <!-- id: 17 -->
    - [x] Update User Profile to include VIP status <!-- id: 18 -->
- [x] **Main Screen Title**:
    - [x] Use App Icon + "Word-Le-Arn" text <!-- id: 19 -->
    - [x] specific font size/scaling to ensure one-line fit (always) <!-- id: 20 -->
- [x] **Landscape Mode**: Fix vertical overflow in Game Screen <!-- id: 21 -->

## Social & Growth
- [ ] **Deep Linking Share**:
    - [ ] Share game with deep link (Firebase Dynamic Links or equivalent) <!-- id: 22 -->
    - [ ] Behavior: Open app to specific word if installed; redirect to Store if not <!-- id: 23 -->
- [ ] **Friend System**: <!-- id: 52 -->
    - [ ] **Add Friends**: User search/invite system <!-- id: 53 -->
    - [ ] **Status**: See if friends are online/playing <!-- id: 54 -->
    - [ ] **Social**: Chat and "Play Together" (Real-time multiplayer) <!-- id: 55 -->

## Content & Features
- [x] **Learnt Word Details Expansion**:
    - [x] Display meanings and synonyms <!-- id: 24 -->
    - [x] **VIP Feature**: Allow adding new words <!-- id: 25 -->
    - [x] **VIP Feature**: Allow adding personal notes (up to ~250 words) <!-- id: 26 -->
- [x] **Library Improvements**:
    - [x] Implement text search/filter for learnt words <!-- id: 28 -->

## Mini Word Games
- [x] **Anagram / Scramble Game** (MVP):
    - [x] Game Logic (Scramble word, validate guess) <!-- id: 27 -->
    - [x] UI Implementation <!-- id: 29 -->
    - [x] Reward System (Points/Diamonds) <!-- id: 30 -->
    - [x] **Hints System** (Reveal letter) <!-- id: 31 -->
    - [x] **Integration**: Add word to Learnt Library <!-- id: 32 -->
    - [x] **Refactor**: Centralize Economy/Price Logic <!-- id: 33 -->
    - [x] **Fix**: Ensure Settings (Category/Length) are respected <!-- id: 34 -->
    - [x] **UI**: Reuse Global Diamond/Points Widget (with Shop/Ads) <!-- id: 35 -->
    - [x] **Economy**: Implement Cost for Hints (5 Diamonds) <!-- id: 36 -->
    - [x] **Refinement**: Verify Hints Logic (Wordle-style) <!-- id: 71 -->
    - [x] **Feature**: Bonus Reward (1 Diamond) for valid non-target words <!-- id: 75 -->
- [x] **Flashcards mode** <!-- id: 28 -->
    - [x] **Logic**: Fetch definitions/distractors, Quiz Engine (`FlashcardsBloc`) <!-- id: 64 -->
    - [x] **UI**: Question Card + 4 Option Buttons <!-- id: 65 -->
    - [x] **Integration**: Use `MiniGameScreen` standards (Header, Diamonds) <!-- id: 66 -->
    - [x] **Standardization**: Clickable Title, Respect Global Settings <!-- id: 69 -->
    - [x] **Refinement**: Interactive Review (Tap words after answer) <!-- id: 72 -->
- [x] **Spelling Bee** <!-- id: 29 -->
    - [x] **Logic**: TTS Integration (`flutter_tts`), Input Validation (`SpellingBeeBloc`) <!-- id: 67 -->
    - [x] **UI**: Audio Controls, Input Field, Hints (Definition/Letter) <!-- id: 68 -->
    - [x] **Standardization**: Clickable Title, Respect Global Settings <!-- id: 70 -->
    - [x] **Refinement**: Add Hints System (Definition + Reveal Letter) <!-- id: 73 -->
- [x] **Wordament** (Grid Search): <!-- id: 37 -->
    - [x] **Logic**: 4x4 Grid Generation, Word Validation, DFS Path Finding <!-- id: 38 -->
    - [x] **UI**: Draggable/Swipe Selection, Timer, Found Words List <!-- id: 39 -->
    - [x] **Integration**: Scoring, Add found words to Library <!-- id: 40 -->
    - [x] **Refinement**: Difficulty Tuning (Common words only) <!-- id: 74 -->
- [x] **Mini Game Standardization**: <!-- id: 59 -->
    - [x] **Title Bar**: Clickable for info <!-- id: 60 -->
    - [x] **Consistency**: Respect global categories/length (where applicable) <!-- id: 61 -->
    - [x] **UI**: Standardize App Bar diamonds, Hint styles <!-- id: 62 -->
    - [x] **Features**: Add to library, Allow revival (spending points) <!-- id: 63 -->


## UI/UX Implementation (Backlog)
- [x] **Shop Screen**: Implement the Shop Screen (currently placeholder) <!-- id: 6 -->
- [ ] **Tutorial/Onboarding**: Guide for new users <!-- id: 7 -->
- [ ] **Game Power-Ups**: Implement "Shuffle" button logic <!-- id: 8 -->

## Monetization (Backlog)
- [ ] **AdMob Banner**: Add banners to Game Screen and Word Detail <!-- id: 9 -->
- [ ] **IAP Integrated**: Store integration, Products (Point Packs), VIP Status <!-- id: 10 -->


## Polish & Platform Specifics
- [ ] **Sound Assets**: Verify success/fail/error sounds exist <!-- id: 13 -->
- [ ] **Linux Build**: Verify build stability <!-- id: 14 -->

## Hybrid Architecture (Future)
- [ ] **Dual-Mode Build**: Local vs API Mode <!-- id: 15 -->
