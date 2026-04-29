# Debug Firestore Rules Access

The user is experiencing permission issues in `_updateCloudWord`. This plan addresses the most likely cause (Firestore rule structure) and adds logging to verify the state if issues persist.

## User Review Required

> [!IMPORTANT]
> The proposed Firestore rules assume you want to allow users access to their own document within `dev_users` or `prod_users` and all data nested under that document. 

> [!WARNING]
> Please ensure you replace **ALL** existing rules in the Firebase Console with this version, as missing the `match /databases/{database}/documents` wrapper is a common cause of "no rules matching" errors.

## Proposed Changes

### Firestore Rules (Copy to Firebase Console)

The current rule pattern `match /{collection}/{userId}/{document=**}` is technically valid in Version 2 but can be cleaner and more robust when nested. More importantly, it **must** be wrapped in the standard Firestore boilerplate.

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Match any document in the user-specific collection
    match /{collection}/{userId} {
      // Rule for the user document itself (e.g., dev_users/UID)
      allow read, write: if 
        (collection == 'dev_users' || collection == 'prod_users') &&
        request.auth != null && 
        request.auth.uid == userId;

      // Rule for all subcollections (e.g., dev_users/UID/learnt_words/APPLE)
      match /{allPaths=**} {
        allow read, write: if 
          (collection == 'dev_users' || collection == 'prod_users') &&
          request.auth != null && 
          request.auth.uid == userId;
      }
    }
  }
}
```

---

### Cloud Sync Service

#### [MODIFY] [cloud_sync_service.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/cloud_sync_service.dart)

Add more descriptive logging to help verify the exact path and UID being used during failures.

```diff
   Future<void> _updateCloudWord(String uid, WordUpdateEvent event) async {
     try {
       final docRef = _firestore
           .collection(_usersCollection)
           .doc(uid)
           .collection('learnt_words')
           .doc(event.word);
+      Log.i("Cloud Sync: Syncing word '${event.word}' for UID: $uid in $_usersCollection");
 
       if (event.status == 'Deleted') {
         await docRef.delete();
```

## Verification Plan

### Manual Verification
1. **Update Firebase Console**: Copy the proposed rules into the Firebase Console -> Firestore -> Rules tab.
2. **Restart App**: Run `flutter run` again.
3. **Trigger Update**: Perform an action in the app that triggers a word update (e.g., mark a word as learnt).
4. **Check Logs**: Verify if `Log.i` shows "Cloud Sync: Updated word..." or if a "Cloud Word Sync Error" with "Permission Denied" still appears.
5. **Verify in Console**: Check the Firestore data browser to see if the document was created at `(dev|prod)_users/{uid}/learnt_words/{word}`.
