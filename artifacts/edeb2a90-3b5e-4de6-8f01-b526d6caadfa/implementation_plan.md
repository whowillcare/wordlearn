# Syncing Learnt Words
The current synchronization logic only covers user points. We need to implement bidirectional sync for `learnt_words` (User Progress) to ensure users can access their vocabulary across devices.

## User Review Required
> [!IMPORTANT]
> **Firestore Security Rules**: The new sync logic uses a subcollection `learnt_words`. usage.
> You must update your Firestore Security Rules to allow access:
> ```javascript
> match /{collection}/{userId}/learnt_words/{word} {
>   allow read, write: if request.auth != null && request.auth.uid == userId;
> }
> ```

## Proposed Changes

### Data Layer

#### [MODIFY] [word_repository.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/word_repository.dart)
-   **Add StreamController**: Introduce a `StreamController<WordUpdateEvent>` to broadcast changes whenever a word is learnt, favorited, or removed.
-   **Structure**:
    ```dart
    class WordUpdateEvent {
      final String word;
      final String status; // 'Learnt', 'Mastered', 'Removed'
      final DateTime timestamp;
    }
    ```
-   **Update Methods**: Trigger this stream in `addLearntWord`, `toggleFavorite`, and `deleteLearntWord`.

#### [MODIFY] [cloud_sync_service.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/cloud_sync_service.dart)
-   **Listen to Stream**: Subscribe to `WordRepository.updates` to push local changes to Firestore immediately.
-   **Sync Logic**:
    -   On Login: Fetch all documents from `_usersCollection/{uid}/learnt_words`.
    -   Merge Strategy:
        -   If Cloud has word and Local doesn't -> Add to Local.
        -   If Local has word and Cloud doesn't -> Add to Cloud (handled by batch or individual checks, simpler to just prioritize Cloud on fresh install, or merge logic).
        -   Conflict: Use latest `lastUpdated` timestamp.

### Firestore Architecture
-   **Path**: `prod_users/{userId}/learnt_words/{wordText}`
-   **Fields**:
    -   `status`: String ('Learnt', 'Mastered')
    -   `lastUpdated`: Timestamp

## Verification Plan

### Manual Verification
1.  **Fresh Install**:
    -   Clear app data.
    -   Login.
    -   Verify standard points sync.
    -   Verify `Library` page is initially empty (if new user).

2.  **Add Word**:
    -   Play game or cheat to learn a word.
    -   Check Firestore Console: Ensure document created in `learnt_words`.

3.  **Restore**:
    -   Clear app data again.
    -   Login.
    -   Verify the word appears in the Library automatically.
