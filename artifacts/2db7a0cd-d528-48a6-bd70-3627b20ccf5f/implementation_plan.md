# Database Initialization Plan

## Goal Description
The goal is to populate the application's SQLite database with word lists from JSON files located in `word/src`. This ensures the proper functioning of the `HomeScreen` category selection, which currently fails due to missing data.

## User Review Required
> [!NOTE]
> This plan involves copying a large number of JSON files into the `flutter/assets/words` directory and bundling them with the app. This might increase the app size.

## Proposed Changes

### Configuration
#### [MODIFY] [pubspec.yaml](file:///home/sam/Projects/wordlearn/flutter/pubspec.yaml)
- Add `assets/words/` to the `assets` section.

### Assets
#### [NEW] `flutter/assets/words/*.json`
- Copy all `.json` files from `word/src/` to `flutter/assets/words/`.

### Code Logic
#### [MODIFY] [database_helper.dart](file:///home/sam/Projects/wordlearn/flutter/lib/data/database_helper.dart)
- Import `dart:convert` and `flutter/services.dart`.
- In `_initDatabase`:
    - After table creation, query `words` table count.
    - If count is 0, call a new method `_populateDatabase(db)`.
- Implement `_populateDatabase(Database db)`:
    - Use `AssetManifest` (or `rootBundle`) to find all files in `assets/words/`.
    - Loop through each file:
        - Read content using `rootBundle.loadString`.
        - Parse JSON list of strings.
        - Extract category name from filename (e.g., `grade-1.json` -> `grade-1`).
        - Perform bulk insert into `words` (text, lengths, category).
        - Use a transaction for performance.

## Verification Plan

### Automated Tests
- Run `flutter run` and check the logs (will add logging to `_populateDatabase`).
- Since there are no existing unit tests for `DatabaseHelper` evident in the file list (but I should check `test/`), verification will rely on runtime success.
- I can create a temporary test file `test/database_population_test.dart` to verify that `DatabaseHelper` populates the DB correctly using `sqflite_common_ffi` (for linux/desktop testing) if available, or just rely on manual verification via logs.
- Given the environment, adding a log statement "Database populated with X words" and checking the output is the most practical first step.

### Manual Verification
- Launch the app.
- Check logs for "Database populated".
- Verify that the `DropdownButton` in `home_screen.dart` is populated with categories like `grade-1`, `sat`, etc.
