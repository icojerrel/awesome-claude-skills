# MNQ ScalpMaster - Advanced Trading Bot for MNQ Futures

**Version**: 1.0  
**Date**: December 26, 2025  
**Platform**: MetaTrader 5 (MT5)  
**Instrument**: MNQ (Micro E-mini Nasdaq-100 Futures)

## 🎯 Overview

MNQ ScalpMaster is a professional algorithmic trading bot designed specifically for MNQ futures trading on MetaTrader 5. It uses a combination of EMA crossovers, RSI, volume analysis, and ATR-based risk management to execute high-probability scalping trades.

### Key Features

✅ **Multi-Indicator Strategy**
- EMA crossover system (9/21 default)
- RSI overbought/oversold detection
- Trend filter with 50 EMA
- Volume confirmation

✅ **Advanced Risk Management**
- Dynamic position sizing (1-2% risk per trade)
- ATR-based stop loss and take profit
- Daily loss limit protection (3% default)
- Maximum open positions limiter

✅ **Performance Tracking**
- Real-time dashboard on chart
- Win rate calculation
- Daily P&L tracking
- Risk exposure monitoring

✅ **Smart Filters**
- Trading hours restriction
- Trend confirmation filter
- Volume filter
- Break-even management

## 📁 File Structure

```
mnq-trading-bot/
├── Experts/
│   └── MNQ_ScalpMaster.mq5       # Main Expert Advisor
├── Include/
│   ├── MNQ_RiskManager.mqh       # Risk management library
│   ├── MNQ_Indicators.mqh        # Technical indicators
│   └── MNQ_Dashboard.mqh         # Performance dashboard
├── Scripts/
│   └── MNQ_Backtester.mq5        # Backtesting script (optional)
└── README.md                      # This file
```

## 🚀 Installation

### Step 1: Copy Files to MT5

1. Open MT5 Data Folder:
   - In MT5: `File` → `Open Data Folder`
   
2. Copy files to appropriate directories:
   ```
   MQL5/Experts/MNQ_ScalpMaster.mq5    → Experts/
   MQL5/Include/MNQ_*.mqh              → Include/
   ```

3. Restart MT5 or press `Ctrl+R` to recompile

### Step 2: Compile Expert Advisor

1. Open MetaEditor (`F4` in MT5)
2. Navigate to `Experts/MNQ_ScalpMaster.mq5`
3. Click `Compile` button or press `F7`
4. Check for errors in the `Toolbox` tab

### Step 3: Attach to Chart

1. Open MNQ chart (any timeframe, EA will use M5)
2. Drag `MNQ_ScalpMaster` from Navigator to chart
3. Configure settings (see Configuration section)
4. Enable AutoTrading (`Ctrl+E` or toolbar button)

## ⚙️ Configuration

### Strategy Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpTimeframe` | M5 | Trading timeframe (5-minute recommended for MNQ) |
| `InpFastEMA` | 9 | Fast EMA period |
| `InpSlowEMA` | 21 | Slow EMA period |
| `InpRSIPeriod` | 14 | RSI period |
| `InpRSIOverbought` | 70 | RSI overbought level |
| `InpRSIOversold` | 30 | RSI oversold level |

### Risk Management

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpRiskPercent` | 1.0% | Risk per trade as % of equity |
| `InpMaxDailyLoss` | 3.0% | Maximum daily loss limit |
| `InpMaxOpenTrades` | 3 | Maximum simultaneous positions |
| `InpATRMultiplier` | 2.0 | ATR multiplier for SL/TP |
| `InpRewardRiskRatio` | 2.0 | Target reward:risk ratio |

### Trade Filters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpUseTrendFilter` | true | Use 50 EMA trend filter |
| `InpTrendEMA` | 50 | Trend EMA period |
| `InpUseVolumeFilter` | true | Require volume confirmation |
| `InpMinVolumeMultiplier` | 1.2 | Min volume vs 20-bar average |

### Time Filters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpStartTime` | 09:30 | Start trading time (Exchange time) |
| `InpEndTime` | 16:00 | End trading time |
| `InpAvoidNews` | true | Avoid major news events (future) |

## 📊 Trading Strategy

### Entry Conditions

**LONG Entry:**
1. Fast EMA crosses above Slow EMA (bullish crossover)
2. RSI < 30 (oversold condition)
3. Price above 50 EMA (uptrend confirmation)
4. Volume > 1.2x average (volume confirmation)

**SHORT Entry:**
1. Fast EMA crosses below Slow EMA (bearish crossover)
2. RSI > 70 (overbought condition)
3. Price below 50 EMA (downtrend confirmation)
4. Volume > 1.2x average (volume confirmation)

### Exit Conditions

**Stop Loss:**
- Placed at 2x ATR from entry price
- Automatically calculated based on recent volatility

**Take Profit:**
- Placed at 2:1 reward:risk ratio (4x ATR from entry)
- Adjustable via `InpRewardRiskRatio`

**Break-Even:**
- Position SL moved to break-even + 0.1 ATR when price moves 0.5 ATR in profit
- Protects capital once trade shows positive momentum

## 💰 Risk Management

### Position Sizing

Position size is automatically calculated to risk a fixed percentage of equity:

```
Risk Amount = Account Equity × (Risk Percent / 100)
Position Size = Risk Amount / (Stop Loss Points × Point Value)
```

**Example:**
- Account: $10,000
- Risk: 1% ($100)
- ATR: 20 points
- SL: 2× ATR = 40 points
- Position Size = $100 / (40 points × $0.50/point) = 5 contracts

### Daily Loss Limit

The EA stops trading when daily loss reaches the specified limit:

- Default: 3% of equity
- Protects from excessive drawdown
- Resets at start of new trading day

### Maximum Open Trades

Limits simultaneous exposure:

- Default: 3 positions
- Prevents over-concentration
- Reduces correlation risk

## 📈 Performance Dashboard

The on-chart dashboard displays:

```
=== MNQ SCALPMASTER ===
Equity: $10,245.50
Daily P&L: +$245.50
Trades Today: 8
Win Rate: 62.5%
Open Positions: 2
Risk Exposure: 1.8%
────────────────────
Status: ✓ ACTIVE
```

### Dashboard Colors

- **Green**: Positive P&L, normal risk
- **Yellow**: Approaching daily loss limit, elevated risk
- **Red**: Negative P&L, high risk exposure

## 🔧 Optimization Tips

### For Aggressive Trading

```
InpRiskPercent = 2.0        // Higher risk per trade
InpMaxOpenTrades = 5        // More simultaneous positions
InpRewardRiskRatio = 1.5    // Tighter profit targets
```

### For Conservative Trading

```
InpRiskPercent = 0.5        // Lower risk per trade
InpMaxOpenTrades = 1        // One trade at a time
InpRewardRiskRatio = 3.0    // Larger profit targets
```

### For Trending Markets

```
InpFastEMA = 12             // Slower EMA crossover
InpSlowEMA = 26
InpUseTrendFilter = true    // Strict trend following
```

### For Ranging Markets

```
InpRSIOverbought = 65       // Wider RSI bands
InpRSIOversold = 35
InpUseTrendFilter = false   // Allow counter-trend
```

## ⚠️ Important Notes

### MNQ Specifications

- **Contract Size**: $2 × Nasdaq-100 Index
- **Tick Size**: 0.25 index points
- **Tick Value**: $0.50
- **Trading Hours**: 6:00 PM - 5:00 PM ET (next day)
- **Margin**: ~$600-800 per contract (varies by broker)

### Risk Warning

⚠️ **Trading futures involves substantial risk of loss**

- Start with paper trading/backtesting
- Never risk more than you can afford to lose
- Use proper position sizing
- Monitor EA performance daily
- Adjust parameters based on market conditions

### System Requirements

- **Platform**: MetaTrader 5 build 3440+
- **Internet**: Stable connection required
- **VPS**: Recommended for 24/7 operation
- **Capital**: Minimum $5,000 recommended

## 📊 Backtesting

### Strategy Tester Settings

1. Open Strategy Tester (`Ctrl+R`)
2. Select `MNQ_ScalpMaster` Expert Advisor
3. Choose MNQ symbol
4. Select M5 timeframe
5. Set date range (at least 6 months)
6. Use "Every tick" or "1 minute OHLC" model
7. Enable visual mode for verification

### Performance Metrics to Monitor

- **Win Rate**: Target 50-60%
- **Profit Factor**: Target 1.5+
- **Max Drawdown**: Keep below 15%
- **Average Win/Loss**: Target 1.5+
- **Sharpe Ratio**: Target 1.0+

## 🐛 Troubleshooting

### EA Not Trading

1. **Check AutoTrading**: Ensure it's enabled (green button in toolbar)
2. **Verify Symbol**: Must be attached to MNQ chart
3. **Check Time**: Within trading hours (9:30-16:00 default)
4. **Review Logs**: Open `Experts` tab for error messages

### Compilation Errors

1. **Missing Headers**: Ensure all `.mqh` files are in `Include/` folder
2. **Trade.mqh Missing**: Comes standard with MT5, reinstall if needed
3. **Syntax Errors**: Check MQL5 version (build 3440+)

### Position Not Opening

1. **Check Margin**: Insufficient margin for position size
2. **Lot Size Too Small**: Increase risk percent or account size
3. **Max Trades Reached**: Already at maximum open positions
4. **Daily Loss Hit**: Reset at new trading day

## 📝 Changelog

### Version 1.0 (December 26, 2025)
- ✅ Initial release
- ✅ EMA crossover + RSI strategy
- ✅ ATR-based risk management
- ✅ Performance dashboard
- ✅ Break-even management
- ✅ Daily loss limits
- ✅ Time filters
- ✅ Volume filters

## 🤝 Support

For issues, questions, or feature requests:

1. Check this README first
2. Review MT5 Experts tab for error messages
3. Test in Strategy Tester before live trading
4. Start with demo account

## 📜 License

This Expert Advisor is provided for educational and trading purposes.  
Use at your own risk. No guarantees of profitability.

---

**Happy Trading! 🚀📈**

*Remember: Past performance does not guarantee future results.*
