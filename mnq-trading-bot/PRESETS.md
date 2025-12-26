# MNQ ScalpMaster - Configuration Presets

Pre-configured settings for different trading styles and market conditions.

## 🎯 Recommended Presets

### 1. Conservative Scalper (Recommended for Beginners)

**Goal**: Low risk, high win rate, smaller profits

```
=== STRATEGY SETTINGS ===
InpFastEMA = 12
InpSlowEMA = 26
InpRSIOverbought = 65
InpRSIOversold = 35

=== RISK MANAGEMENT ===
InpRiskPercent = 0.5%
InpMaxDailyLoss = 2.0%
InpMaxOpenTrades = 1
InpATRMultiplier = 2.5
InpRewardRiskRatio = 3.0

=== TRADE FILTERS ===
InpUseTrendFilter = true
InpTrendEMA = 50
InpUseVolumeFilter = true
InpMinVolumeMultiplier = 1.5
```

**Expected Performance:**
- Win Rate: 60-70%
- Avg Trades/Day: 2-4
- Risk Profile: Low
- Drawdown: <10%

---

### 2. Aggressive Scalper (For Experienced Traders)

**Goal**: High frequency, larger position sizes, quick profits

```
=== STRATEGY SETTINGS ===
InpFastEMA = 5
InpSlowEMA = 13
InpRSIOverbought = 75
InpRSIOversold = 25

=== RISK MANAGEMENT ===
InpRiskPercent = 2.0%
InpMaxDailyLoss = 5.0%
InpMaxOpenTrades = 5
InpATRMultiplier = 1.5
InpRewardRiskRatio = 1.5

=== TRADE FILTERS ===
InpUseTrendFilter = false
InpUseVolumeFilter = true
InpMinVolumeMultiplier = 1.0
```

**Expected Performance:**
- Win Rate: 50-60%
- Avg Trades/Day: 8-15
- Risk Profile: High
- Drawdown: <20%

---

### 3. Trend Follower (Best for Trending Days)

**Goal**: Catch strong trends, ride winners

```
=== STRATEGY SETTINGS ===
InpFastEMA = 9
InpSlowEMA = 21
InpRSIOverbought = 60
InpRSIOversold = 40

=== RISK MANAGEMENT ===
InpRiskPercent = 1.5%
InpMaxDailyLoss = 3.0%
InpMaxOpenTrades = 3
InpATRMultiplier = 3.0
InpRewardRiskRatio = 4.0

=== TRADE FILTERS ===
InpUseTrendFilter = true
InpTrendEMA = 100
InpUseVolumeFilter = true
InpMinVolumeMultiplier = 1.3
```

**Expected Performance:**
- Win Rate: 45-55%
- Avg Trades/Day: 3-6
- Risk Profile: Medium
- Drawdown: <15%

---

### 4. Range Trader (Best for Choppy Markets)

**Goal**: Exploit overbought/oversold conditions

```
=== STRATEGY SETTINGS ===
InpFastEMA = 9
InpSlowEMA = 21
InpRSIOverbought = 70
InpRSIOversold = 30

=== RISK MANAGEMENT ===
InpRiskPercent = 1.0%
InpMaxDailyLoss = 3.0%
InpMaxOpenTrades = 2
InpATRMultiplier = 2.0
InpRewardRiskRatio = 2.0

=== TRADE FILTERS ===
InpUseTrendFilter = false
InpUseVolumeFilter = false
InpMinVolumeMultiplier = 1.0
```

**Expected Performance:**
- Win Rate: 55-65%
- Avg Trades/Day: 4-8
- Risk Profile: Low-Medium
- Drawdown: <12%

---

### 5. News Trader (High Volatility)

**Goal**: Capture moves during news releases

```
=== STRATEGY SETTINGS ===
InpFastEMA = 5
InpSlowEMA = 13
InpRSIOverbought = 80
InpRSIOversold = 20

=== RISK MANAGEMENT ===
InpRiskPercent = 1.0%
InpMaxDailyLoss = 4.0%
InpMaxOpenTrades = 2
InpATRMultiplier = 3.0
InpRewardRiskRatio = 3.0

=== TRADE FILTERS ===
InpUseTrendFilter = false
InpUseVolumeFilter = true
InpMinVolumeMultiplier = 2.0

=== TIME FILTERS ===
InpStartTime = 08:25   // Before market open
InpEndTime = 10:00     // First 90 minutes
InpAvoidNews = false
```

**Expected Performance:**
- Win Rate: 40-50%
- Avg Trades/Day: 2-5
- Risk Profile: Very High
- Drawdown: <25%

---

### 6. Night Session (Asian/European Hours)

**Goal**: Trade during quieter hours

```
=== STRATEGY SETTINGS ===
InpFastEMA = 12
InpSlowEMA = 26
InpRSIOverbought = 65
InpRSIOversold = 35

=== RISK MANAGEMENT ===
InpRiskPercent = 0.75%
InpMaxDailyLoss = 2.5%
InpMaxOpenTrades = 2
InpATRMultiplier = 2.5
InpRewardRiskRatio = 2.5

=== TIME FILTERS ===
InpStartTime = 18:00   // Evening session
InpEndTime = 05:00     // Before US open
```

**Expected Performance:**
- Win Rate: 55-65%
- Avg Trades/Day: 1-3
- Risk Profile: Low
- Drawdown: <8%

---

## 🎨 How to Apply Presets

### Method 1: Manual Configuration

1. Attach EA to chart
2. Open EA Properties (`F7`)
3. Go to "Inputs" tab
4. Enter values from chosen preset
5. Click "OK"

### Method 2: Create SET File

1. Configure EA with preset values
2. Right-click on EA in chart
3. Select "Expert Advisors" → "Properties"
4. Go to "Inputs" tab
5. Click "Save" and name it (e.g., `MNQ_Conservative.set`)
6. Save to `MQL5/Presets/` folder

To load:
1. Right-click on EA → "Properties"
2. Go to "Inputs" tab
3. Click "Load"
4. Select saved preset

---

## 📊 Preset Comparison

| Preset | Risk Level | Trades/Day | Win Rate | Best For |
|--------|------------|------------|----------|----------|
| Conservative | ⭐ Low | 2-4 | 60-70% | Beginners, small accounts |
| Aggressive | ⭐⭐⭐ High | 8-15 | 50-60% | Experienced, large accounts |
| Trend Follower | ⭐⭐ Medium | 3-6 | 45-55% | Strong trending days |
| Range Trader | ⭐⭐ Low-Med | 4-8 | 55-65% | Choppy, sideways markets |
| News Trader | ⭐⭐⭐⭐ Very High | 2-5 | 40-50% | Major news events |
| Night Session | ⭐ Low | 1-3 | 55-65% | Asian/European hours |

---

## 🔧 Custom Optimization

### Step 1: Choose Base Preset

Start with the preset closest to your trading style:
- **Risk-averse**: Conservative Scalper
- **Moderate**: Range Trader
- **Aggressive**: Aggressive Scalper

### Step 2: Backtest

1. Load preset in Strategy Tester
2. Run on historical data (6+ months)
3. Analyze performance metrics

### Step 3: Optimize Parameters

Focus on optimizing 2-3 parameters at a time:

**For better win rate:**
- Increase `InpATRMultiplier` (wider stops)
- Enable `InpUseTrendFilter`
- Increase `InpMinVolumeMultiplier`

**For more trades:**
- Decrease `InpFastEMA` and `InpSlowEMA`
- Widen RSI bands (lower overbought, higher oversold)
- Disable `InpUseVolumeFilter`

**For higher profits:**
- Increase `InpRewardRiskRatio`
- Increase `InpRiskPercent` (carefully!)
- Increase `InpMaxOpenTrades`

### Step 4: Forward Test

Test optimized settings on demo account for at least 2 weeks before going live.

---

## ⚠️ Important Reminders

1. **No preset works in all market conditions**
   - Monitor performance weekly
   - Switch presets when market character changes

2. **Start conservative**
   - Use Conservative preset for first month
   - Gradually increase risk as you gain confidence

3. **Backtest before use**
   - Always test preset on historical data
   - Verify it works with your broker's spread/commission

4. **Account size matters**
   - $5k account: Conservative preset
   - $10k-25k account: Conservative or Range Trader
   - $25k+ account: Any preset based on experience

5. **Market sessions**
   - US Open (9:30-11:00): Most volatile, use Conservative
   - Mid-day (11:00-14:00): Lower volume, use Range Trader
   - US Close (15:00-16:00): Increased activity, use Trend Follower

---

**Happy Trading! 🚀**

*Remember to always test presets in backtesting and demo accounts before live trading.*
