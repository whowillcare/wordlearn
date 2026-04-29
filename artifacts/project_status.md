# WordLearn Project Status

This document serves as the central entry point for the project's current state, synthesizing the history and unfinished tasks from all previous planning and implementation sessions.

> **Note to AI Agents:** The user has requested that all future planning, thinking, and artifacts be kept within this `artifacts/` directory. Be sure to read the artifacts grouped by their unique conversation IDs when needing historical context, and update this `project_status.md` file as work progresses.

## 🚀 In Progress / Immediate Bugs
- **Authentication:** Resolve Google Sign-In `null` token error and `SecurityException: Unknown calling package name 'com.google.android.gms'`.
- **Firebase/Cloud Sync:** Fix permission issues or query construction for `CloudSyncService` and ensure "learnt words" sync correctly.
- **Database Population:** Finalize database population logic from `word/src` JSON files.

## 📋 Pending Features & Enhancements

### Social & Growth
- **Friend System:** Add users, see online/playing status, and implement "Play Together" (real-time multiplayer chat/gameplay).
- **Deep Linking:** Share games with deep links (Firebase Dynamic Links); open the app to a specific word if installed or redirect to the store if not.

### Game Mechanics & Power-ups
- **Retry System:** Allow users to spend points to retry a failed game.
- **Smart Hint Masking:** Compare similarity (>80%) between a hint/definition and the target word. Mask the target word in the hint (e.g., "To ___ fast") if they are too similar.
- **Power-Ups:** Implement "Shuffle" button logic in the Game Screen.

### Progression & Monetization
- **VIP Logic:** Remove hardcoded `isVip = true`, restrict specific features (e.g., Custom Words, Notes), and show/hide ads based on VIP status.
- **XP System:** Ensure XP updates are animated and displayed correctly.
- **Monetization (IAP):** Integrate the `in_app_purchase` package to sell Point Packs and VIP Status. Add AdMob banners to the Game Screen and Word Detail views.

### Content & Localization
- **Data Expansion:** Add new categories (Animals, Plants, Flowers, etc.) and advanced language data (Synonyms, Antonyms).
- **Localization:** Translate word lists and definitions.

### Tech Debt & Build Infrastructure
- **Dual-Mode Build Option:** Support Local Mode (offline independent SQLite database) versus API Mode (Thin client leveraging a remote REST API).
- **Linux Build:** Verify build stability and ensure GStreamer dependencies (`libgstreamer1.0-dev`) are handled.
- **Sound Assets:** Verify that `success.wav`, `fail.wav`, and `error.wav` exist and load correctly.

## 📂 Architecture & Historical Context
Previous plans, walkthroughs, and tasks are organized in subdirectories by their conversation IDs. When starting work on a major component (like Cloud Sync, GameBloc logic, or VIP features), consult the respective subfolder for deeper context on previously established architectural decisions.
