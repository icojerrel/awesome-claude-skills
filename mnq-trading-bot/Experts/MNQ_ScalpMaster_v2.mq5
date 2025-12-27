//+------------------------------------------------------------------+
//|                                      MNQ_ScalpMaster_v2.mq5      |
//|                   QUANT-DRIVEN NQ STATS PROBABILITY TRADING      |
//|                      Version 2.0 - December 2025                 |
//+------------------------------------------------------------------+
#property copyright "MNQ ScalpMaster v2 - NQ Stats Integration"
#property version   "2.00"
#property strict

// Include libraries
#include <Trade\Trade.mqh>
#include "../Include/MNQ_RiskManager.mqh"
#include "../Include/MNQ_Indicators.mqh"
#include "../Include/MNQ_Dashboard.mqh"
#include "../Include/MNQ_NQStats.mqh"

//--- Input parameters
input group "=== NQ STATS PROBABILITY FILTERS ==="
input bool   InpUseSDEVPivots = true;                      // Use SDEV-Based Pivots
input bool   InpUseIBStrategy = true;                      // Use Initial Balance Strategy
input bool   Inp9amBias = true;                            // Use 9am Hour Bias (67-70%)
input bool   InpUseJudas = true;                           // Use Morning Judas Continuation
input bool   InpUseRTHBreaks = true;                       // Use RTH Break Bias (83%)
input bool   InpUseNoonCurve = true;                       // Use Noon Curve AM/PM Structure
input bool   InpUseHourStats = true;                       // Use Hour Retracement Stats

input group "=== PROBABILITY THRESHOLDS ==="
input double InpMinProbability = 0.60;                     // Minimum Trade Probability (60%)
input double InpSDEVExtreme = 1.5;                         // SDEV Extreme Level (Trend Day)
input double InpReversionSDEV = 1.0;                       // SDEV Level for Reversion

input group "=== STRATEGY SETTINGS ==="
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;
input int    InpFastEMA = 9;
input int    InpSlowEMA = 21;
input int    InpRSIPeriod = 14;
input double InpRSIOverbought = 70.0;
input double InpRSIOversold = 30.0;

input group "=== RISK MANAGEMENT ==="
input double InpRiskPercent = 1.0;
input double InpMaxDailyLoss = 3.0;
input int    InpMaxOpenTrades = 3;
input bool   InpUseSDEVTP = true;                          // Use SDEV-Based Take Profit
input bool   InpUseSDEVSL = true;                          // Use SDEV-Based Stop Loss

input group "=== DISPLAY ==="
input bool   InpShowDashboard = true;
input bool   InpShowNQStats = true;                        // Show NQ Stats Panel
input color  InpDashboardColor = clrLime;

//--- Global variables
CTrade trade;
MNQ_RiskManager riskManager;
MNQ_Indicators indicators;
MNQ_Dashboard dashboard;
MNQ_NQStats nqStats;

datetime lastBarTime = 0;
double dailyProfit = 0.0;
int tradesToday = 0;
datetime todayStart;

// NQ Stats tracking
int currentBias = 0;              // -1 = bearish, 0 = neutral, 1 = bullish
double currentProbability = 0.0;  // Current setup probability

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== MNQ ScalpMaster v2 - NQ Stats Edition ===");
   Print("Quant-Driven Probability Trading");
   
   // Initialize components
   riskManager.Init(InpRiskPercent, InpMaxDailyLoss, InpMaxOpenTrades);
   indicators.Init(InpFastEMA, InpSlowEMA, InpRSIPeriod, 50);
   nqStats.Init(_Symbol);
   
   if(InpShowDashboard)
      dashboard.Init(InpDashboardColor);
   
   // Set trading parameters
   trade.SetExpertMagicNumber(20251226);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Initialize daily tracking
   todayStart = TimeCurrent();
   todayStart = todayStart - (todayStart % 86400);
   
   Print("NQ Stats Filters Active:");
   if(InpUseSDEVPivots) Print("  ✓ SDEV Pivots");
   if(InpUseIBStrategy) Print("  ✓ Initial Balance (96% break rate)");
   if(Inp9amBias) Print("  ✓ 9am Bias (67-70%)");
   if(InpUseJudas) Print("  ✓ Morning Judas Continuation");
   if(InpUseRTHBreaks) Print("  ✓ RTH Breaks (83%)");
   if(InpUseNoonCurve) Print("  ✓ Noon Curve");
   if(InpUseHourStats) Print("  ✓ Hour Stats");
   
   Print("Minimum Trade Probability: ", InpMinProbability * 100, "%");
   Print("EA Ready to Trade!");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;
   
   // Update daily tracking
   UpdateDailyTracking();
   
   // Update NQ Stats components
   UpdateNQStats();
   
   // Calculate probability-weighted bias
   CalculateProbabilityBias();
   
   // Check minimum probability threshold
   if(currentProbability < InpMinProbability)
   {
      Comment(StringFormat("Low probability setup (%.1f%%). Waiting for higher edge...", 
              currentProbability * 100));
      return;
   }
   
   // Check time filter
   if(!IsWithinTradingHours())
      return;
   
   // Check daily loss limit
   if(!riskManager.CheckDailyLossLimit(dailyProfit))
   {
      Comment("Daily loss limit reached. Trading paused.");
      return;
   }
   
   // Check max open trades
   if(PositionsTotal() >= InpMaxOpenTrades)
      return;
   
   // Manage existing positions
   ManagePositions();
   
   // Check for trade signals with NQ Stats confluence
   CheckTradeSignalsWithNQStats();
   
   // Update dashboard
   if(InpShowDashboard)
      UpdateDashboardWithStats();
}

//+------------------------------------------------------------------+
//| Update NQ Stats components                                       |
//+------------------------------------------------------------------+
void UpdateNQStats()
{
   MqlDateTime time_struct;
   TimeCurrent(time_struct);
   
   // Update Initial Balance (9:30-10:30)
   if(InpUseIBStrategy)
   {
      double high = iHigh(_Symbol, PERIOD_M1, 1);
      double low = iLow(_Symbol, PERIOD_M1, 1);
      nqStats.UpdateIB(high, low, TimeCurrent());
   }
   
   // Update RTH levels at end of session
   if(time_struct.hour == 16 && time_struct.min == 0)
   {
      double rthHigh = iHigh(_Symbol, PERIOD_D1, 0);
      double rthLow = iLow(_Symbol, PERIOD_D1, 0);
      nqStats.UpdateRTH(rthHigh, rthLow);
   }
   
   // Reset daily at new session
   if(time_struct.hour == 0 && time_struct.min == 0)
   {
      nqStats.ResetDaily();
   }
}

//+------------------------------------------------------------------+
//| Calculate probability-weighted bias from NQ Stats                |
//+------------------------------------------------------------------+
void CalculateProbabilityBias()
{
   int biasScore = 0;
   double totalWeight = 0.0;
   double sessionOpen = iOpen(_Symbol, PERIOD_D1, 0);
   double currentPrice = iClose(_Symbol, InpTimeframe, 1);
   
   // 1. SDEV Reversion Bias (Weight: 0.20)
   if(InpUseSDEVPivots)
   {
      double reversionProb = nqStats.GetReversionProbability(currentPrice, sessionOpen);
      if(reversionProb > 0.68)  // High reversion pressure
      {
         int sdevBias = (currentPrice > sessionOpen) ? -1 : 1;  // Revert to mean
         biasScore += sdevBias * 20;
         totalWeight += 20.0;
      }
   }
   
   // 2. 9am Hour Bias (Weight: 0.30 - STRONGEST EDGE!)
   if(Inp9amBias)
   {
      MqlDateTime time_struct;
      TimeCurrent(time_struct);
      
      if(time_struct.hour >= 10)  // After 9am hour complete
      {
         int am9Bias = nqStats.Get9amBias();
         if(am9Bias != 0)
         {
            biasScore += am9Bias * 30;  // 67-70% probability
            totalWeight += 30.0;
         }
      }
   }
   
   // 3. Initial Balance Break Direction (Weight: 0.25)
   if(InpUseIBStrategy)
   {
      int ibBias = nqStats.GetIBBreakDirection(currentPrice);
      if(ibBias != 0)
      {
         biasScore += ibBias * 25;  // 74-81% probability
         totalWeight += 25.0;
      }
   }
   
   // 4. RTH Break Bias (Weight: 0.25)
   if(InpUseRTHBreaks)
   {
      int rthBias = nqStats.GetRTHBreakBias(sessionOpen);
      if(rthBias != 0)
      {
         biasScore += rthBias * 25;  // 83% probability
         totalWeight += 25.0;
      }
   }
   
   // 5. Morning Judas Continuation (Weight: 0.20)
   if(InpUseJudas)
   {
      int judasBias = nqStats.GetJudasContinuation(TimeCurrent());
      if(judasBias != 0)
      {
         biasScore += judasBias * 20;  // 64-70% probability
         totalWeight += 20.0;
      }
   }
   
   // 6. Noon Curve (Weight: 0.15)
   if(InpUseNoonCurve)
   {
      if(!nqStats.IsAMSession())  // PM session
      {
         // Determine if AM made high or low
         double amHigh = iHigh(_Symbol, PERIOD_H4, 0);  // 8am-12pm
         double amLow = iLow(_Symbol, PERIOD_H4, 0);
         bool amMadeHigh = (amHigh > amLow);  // Simplified
         
         int noonBias = nqStats.GetNoonCurveBias(amMadeHigh);
         biasScore += noonBias * 15;  // 74.3% probability
         totalWeight += 15.0;
      }
   }
   
   // Calculate weighted bias
   if(totalWeight > 0)
   {
      double normalizedScore = biasScore / totalWeight;
      currentBias = (normalizedScore > 0.3) ? 1 : (normalizedScore < -0.3) ? -1 : 0;
      currentProbability = MathAbs(normalizedScore);
   }
   else
   {
      currentBias = 0;
      currentProbability = 0.0;
   }
   
   // Log bias calculation
   if(currentProbability > 0)
   {
      Print(StringFormat("NQ Stats Bias: %s | Probability: %.1f%% | Score: %d/%d",
            currentBias > 0 ? "BULLISH" : currentBias < 0 ? "BEARISH" : "NEUTRAL",
            currentProbability * 100, biasScore, (int)totalWeight));
   }
}

//+------------------------------------------------------------------+
//| Check trade signals with NQ Stats confluence                     |
//+------------------------------------------------------------------+
void CheckTradeSignalsWithNQStats()
{
   // Get technical indicators
   double fastEMA = indicators.GetEMA(InpFastEMA, 1);
   double slowEMA = indicators.GetEMA(InpSlowEMA, 1);
   double rsi = indicators.GetRSI(1);
   double atr = indicators.GetATR(14, 1);
   
   double prevFastEMA = indicators.GetEMA(InpFastEMA, 2);
   double prevSlowEMA = indicators.GetEMA(InpSlowEMA, 2);
   
   double sessionOpen = iOpen(_Symbol, PERIOD_D1, 0);
   double currentPrice = iClose(_Symbol, InpTimeframe, 1);
   
   // Check SDEV extreme levels (trend day identifier)
   bool isTrendDay = nqStats.IsTrendDay(currentPrice, sessionOpen);
   if(isTrendDay)
   {
      Print("TREND DAY DETECTED - Rubber band snap in progress");
   }
   
   // LONG SIGNAL - Must align with NQ Stats bias
   if(prevFastEMA <= prevSlowEMA && fastEMA > slowEMA &&  // Bullish crossover
      rsi < InpRSIOversold &&                              // Oversold
      currentBias >= 0 &&                                  // NQ Stats neutral or bullish
      currentProbability >= InpMinProbability)             // Minimum probability
   {
      // Additional NQ Stats confirmation
      bool ibConfirm = !InpUseIBStrategy || nqStats.GetIBBreakDirection(currentPrice) >= 0;
      bool rthConfirm = !InpUseRTHBreaks || nqStats.GetRTHBreakBias(sessionOpen) >= 0;
      
      if(ibConfirm && rthConfirm)
      {
         Print(StringFormat("✓ LONG SIGNAL - Probability: %.1f%% | IB: %s | RTH: %s",
               currentProbability * 100,
               ibConfirm ? "✓" : "✗",
               rthConfirm ? "✓" : "✗"));
         
         OpenTradeWithSDEV(ORDER_TYPE_BUY, atr, sessionOpen, currentPrice);
      }
   }
   
   // SHORT SIGNAL - Must align with NQ Stats bias
   if(prevFastEMA >= prevSlowEMA && fastEMA < slowEMA &&  // Bearish crossover
      rsi > InpRSIOverbought &&                            // Overbought
      currentBias <= 0 &&                                  // NQ Stats neutral or bearish
      currentProbability >= InpMinProbability)             // Minimum probability
   {
      // Additional NQ Stats confirmation
      bool ibConfirm = !InpUseIBStrategy || nqStats.GetIBBreakDirection(currentPrice) <= 0;
      bool rthConfirm = !InpUseRTHBreaks || nqStats.GetRTHBreakBias(sessionOpen) <= 0;
      
      if(ibConfirm && rthConfirm)
      {
         Print(StringFormat("✓ SHORT SIGNAL - Probability: %.1f%% | IB: %s | RTH: %s",
               currentProbability * 100,
               ibConfirm ? "✓" : "✗",
               rthConfirm ? "✓" : "✗"));
         
         OpenTradeWithSDEV(ORDER_TYPE_SELL, atr, sessionOpen, currentPrice);
      }
   }
}

//+------------------------------------------------------------------+
//| Open trade with SDEV-based SL/TP                                 |
//+------------------------------------------------------------------+
void OpenTradeWithSDEV(ENUM_ORDER_TYPE orderType, double atr, double sessionOpen, double currentPrice)
{
   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double sl, tp;
   
   if(InpUseSDEVSL || InpUseSDEVTP)
   {
      // Calculate SDEV-based levels
      double sdevDistance = nqStats.GetSDEVLevel(sessionOpen, 1.0);  // 1.0 SDEV
      
      if(orderType == ORDER_TYPE_BUY)
      {
         // SDEV-based SL (at -1.0 SDEV from current price)
         sl = InpUseSDEVSL ? currentPrice - sdevDistance : price - (atr * 2.0);
         
         // SDEV-based TP (at +1.5 SDEV from current price)
         tp = InpUseSDEVTP ? currentPrice + (sdevDistance * 1.5) : price + (atr * 4.0);
      }
      else
      {
         sl = InpUseSDEVSL ? currentPrice + sdevDistance : price + (atr * 2.0);
         tp = InpUseSDEVTP ? currentPrice - (sdevDistance * 1.5) : price - (atr * 4.0);
      }
   }
   else
   {
      // Traditional ATR-based SL/TP
      if(orderType == ORDER_TYPE_BUY)
      {
         sl = price - (atr * 2.0);
         tp = price + (atr * 4.0);
      }
      else
      {
         sl = price + (atr * 2.0);
         tp = price - (atr * 4.0);
      }
   }
   
   // Calculate position size
   double stopLoss = MathAbs(price - sl);
   double lotSize = riskManager.CalculatePositionSize(stopLoss);
   
   if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("Lot size too small: ", lotSize);
      return;
   }
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   price = NormalizeDouble(price, _Digits);
   
   // Calculate R:R ratio
   double rr = MathAbs(tp - price) / MathAbs(price - sl);
   
   // Execute trade
   string comment = StringFormat("NQStats %.0f%%", currentProbability * 100);
   bool result = trade.PositionOpen(_Symbol, orderType, lotSize, price, sl, tp, comment);
   
   if(result)
   {
      Print(StringFormat("✓ %s order | Price: %.2f | SL: %.2f | TP: %.2f | R:R: %.1f | Prob: %.1f%%",
            orderType == ORDER_TYPE_BUY ? "BUY" : "SELL",
            price, sl, tp, rr, currentProbability * 100));
      tradesToday++;
   }
   else
   {
      Print("✗ Order failed: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Manage positions with SDEV-based exits                           |
//+------------------------------------------------------------------+
void ManagePositions()
{
   double sessionOpen = iOpen(_Symbol, PERIOD_D1, 0);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      double currentPrice = iClose(_Symbol, InpTimeframe, 0);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Check SDEV reversion signals
      double reversionProb = nqStats.GetReversionProbability(currentPrice, sessionOpen);
      
      if(reversionProb > 0.85)  // 85%+ reversion probability
      {
         // Close position if near extreme SDEV level
         if(posType == POSITION_TYPE_BUY && currentPrice > sessionOpen)
         {
            Print("High reversion probability (", reversionProb * 100, "%) - Closing LONG");
            trade.PositionClose(ticket);
            continue;
         }
         else if(posType == POSITION_TYPE_SELL && currentPrice < sessionOpen)
         {
            Print("High reversion probability (", reversionProb * 100, "%) - Closing SHORT");
            trade.PositionClose(ticket);
            continue;
         }
      }
      
      // Traditional break-even management
      double atr = indicators.GetATR(14, 1);
      double beDistance = atr * 0.5;
      
      if(posType == POSITION_TYPE_BUY)
      {
         if(currentPrice > openPrice + beDistance && currentSL < openPrice)
         {
            trade.PositionModify(ticket, openPrice + (atr * 0.1), currentTP);
            Print("Position moved to break-even: ", ticket);
         }
      }
      else
      {
         if(currentPrice < openPrice - beDistance && currentSL > openPrice)
         {
            trade.PositionModify(ticket, openPrice - (atr * 0.1), currentTP);
            Print("Position moved to break-even: ", ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update dashboard with NQ Stats info                              |
//+------------------------------------------------------------------+
void UpdateDashboardWithStats()
{
   dashboard.Update(dailyProfit, tradesToday, CalculateWinRate());
   
   // Add NQ Stats info to comment
   if(InpShowNQStats)
   {
      string statsInfo = "\n\n=== NQ STATS ===\n";
      statsInfo += StringFormat("Bias: %s\n", 
                   currentBias > 0 ? "BULLISH" : currentBias < 0 ? "BEARISH" : "NEUTRAL");
      statsInfo += StringFormat("Probability: %.1f%%\n", currentProbability * 100);
      statsInfo += StringFormat("Quality: %s", nqStats.GetProbabilityString(currentProbability));
      
      Comment(statsInfo);
   }
}

//+------------------------------------------------------------------+
//| Helper functions (same as v1)                                    |
//+------------------------------------------------------------------+

bool IsWithinTradingHours()
{
   MqlDateTime time_struct;
   TimeCurrent(time_struct);
   
   int currentMinutes = time_struct.hour * 60 + time_struct.min;
   int startMinutes = 9 * 60 + 30;  // 9:30am
   int endMinutes = 16 * 60;        // 4:00pm
   
   return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
}

void UpdateDailyTracking()
{
   datetime now = TimeCurrent();
   datetime currentDayStart = now - (now % 86400);
   
   if(currentDayStart != todayStart)
   {
      Print("=== New Trading Day ===");
      Print("Previous Day P&L: $", DoubleToString(dailyProfit, 2));
      Print("Previous Day Trades: ", tradesToday);
      
      dailyProfit = 0.0;
      tradesToday = 0;
      todayStart = currentDayStart;
      nqStats.ResetDaily();
   }
   
   // Calculate current daily profit
   dailyProfit = 0.0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            dailyProfit += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   HistorySelect(todayStart, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) == _Symbol)
      {
         dailyProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      }
   }
}

double CalculateWinRate()
{
   int wins = 0;
   int total = 0;
   
   HistorySelect(todayStart, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) == _Symbol)
      {
         if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            total++;
            if(HistoryDealGetDouble(dealTicket, DEAL_PROFIT) > 0)
               wins++;
         }
      }
   }
   
   return total > 0 ? (double)wins / total * 100.0 : 0.0;
}

void OnDeinit(const int reason)
{
   Print("=== MNQ ScalpMaster v2 Stopped ===");
   Print("Total Trades Today: ", tradesToday);
   Print("Daily P&L: $", DoubleToString(dailyProfit, 2));
   
   if(InpShowDashboard)
      dashboard.Destroy();
}
//+------------------------------------------------------------------+
