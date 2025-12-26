# MNQ ScalpMaster - Quick Start Guide

Get up and running in 5 minutes! ⚡

## ✅ Prerequisites

- [x] MetaTrader 5 installed and running
- [x] MNQ (Micro E-mini Nasdaq-100) symbol available with broker
- [x] Demo or funded trading account
- [x] Basic understanding of MQL5 Expert Advisors

## 🚀 Installation (3 Steps)

### Step 1: Copy Files (2 minutes)

1. **Download** all files from `mnq-trading-bot/` folder

2. **Open MT5 Data Folder:**
   - In MT5: `File` → `Open Data Folder` (or press `Ctrl+Shift+D`)

3. **Copy files** to these locations:
   ```
   📁 MQL5/
   ├── 📁 Experts/
   │   └── MNQ_ScalpMaster.mq5     ← Copy here
   └── 📁 Include/
       ├── MNQ_RiskManager.mqh      ← Copy here
       ├── MNQ_Indicators.mqh       ← Copy here
       └── MNQ_Dashboard.mqh        ← Copy here
   ```

### Step 2: Compile (1 minute)

1. Open **MetaEditor** (press `F4` in MT5)
2. Navigate to `Experts` → `MNQ_ScalpMaster.mq5`
3. Click **Compile** button (or press `F7`)
4. Check for ✅ **"0 error(s), 0 warning(s)"** in Toolbox tab
5. Close MetaEditor

### Step 3: Attach to Chart (2 minutes)

1. **Open MNQ chart** in MT5:
   - `File` → `New Chart` → Search "MNQ" or "NQ"
   
2. **Attach EA:**
   - Drag `MNQ_ScalpMaster` from Navigator panel onto chart
   - OR: Right-click chart → `Expert Advisors` → `MNQ_ScalpMaster`

3. **Configure settings** (use defaults for first test):
   - Check "Allow Algo Trading" ✅
   - Check "Allow DLL imports" (if needed)
   - Click `OK`

4. **Enable AutoTrading:**
   - Click the **AutoTrading** button in toolbar (turns green)
   - OR press `Ctrl+E`

5. **Verify:** Look for **smiley face** 😊 in top-right corner of chart

## 🎨 Recommended First Settings

Use the **Conservative Scalper** preset for your first run:

```
=== RISK MANAGEMENT ===
InpRiskPercent = 0.5%       ← Low risk
InpMaxDailyLoss = 2.0%      ← Safety limit
InpMaxOpenTrades = 1        ← One trade at a time

=== TRADE FILTERS ===
InpUseTrendFilter = true    ← Trade with trend
InpUseVolumeFilter = true   ← Confirm with volume
```

## 📊 First Backtest (Optional but Recommended)

Before live/demo trading, test on historical data:

1. Open **Strategy Tester** (`Ctrl+R`)
2. Configure:
   - Expert Advisor: `MNQ_ScalpMaster`
   - Symbol: `MNQ` or `NQ`
   - Period: `M5` (5-minute)
   - Date Range: Last 6 months
   - Model: `Every tick` (most accurate)
   
3. Click **Start**
4. Review results:
   - Win Rate: Target 50-60%
   - Profit Factor: Target > 1.5
   - Max Drawdown: Keep < 15%

## 🎯 What to Expect

### First Hour
- EA initializes and shows dashboard
- May not trade immediately (waiting for signals)
- Monitor Experts tab for messages

### First Day
- Conservative preset: 2-4 trades expected
- Each trade has Stop Loss and Take Profit automatically set
- Dashboard shows realtime P&L

### First Week
- Monitor win rate (target: 55%+)
- Check daily P&L consistency
- Adjust settings if needed (see PRESETS.md)

## 📈 Dashboard Explained

```
=== MNQ SCALPMASTER ===
Equity: $10,245.50           ← Your account value
Daily P&L: +$245.50          ← Today's profit/loss (green=profit, red=loss)
Trades Today: 8              ← Number of trades executed
Win Rate: 62.5%              ← Percentage of winning trades
Open Positions: 2            ← Currently active trades
Risk Exposure: 1.8%          ← % of equity at risk
────────────────────
Status: ✓ ACTIVE             ← Trading status
```

## ⚠️ Common Issues & Fixes

### ❌ "Expert Advisor is not allowed to trade"
**Fix:** Enable AutoTrading button in toolbar (should be green)

### ❌ "Not enough money"
**Fix:** 
- Reduce `InpRiskPercent` to 0.25%
- Increase account balance
- Check margin requirements with broker

### ❌ "Invalid stops"
**Fix:**
- Check broker's minimum stop distance
- Increase `InpATRMultiplier` to 2.5 or 3.0

### ❌ No trades happening
**Check:**
- Current time (must be within 9:30-16:00 default)
- AutoTrading is enabled
- Expert tab shows "initialized successfully"
- Market is open (not weekend/holiday)

### ❌ Compilation errors
**Fix:**
- Ensure all `.mqh` files are in `Include/` folder
- Update MT5 to latest build (3440+)
- Check file paths are correct

## 🔧 Quick Tweaks

### Want more trades?
```
InpFastEMA = 5              // Faster crossovers
InpSlowEMA = 13
InpUseVolumeFilter = false  // Remove volume filter
```

### Want safer trading?
```
InpRiskPercent = 0.25%      // Quarter of default
InpMaxOpenTrades = 1        // One at a time
InpRewardRiskRatio = 3.0    // Larger profit targets
```

### Want to trade overnight?
```
InpStartTime = 18:00        // Evening session
InpEndTime = 05:00          // Before US open
```

## 📚 Next Steps

1. ✅ **Read full README.md** - Understand strategy in depth
2. ✅ **Check PRESETS.md** - Try different trading styles  
3. ✅ **Run backtests** - Test before risking real money
4. ✅ **Start with demo** - At least 2 weeks on demo account
5. ✅ **Monitor daily** - Review performance and adjust

## 🎓 Learning Resources

**MT5 Basics:**
- AutoTrading: `Tools` → `Options` → `Expert Advisors` tab
- Strategy Tester: `View` → `Strategy Tester` (or `Ctrl+R`)
- Logs: `Toolbox` → `Experts` tab

**EA Settings:**
- Right-click chart → `Expert Advisors` → `Properties`
- `Inputs` tab - All EA parameters
- `Common` tab - Trading permissions

## 💡 Pro Tips

1. **Start conservative** - Use 0.5% risk for first month
2. **Monitor daily** - Check dashboard for performance
3. **Adjust to market** - Switch presets based on conditions
4. **Keep logs** - Screenshot dashboard daily
5. **Test changes** - Always backtest before changing settings

## 🆘 Need Help?

1. Check **Experts** tab in Toolbox for error messages
2. Review **README.md** troubleshooting section
3. Verify all files are in correct folders
4. Test in Strategy Tester before live trading
5. Start with small risk (0.25-0.5%)

---

**Ready to Trade! 🚀**

Remember:
- ⚠️ Start with demo account
- ⚠️ Never risk more than you can afford to lose
- ⚠️ Monitor EA performance daily
- ⚠️ Past performance ≠ future results

**Good luck trading MNQ! 📈💰**
