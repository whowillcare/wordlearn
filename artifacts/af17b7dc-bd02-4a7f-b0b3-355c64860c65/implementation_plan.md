# Implementation Plan - Advanced Settings & Features

## Goal Description
Enhance the application with global strategy selection, risk management rules (Max Holding Days), improved event log navigation, and customizable external URL references for stocks.

## User Review Required
> [!IMPORTANT]
> - **Global Strategy**: The strategy selected in Global Settings will be applied to ALL sessions unless we keep per-session overrides. Assuming Global is the default/driver.
> - **Max Holding Logic**: "Update the entry's hold day" - Interpret this as updating the content of the latest "Max Holding Warning" event if it exists, otherwise creating one.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///home/sam/Projects/stocks/pubspec.yaml)
- Add `url_launcher` for opening external links.

### Data Layer & State
#### [MODIFY] [home_provider.dart](file:///home/sam/Projects/stocks/lib/ui/home_provider.dart)
- **New Settings**:
    - `globalStrategyName` (String): 'ATR' or 'EMA'.
    - `maxHoldingDays` (int): default 20.
    - `urlTemplates` (String): Multi-line string for URL templates.
- **Methods**:
    - `updateGlobalStrategySettings(...)`: Combined update method.
    - `saveGlobalSettings()` / `loadSessions()`: Persist new fields.
    - `refreshAllSessions()`: Add check for `daysHeld > maxHoldingDays`.
        - Logic: If exceeded, check last event. If it's a "Max Holding" warning, update it. Else, add new event.
- **Strategy Application**:
    - Ensure new sessions use the `globalStrategyName` to pick the strategy implementation.

### UI Components
#### [MODIFY] [home_screen.dart](file:///home/sam/Projects/stocks/lib/ui/home_screen.dart)
- **Refactor**: Extract `_SessionView` (or similar) to be a public `SessionView` class (possibly in new file or just public) so `EventLogScreen` can use it.
- **Settings Dialog**:
    - Add **Strategy Selector** (Dropdown).
    - Conditionally show ATR/EMA params based on selection.
    - Add **Max Holding Days** input.
    - Add **URL Templates** Multi-line TextField.
- **Session View**:
    - Add "Link" Icon Button.
    - On click, parse `urlTemplates` (split by newline), replace `{symbol}`.
    - If 1 URL: Launch.
    - If >1 URL: Show PopupMenu to choose.

#### [MODIFY] [event_log_screen.dart](file:///home/sam/Projects/stocks/lib/ui/event_log_screen.dart)
- **Navigation**:
    - On `ExpansionTile` header tap (Double tap or Icon), navigate to `SessionView` for that symbol.
    - Requires `HomeProvider` to find the correct `StockSession` object.

## Verification Plan
### Manual Verification
1.  **Settings**: Change Strategy to EMA. Verify UI updates. Verify new sessions use EMA.
2.  **Max Holding**: Set Max Holding to 1 day. Check a stock held > 1 day. Click Refresh. Verify "Max Holding" event appears/updates.
3.  **Event Nav**: Go to Event Log. Tap a symbol. Verify it opens the Session details.
4.  **URLs**: Add `https://google.com/search?q={symbol}`. Save. Go to session. Click Link icon. Verify browser opens.
