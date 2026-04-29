# Stock Analysis App Implementation Plan (Enhancements)

## Goal Description
Enhance the existing stock analysis app with:
- **Manual Data Refresh**: Override cache to get latest data.
- **Multi-tab Support**: Analyze multiple stocks simultaneously.
- **Detailed Results**: Show calculation equation and data timestamp.
- **Symbol Autocomplete**: Search candidates via backend API.

## Proposed Changes

### Data Layer
#### [MODIFY] [lib/data/repository.dart](file:///home/sam/Projects/stocks/lib/data/repository.dart)
- Update `getStockData` to accept `bool forceRefresh`.
- If `forceRefresh` is true, fetch from API regardless of cache.

#### [MODIFY] [lib/data/yahoo_api.dart](file:///home/sam/Projects/stocks/lib/data/yahoo_api.dart)
- specific `fetchChartData` to support `forceRefresh` (API logic remains same, but repository controls it).
- **[NEW]** `searchSymbols(String query)`: Call Yahoo Finance V1 search API (`https://query1.finance.yahoo.com/v1/finance/search?q=...`) to get candidates.

### Business Logic
#### [MODIFY] [lib/domain/strategy/strategy.dart](file:///home/sam/Projects/stocks/lib/domain/strategy/strategy.dart)
- Add `String get equation` getter to `StopStrategy`.
- return descriptive equation (e.g. "Close (102.00) - 3.0 * ATR (5.00) = 87.00").

#### [MODIFY] [lib/ui/home_provider.dart](file:///home/sam/Projects/stocks/lib/ui/home_provider.dart)
- Refactor to support list of active "Sessions" or "Tabs".
- Each tab maintains its own `StockSymbol`, `Strategy` params, etc.
- Or, simplify: `HomeProvider` manages a list of `StockSession` objects.
- Add `searchCandidates(String query)` method.

### Presentation Layer
#### [MODIFY] [lib/ui/home_screen.dart](file:///home/sam/Projects/stocks/lib/ui/home_screen.dart)
- Replace main content with `TabBar` and `TabBarView`.
- Add generic `Autocomplete<StockSearchResult>` widget for stock input.
- Add "Refresh" Icon Button.
- Update Result Card to show:
    - Timestamp of last candle.
    - Strategy Equation.

## Verification Plan
### Manual Verification
1. **Refresh**: Load stock, wait, click refresh. Verify network call (log) or updated data.
2. **Tabs**: Open AAPL, click new tab (+), open TSLA. Switch between tabs. Verify state preserved.
3. **Equation**: Check text in result card matches expected calculation.
4. **Autocomplete**: Type "TES", verify "TSLA - Tesla Inc" appears in candidates.
