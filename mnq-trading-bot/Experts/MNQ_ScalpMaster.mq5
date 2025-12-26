//+------------------------------------------------------------------+
//|                                            MNQ_ScalpMaster.mq5   |
//|                        Advanced Scalping Bot for MNQ Futures     |
//|                                      Version 1.0 - Dec 2025      |
//+------------------------------------------------------------------+
#property copyright "MNQ ScalpMaster"
#property version   "1.00"
#property strict

// Include custom libraries
#include <Trade\Trade.mqh>
#include "../Include/MNQ_RiskManager.mqh"
#include "../Include/MNQ_Indicators.mqh"
#include "../Include/MNQ_Dashboard.mqh"

//--- Input parameters
input group "=== STRATEGY SETTINGS ==="
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;           // Trading Timeframe
input int    InpFastEMA = 9;                               // Fast EMA Period
input int    InpSlowEMA = 21;                              // Slow EMA Period
input int    InpRSIPeriod = 14;                            // RSI Period
input double InpRSIOverbought = 70.0;                      // RSI Overbought Level
input double InpRSIOversold = 30.0;                        // RSI Oversold Level

input group "=== RISK MANAGEMENT ==="
input double InpRiskPercent = 1.0;                         // Risk Per Trade (%)
input double InpMaxDailyLoss = 3.0;                        // Max Daily Loss (%)
input int    InpMaxOpenTrades = 3;                         // Max Open Trades
input double InpATRMultiplier = 2.0;                       // ATR Multiplier for SL/TP
input double InpRewardRiskRatio = 2.0;                     // Reward:Risk Ratio

input group "=== TRADE FILTERS ==="
input bool   InpUseTrendFilter = true;                     // Use Trend Filter
input int    InpTrendEMA = 50;                             // Trend EMA Period
input bool   InpUseVolumeFilter = true;                    // Use Volume Filter
input double InpMinVolumeMultiplier = 1.2;                 // Min Volume Multiplier

input group "=== TIME FILTERS ==="
input string InpStartTime = "09:30";                       // Start Trading Time
input string InpEndTime = "16:00";                         // End Trading Time
input bool   InpAvoidNews = true;                          // Avoid Major News

input group "=== DISPLAY ==="
input bool   InpShowDashboard = true;                      // Show Performance Dashboard
input color  InpDashboardColor = clrLime;                  // Dashboard Color

//--- Global variables
CTrade trade;
MNQ_RiskManager riskManager;
MNQ_Indicators indicators;
MNQ_Dashboard dashboard;

datetime lastBarTime = 0;
double dailyProfit = 0.0;
int tradesT

oday = 0;
datetime todayStart;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== MNQ ScalpMaster EA Initialized ===");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: ", EnumToString(InpTimeframe));
   Print("Risk Per Trade: ", InpRiskPercent, "%");
   
   // Initialize components
   riskManager.Init(InpRiskPercent, InpMaxDailyLoss, InpMaxOpenTrades);
   indicators.Init(InpFastEMA, InpSlowEMA, InpRSIPeriod, InpTrendEMA);
   
   if(InpShowDashboard)
      dashboard.Init(InpDashboardColor);
   
   // Set trading parameters
   trade.SetExpertMagicNumber(20251226);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Initialize daily tracking
   todayStart = TimeCurrent();
   todayStart = todayStart - (todayStart % 86400); // Start of day
   
   Print("EA Ready to Trade!");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== MNQ ScalpMaster EA Stopped ===");
   Print("Total Trades Today: ", tradesToday);
   Print("Daily P&L: $", DoubleToString(dailyProfit, 2));
   
   if(InpShowDashboard)
      dashboard.Destroy();
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
   
   // Check for new trade signals
   CheckTradeSignals();
   
   // Update dashboard
   if(InpShowDashboard)
      dashboard.Update(dailyProfit, tradesToday, CalculateWinRate());
}

//+------------------------------------------------------------------+
//| Check for trade entry signals                                    |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
   // Get current indicator values
   double fastEMA = indicators.GetEMA(InpFastEMA, 1);
   double slowEMA = indicators.GetEMA(InpSlowEMA, 1);
   double rsi = indicators.GetRSI(1);
   double atr = indicators.GetATR(14, 1);
   
   // Get previous values for crossover detection
   double prevFastEMA = indicators.GetEMA(InpFastEMA, 2);
   double prevSlowEMA = indicators.GetEMA(InpSlowEMA, 2);
   
   // Check trend filter
   bool trendUp = true;
   bool trendDown = true;
   if(InpUseTrendFilter)
   {
      double trendEMA = indicators.GetEMA(InpTrendEMA, 1);
      double close = iClose(_Symbol, InpTimeframe, 1);
      trendUp = close > trendEMA;
      trendDown = close < trendEMA;
   }
   
   // Check volume filter
   bool volumeOK = true;
   if(InpUseVolumeFilter)
   {
      volumeOK = indicators.IsVolumeHigh(InpMinVolumeMultiplier);
   }
   
   // === LONG SIGNAL ===
   // EMA crossover + RSI oversold + Trend up + Volume
   if(prevFastEMA <= prevSlowEMA && fastEMA > slowEMA &&  // Bullish crossover
      rsi < InpRSIOversold &&                              // Oversold
      trendUp &&                                           // Trend confirmation
      volumeOK)                                            // Volume confirmation
   {
      OpenTrade(ORDER_TYPE_BUY, atr);
   }
   
   // === SHORT SIGNAL ===
   // EMA crossover + RSI overbought + Trend down + Volume
   if(prevFastEMA >= prevSlowEMA && fastEMA < slowEMA &&  // Bearish crossover
      rsi > InpRSIOverbought &&                            // Overbought
      trendDown &&                                         // Trend confirmation
      volumeOK)                                            // Volume confirmation
   {
      OpenTrade(ORDER_TYPE_SELL, atr);
   }
}

//+------------------------------------------------------------------+
//| Open a new trade                                                 |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, double atr)
{
   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) 
                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Calculate position size based on risk
   double stopLoss = atr * InpATRMultiplier;
   double lotSize = riskManager.CalculatePositionSize(stopLoss);
   
   if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("Lot size too small: ", lotSize);
      return;
   }
   
   // Calculate SL and TP
   double sl, tp;
   if(orderType == ORDER_TYPE_BUY)
   {
      sl = price - stopLoss;
      tp = price + (stopLoss * InpRewardRiskRatio);
   }
   else
   {
      sl = price + stopLoss;
      tp = price - (stopLoss * InpRewardRiskRatio);
   }
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   price = NormalizeDouble(price, _Digits);
   
   // Execute trade
   bool result = trade.PositionOpen(_Symbol, orderType, lotSize, price, sl, tp, "MNQ Scalp");
   
   if(result)
   {
      Print("✓ ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
            " order opened at ", price, 
            " | Lots: ", lotSize,
            " | SL: ", sl, 
            " | TP: ", tp);
      tradesToday++;
   }
   else
   {
      Print("✗ Order failed: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, break-even, etc.)          |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      double positionProfit = PositionGetDouble(POSITION_PROFIT);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                             : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // Move to break-even when in profit
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
      else // SELL
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
//| Check if within trading hours                                    |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
   MqlDateTime time_struct;
   TimeCurrent(time_struct);
   
   int currentMinutes = time_struct.hour * 60 + time_struct.min;
   
   // Parse start and end times
   string startParts[];
   string endParts[];
   StringSplit(InpStartTime, ':', startParts);
   StringSplit(InpEndTime, ':', endParts);
   
   int startMinutes = StringToInteger(startParts[0]) * 60 + StringToInteger(startParts[1]);
   int endMinutes = StringToInteger(endParts[0]) * 60 + StringToInteger(endParts[1]);
   
   return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
}

//+------------------------------------------------------------------+
//| Update daily tracking                                            |
//+------------------------------------------------------------------+
void UpdateDailyTracking()
{
   datetime now = TimeCurrent();
   datetime currentDayStart = now - (now % 86400);
   
   // Reset daily counters if new day
   if(currentDayStart != todayStart)
   {
      Print("=== New Trading Day ===");
      Print("Previous Day P&L: $", DoubleToString(dailyProfit, 2));
      Print("Previous Day Trades: ", tradesToday);
      
      dailyProfit = 0.0;
      tradesToday = 0;
      todayStart = currentDayStart;
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
   
   // Add closed trades profit from history
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

//+------------------------------------------------------------------+
//| Calculate win rate                                               |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
