# Fix Build Errors in Stocks App

- [x] Analyze and fix missing `activity_model.dart` import <!-- id: 0 -->
- [x] Define or import `StockSearchResult` class <!-- id: 1 -->
- [x] Define or import `Candle` class <!-- id: 2 -->
- [x] Fix missing `max` import in `strategy.dart` <!-- id: 3 -->
- [x] Verify build <!-- id: 4 -->

# New Requirements
- [x] Implement Persistence (Save/Load Sessions) <!-- id: 5 -->
- [x] Update `StockSession` model (Entry Date/Price, JSON serialization) <!-- id: 6 -->
- [x] Update `Strategy` logic (Trailing Stop from Entry High) <!-- id: 7 -->
- [x] Update UI (Entry inputs, Persistence hooks) <!-- id: 8 -->
- [x] Verify Changes <!-- id: 9 -->

# Dual Price & Chart Features
- [x] Logic: Update `StockSession` and `Strategy` for Dual Prices <!-- id: 10 -->
- [x] Logic: Update `HomeProvider` to handle new Strategy Result <!-- id: 11 -->
- [x] UI: Add Dual Price Display in `HomeScreen` <!-- id: 12 -->
- [x] UI: Add Chart Maximize/Minimize Controls <!-- id: 13 -->
- [x] UI: Implement Chart Indicator Overlay (EMA/Stop Line) <!-- id: 14 -->
- [x] Verify Updates <!-- id: 15 -->
- [x] Fix Screen Scroll Overflow (RenderFlex error) <!-- id: 16 -->
- [x] Fix Runtime Error (TabController Scaffold Error) <!-- id: 17 -->
- [x] Fix Layout Error (Intrinsic Dimensions) <!-- id: 18 -->

# Logic Updates
- [x] Implement Trading Hours Logic for Cut Loss <!-- id: 19 -->
- [x] Verify Trading Hours Logic <!-- id: 20 -->

# Layout & Features
- [x] Global Strategy: Move Config to Global Provider <!-- id: 21 -->
- [x] UI: Implement Global Settings Dialog <!-- id: 22 -->
- [x] Logic: Implement Search History (Persistence) <!-- id: 23 -->
- [x] UI: Add History Dropdown to Add Button <!-- id: 24 -->
- [x] Chart: Switch to Syncfusion Charts for EMA Lines <!-- id: 25 -->
- [x] Chart: Fix Interaction (Zoom/Pan/MouseWheel) <!-- id: 27 -->
- [x] Chart: Persist Zoom Level (Default 90 days) <!-- id: 28 -->
- [x] Logic: Update Cut Loss Calculation (Entry Date Base) <!-- id: 29 -->
- [x] UI: Chart Tooltip with Date <!-- id: 30 -->
- [x] Logic: Implement Trend/Risk Analysis & Scoring <!-- id: 31 -->
- [x] UI: Configurable Risk Scores (Global Settings) <!-- id: 32 -->
- [x] UI: Display Trend & Risk Level in Results <!-- id: 33 -->
- [x] UI: Refine Chart Tooltip Layout (Header/Body) <!-- id: 37 -->
- [x] Logic: Update Cut Loss to use Entry Price <!-- id: 34 -->
- [x] Logic: Implement Safe Entry Range & Conditions <!-- id: 35 -->
- [x] UI: Display Safe Entry Range & Signal <!-- id: 36 -->
- [x] Verify Features <!-- id: 26 -->

# ATR Calculation
- [x] Logic: Separate ATR for Cut Loss (historical) vs Trailing (current) <!-- id: 38 -->
- [x] Verify Dual ATR Implementation <!-- id: 39 -->

# Advanced Trading Logic Integration
- [x] Data Models: Add TradeState enum and enhanced StrategyResult <!-- id: 40 -->
- [x] Structure Detection: Implement HH/HL pattern recognition <!-- id: 41 -->
- [x] Breakout Detection: Add 20-day high breakout logic <!-- id: 42 -->
- [x] Post-Entry: Implement confirmation monitoring (3-7 days) <!-- id: 43 -->
- [x] Post-Entry: Add failure detection logic <!-- id: 44 -->
- [x] Position Sizing: Implement risk-based calculator <!-- id: 45 -->
- [x] Profit Management: Add breakeven stop movement <!-- id: 46 -->
- [x] Profit Management: Add partial profit targets <!-- id: 47 -->
- [x] Trade Lifecycle: Implement max hold time tracking <!-- id: 48 -->
- [ ] UI: Display trade state and confirmation status <!-- id: 49 -->
- [ ] UI: Show position sizing suggestions <!-- id: 50 -->
- [ ] Testing: Verify all new features <!-- id: 51 -->
