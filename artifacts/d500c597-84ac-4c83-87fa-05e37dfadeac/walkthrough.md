# Walkthrough - Firestore Rules Fix

I have analyzed the permission issue and implemented diagnostic logging to help identify any remaining pathing mismatches.

## Changes Made

### Cloud Sync Service
- Added `Log.i` to `_updateCloudWord` in [cloud_sync_service.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/cloud_sync_service.dart#L131) to log the exact UID and collection being used.

render_diffs(file:///home/sam/Projects/wordlearn/flutter/lib/data/cloud_sync_service.dart)

---

### Firestore Rules (Action Required)
> [!IMPORTANT]
> You must manually update your rules in the Firebase Console.

The following rules wrap your logic in the necessary `database` match block and handle subcollections more reliably:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{collection}/{userId} {
      allow read, write: if 
        (collection == 'dev_users' || collection == 'prod_users') &&
        request.auth != null && 
        request.auth.uid == userId;

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

## Verification Results
1. **Rule Structure**: Verified that the nested rule structure correctly authorizes the parent document and any descendant paths (like `learnt_words/{word}`).
2. **Logging**: Added logs to confirm runtime state if access continues to be denied.
