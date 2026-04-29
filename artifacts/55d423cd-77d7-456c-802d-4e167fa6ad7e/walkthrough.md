# Event Log Grouping, Navigation, & Session Organization - Walkthrough

Major updates include grouping the Event Log, smarter navigation, in-app WebView, and a new Portfolio/Watchlist separation for sessions.

## Changes

### 1. Grouping Logic (Event Log)
-   Events are grouped by **Symbol**.
-   Symbols are sorted into **Today**, **Yesterday**, and **Older** buckets based on the latest event.

### 2. Smart Navigation
-   Clicking a notification checks if the **Event Log** is open to avoid duplicates.

### 3. In-App WebView
-   External links open in an integrated **WebView** instead of an external browser.

### 4. Portfolio vs. Watchlist
-   **Sessions** are now split into two views:
    -   **Watchlist**: Default for new symbols (no entry info).
    -   **Portfolio**: Symbols with an `Entry Date` AND `Entry Price`.
-   **Toggle**: Use the toggle button in the **AppBar Title** to switch views.
-   **Auto-Sort**:
    -   Adding entry info to a Watchlist item automatically moves it to **Portfolio**.
    -   Removing entry info moves it back to **Watchlist**.
    -   The app automatically switches the view so you don't lose track of the item you are editing.
-   **UI Refinements**:
    -   Strategy Info Card has been removed.
    -   Strategy details are now available via an **Info Button** next to the "Cut Loss" header. Clicking it opens Global Settings.

## Verification Steps

1.  **Session Grouping**:
    -   Add a new session (e.g. 'GOOG'). It appears in **Watchlist**.
    -   Enter an Entry Price/Date. It disappears from Watchlist and the view switches to **Portfolio**.
    -   Remove the Entry Price. It matches back to **Watchlist**.
    -   Test the toggle in the AppBar title.
    -   Click the Info icon next to "Cut Loss" to confirm Global Settings opens.
