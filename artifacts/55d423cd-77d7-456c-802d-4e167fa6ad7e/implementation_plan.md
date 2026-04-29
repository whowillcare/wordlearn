# Refine UI Layout

The goal is to streamline the UI by moving the grouped view toggle to the top bar and replacing the bulky strategy card with a compact info button.

## User Review Required
None.

## Proposed Changes

### UI
#### [MODIFY] [home_screen.dart](file:///home/sam/Projects/stocks/lib/ui/home_screen.dart)
1.  **AppBar Title**:
    -   Replace `Text('Stock Analyzer')` with the `SegmentedButton`.
    -   Wrap it in a `FittedBox` or `SingleChildScrollView(scrollDirection: Axis.horizontal)` to handle overflow on small screens involved with the buttons.
    -   Styles: `ButtonStyle(visualDensity: VisualDensity.compact)`.

2.  **AppBar Bottom**:
    -   Remove the `SegmentedButton` from the `bottom` widget `Column`.
    -   Keep the `TabBar` (and the `Add` button row) in the `bottom` slot.
    -   Adjust `preferredSize`.

3.  **Strategy Info**:
    -   Remove `_buildStrategyConfig` method call in `SessionView`.
    -   Remove the method definition itself.

4.  **Cut Loss Header**:
    -   In `_buildResults`, find the "Cut Loss" Text.
    -   Replace with a `Row`:
        -   Text "Cut Loss"
        -   `IconButton(icon: Icon(Icons.info_outline))`
        -   `tooltip`: Build a string based on `provider.globalStrategyName` and params.
        -   `onPressed`: Call `_showGlobalSettingsDialog`.

## Verification Plan
1.  Run app.
2.  Verify `Watchlist | Portfolio` toggle is in the App Bar title area.
3.  Verify the bulky Strategy Card is gone.
4.  Verify an Info icon exists next to "Cut Loss".
5.  Long press Info icon -> Check tooltip (e.g. "ATR Strategy: Period 14...").
6.  Tap Info icon -> Should open Global Settings dialog.
