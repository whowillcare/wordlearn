# Advanced Trading Logic Integration Plan

## Overview

Integrate POC trading logic from `poc.dart` into existing `strategy.dart` and `trend_analyzer.dart` to create a comprehensive trading system meeting all requirements.

## Current State Analysis

### Existing Features ✅
- **Trend Detection**: Basic EMA-based trend classification
- **Entry Risk**: Safe entry range using ATR
- **Stop Loss**: Dual ATR calculation (historical for cut loss, current for trailing)
- **Volume Analysis**: Basic volume spike detection
- **Risk Scoring**: Distance-based risk assessment

### Missing Features ❌

1. **Higher High/Higher Low Structure Detection**
2. **Post-Entry Trend Confirmation**
3. **Failed Confirmation Handling**
4. **Breakout Detection** (20-day high)
5. **Position Sizing Calculations**
6. **Maximum Hold Time Rules**
7. **Breakeven Stop Movement**
8. **Partial Profit Taking Logic**
9. **Gap Risk Handling**
10. **Multiple Timeframe Confirmation** (future enhancement)

## Proposed Architecture

###[strategy.dart](file:///home/sam/Projects/stocks/lib/domain/strategy/strategy.dart)

**New Classes:**
- `TradeState`: Enum for trade lifecycle (NOT_ENTERED, WAITING_CONFIRMATION, CONFIRMED, FAILED)
- `PostEntryAnalysis`: Result class tracking confirmation status
- `PositionSizingCalculator`: Helper for risk-based position sizing

**Enhanced `StrategyResult`:**
```dart
class StrategyResult {
  // Existing
  final double cutLossPrice;
  final double? trailingStopPrice;
  final String equation;
  
  // NEW: Post-entry monitoring
  final TradeState tradeState;
  final int daysHeld; // Days since entry
  final bool confirmationPassed;
  final bool confirmationFailed;
  final String confirmationNote;
  
  // NEW: Entry analysis
  final bool canEnter;
  final String entryReason; // Why entry is safe/unsafe
  final double suggestedPositionSize;
  
  // NEW: Profit management
  final bool moveToBreakeven;
  final double? partialProfitTarget;
}
```

**Enhanced `AtrStopStrategy`:**
- Add `analyzePostEntry()` method
- Add `checkConfirmation()` method
- Integrate HH/HL structure detection
- Add breakout detection
- Add position sizing
- Add max hold time check

### [trend_analyzer.dart](file:///home/sam/Projects/stocks/lib/domain/analysis/trend_analyzer.dart)

**Enhancements:**
- Add `detectHigherHighsLows()` from POC
- Add `detectBreakout()` method
- Add `analyzeStructure()` for swing point analysis
- Enhanced volume confirmation (not just spike, but pattern)
- Add sideways duration tracking

**New Methods:**
```dart
class TrendAnalyzer {
  // Enhanced structure detection
  StructureAnalysis analyzeSwingStructure(List<Candle> candles, {int lookback});
  
  // Breakout detection
  bool detectBreakout(List<Candle> candles, {int period});
  
  // Post-entry monitoring
  ConfirmationStatus checkPostEntryConfirmation(
    List<Candle> candles,
    DateTime entryDate,
    double entryPrice,
  );
}
```

## Implementation Steps

### Step 1: Update Data Models

**File:** [stock_data.dart](file:///home/sam/Projects/stocks/lib/model/stock_data.dart)

- Add `TradeState` enum
- Enhance `StrategyResult` class
- Add `PostEntryAnalysis` class
- Add `StructureAnalysis` class

### Step 2: Implement Structure Detection

**File:** [trend_analyzer.dart](file:///home/sam/Projects/stocks/lib/domain/analysis/trend_analyzer.dart)

- Port `detectHigherHighsLows()` from POC
- Implement `analyzeSwingStructure()`
- Implement `detectBreakout()`
- Add swing point detection (local peaks/troughs)

### Step 3: Enhance AT

R Strategy

**File:** [strategy.dart](file:///home/sam/Projects/stocks/lib/domain/strategy/strategy.dart)

#### 3.1 Pre-Entry Analysis
- Integrate structure check
- Add breakout confirmation
- Add position sizing calculator
- Enhanced "can enter" logic

#### 3.2 Post-Entry Monitoring
- `analyzePostEntry()`: Check if confirmation passed/failed/waiting
- Track days since entry
- Monitor structure integrity
- Check for failure patterns

#### 3.3 Profit Management
- Add breakeven stop logic (when price moves > 1R)
- Add partial profit targets
- Enhanced trailing stop activation

### Step 4: Integration Points

**Provider Updates:** [home_provider.dart](file:///home/sam/Projects/stocks/lib/ui/home_provider.dart)
- Pass `entryDate` and `entryPrice` to enhanced calculations
- Store `tradeState` in session
- Handle post-entry analysis results

**UI Updates:** [home_screen.dart](file:///home/sam/Projects/stocks/lib/ui/home_screen.dart)
- Display trade state (waiting confirmation / confirmed / failed)
- Show days held counter
- Show position sizing suggestion
- Display confirmation status
- Show breakeven/partial profit indicators

## Detailed Feature Specifications

### 1. Higher High/Higher Low Detection

```dart
bool _detectHigherHighsLows(List<Candle> candles, {int lookback = 30}) {
  // Find local peaks and troughs
  // Check if last 3 peaks are ascending
  // Check if last 3 troughs are ascending
  // Return true if both conditions met
}
```

### 2. Post-Entry Confirmation

**Wait Period:** 3-7 trading days after entry

**Confirmation Criteria:**
- Price stays above EMA20 (for uptrend)
- No break of previous swing low
- ATR not expanding downward
- Structure remains intact (no lower high)

**States:**
- `WAITING_CONFIRMATION`: < 7 days, structure intact
- `CONFIRMED`: Breakout or sustained strength
- `FAILED`: Structure broken, price below swing low

### 3. Position Sizing

```dart
double calculatePositionSize({
  required double accountSize,
  required double riskPercentage, // e.g., 0.02 for 2%
  required double entryPrice,
  required double stopLoss,
}) {
  final riskAmount = accountSize * riskPercentage;
  final priceRisk = entryPrice - stopLoss;
  return riskAmount / priceRisk; // shares to buy
}
```

### 4. Maximum Hold Time

- Track `daysHeld` since entry
- If > 15-20 days without confirmation → suggest exit
- Display warning in UI

### 5. Breakeven Stop

- When price > entry + 1*ATR (or 1R reward)
- Move stop to entry price
- Display "Breakeven Mode" in UI

## Testing Strategy

1. **Unit Tests**: Individual methods (structure detection, breakout, etc.)
2. **Integration Tests**: Full workflow from entry analysis to post-entry
3. **Manual Testing**: Real stock data scenarios

## Migration Notes

- Existing sessions will need `tradeState` initialized to `NOT_ENTERED`
- POC file `poc.dart` can remain as reference/alternative implementation
- No breaking changes to existing stop price calculations

## Timeline Estimate

- Data models: 1 task
- Structure detection: 1 task  
- Strategy enhancements: 2 tasks
- Provider/UI integration: 1 task
- Testing: 1 task

Total: ~6 implementation tasks
