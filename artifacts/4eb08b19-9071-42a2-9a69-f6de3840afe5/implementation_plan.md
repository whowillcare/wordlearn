# Migrate SQLite Cache to SharedPreferences for Web Compatibility

This refactors the stock candle caching from SQLite (`sqflite`) to SharedPreferences, enabling web platform support.

## Proposed Changes

### Data Layer

#### [MODIFY] [stock_cache.dart](file:///home/sam/Projects/stocks/lib/data/stock_cache.dart)
Replace `stock_database.dart` with a new `stock_cache.dart` that uses SharedPreferences:
- Store candles as JSON strings with key pattern `cache_candles_{symbol}`
- Add `getCandles(symbol)` and `insertCandles(symbol, candles)` methods
- Serialize/deserialize `List<Candle>` to/from JSON

#### [MODIFY] [repository.dart](file:///home/sam/Projects/stocks/lib/data/repository.dart)
- Replace `StockDatabase` dependency with new `StockCache`
- Update method calls to use the new cache interface

#### [DELETE] [stock_database.dart](file:///home/sam/Projects/stocks/lib/data/stock_database.dart)
Remove the SQLite-based database file (no longer needed)

---

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///home/sam/Projects/stocks/pubspec.yaml)
- Remove `sqflite: ^2.4.2`
- Remove `sqflite_common_ffi: ^2.3.6`
- Remove `path: ^1.9.1` (only used for SQLite path)
- Keep `shared_preferences: ^2.5.4` (already present)

---

## Verification Plan

### Automated Tests
```bash
# Run existing tests to ensure no regressions
flutter test
```

### Manual Verification
1. Run the app with `flutter run -d linux` (or `flutter run -d chrome` for web)
2. Search for a stock symbol (e.g., "AAPL")
3. Verify data loads and displays correctly
4. Close and restart the app
5. Verify cached data persists (symbol should load without network if cache exists)
6. Click refresh button to force-fetch new data
7. Verify tooltip shows "Last refreshed" timestamp updates

### Web Platform Test (primary goal)
```bash
# Test web build compiles without SQLite errors
flutter run -d chrome
```
