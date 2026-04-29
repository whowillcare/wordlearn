# Flutter Stock Analysis App Walkthrough

## Overview
This application allows users to analyze stock data using Yahoo Finance. It features historical candlestick charts and trading strategy tools like ATR Stops and EMA Stops.

## Features
- **Stock Search**: Enter a symbol (e.g., AAPL, TSLA) to fetch daily historical data.
- **[NEW] Autocomplete**: Search for Company Name or Symbol to get suggestions.
- **[NEW] Multi-Tab Interface**: Analyze multiple stocks simultaneously in different tabs.
- **[NEW] Manual Refresh**: Force update data from the server, bypassing the cache.
- **Data Caching**: Automatically improved performance by caching data locally using SQLite.
- **Interactive Chart**: Pan and zoom candlestick charts.
- **Strategies**:
    - **ATR Stop**: Calculates a stop loss based on Average True Range.
    - **EMA Stop**: Uses Exponential Moving Average as a dynamic stop level.
    - **[NEW] Transparent Logic**: Displays the exact equation and values used for the calculation.

## How to Run
1. Ensure you have Flutter installed.
2. Navigate to the project directory:
   ```bash
   cd /home/sam/Projects/stocks
   ```
3. Run the app:
   ```bash
   flutter run -d linux
   ```

## Verification
- **Unit Tests**: Strategy logic (ATR, EMA) has been verified.
- **Build**: Validated that the app compiles and builds for Linux.
- **Manual QA**: verified Search, Tabs, and Refresh functionality.

## Screenshots
> (Note: Run the app to explore the UI interactively)
