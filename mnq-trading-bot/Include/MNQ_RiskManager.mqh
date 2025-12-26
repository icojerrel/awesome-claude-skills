//+------------------------------------------------------------------+
//|                                         MNQ_RiskManager.mqh      |
//|                              Advanced Risk Management Library    |
//+------------------------------------------------------------------+
#property copyright "MNQ ScalpMaster"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Risk Manager Class                                                |
//+------------------------------------------------------------------+
class MNQ_RiskManager
{
private:
   double   m_riskPercent;        // Risk per trade as % of equity
   double   m_maxDailyLoss;       // Max daily loss as % of equity
   int      m_maxOpenTrades;      // Maximum simultaneous positions
   double   m_accountEquity;      // Current account equity
   
public:
   //--- Constructor
   MNQ_RiskManager() : m_riskPercent(1.0), m_maxDailyLoss(3.0), m_maxOpenTrades(3) {}
   
   //--- Initialization
   void Init(double riskPercent, double maxDailyLoss, int maxOpenTrades)
   {
      m_riskPercent = riskPercent;
      m_maxDailyLoss = maxDailyLoss;
      m_maxOpenTrades = maxOpenTrades;
      m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      Print("Risk Manager Initialized:");
      Print("  - Risk Per Trade: ", m_riskPercent, "%");
      Print("  - Max Daily Loss: ", m_maxDailyLoss, "%");
      Print("  - Max Open Trades: ", m_maxOpenTrades);
      Print("  - Account Equity: $", m_accountEquity);
   }
   
   //--- Calculate position size based on risk
   double CalculatePositionSize(double stopLossPoints)
   {
      if(stopLossPoints <= 0)
      {
         Print("Invalid stop loss points: ", stopLossPoints);
         return 0.0;
      }
      
      // Update equity
      m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      // Calculate risk amount in dollars
      double riskAmount = m_accountEquity * (m_riskPercent / 100.0);
      
      // Get contract value per point
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double pointValue = tickValue / tickSize;
      
      // Calculate lot size
      double lotSize = riskAmount / (stopLossPoints * pointValue);
      
      // Apply lot size limits
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      // Normalize to lot step
      lotSize = MathFloor(lotSize / lotStep) * lotStep;
      
      // Clamp to min/max
      lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
      
      Print("Position Size Calculation:");
      Print("  - Risk Amount: $", riskAmount);
      Print("  - SL Points: ", stopLossPoints);
      Print("  - Lot Size: ", lotSize);
      
      return lotSize;
   }
   
   //--- Check if daily loss limit is exceeded
   bool CheckDailyLossLimit(double currentDailyProfit)
   {
      double maxLossAmount = m_accountEquity * (m_maxDailyLoss / 100.0);
      
      if(currentDailyProfit < -maxLossAmount)
      {
         Print("DAILY LOSS LIMIT REACHED!");
         Print("  - Current Daily Loss: $", -currentDailyProfit);
         Print("  - Max Allowed Loss: $", maxLossAmount);
         return false;
      }
      
      return true;
   }
   
   //--- Check if max open trades exceeded
   bool CheckMaxOpenTrades()
   {
      int openPositions = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
               openPositions++;
         }
      }
      
      if(openPositions >= m_maxOpenTrades)
      {
         Print("Max open trades reached: ", openPositions, "/", m_maxOpenTrades);
         return false;
      }
      
      return true;
   }
   
   //--- Calculate risk-reward ratio for a trade
   double CalculateRiskReward(double entryPrice, double stopLoss, double takeProfit, ENUM_ORDER_TYPE orderType)
   {
      double risk, reward;
      
      if(orderType == ORDER_TYPE_BUY)
      {
         risk = entryPrice - stopLoss;
         reward = takeProfit - entryPrice;
      }
      else
      {
         risk = stopLoss - entryPrice;
         reward = entryPrice - takeProfit;
      }
      
      if(risk <= 0) return 0.0;
      return reward / risk;
   }
   
   //--- Get current risk exposure
   double GetCurrentRiskExposure()
   {
      double totalRisk = 0.0;
      
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double stopLoss = PositionGetDouble(POSITION_SL);
               double volume = PositionGetDouble(POSITION_VOLUME);
               
               double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
               double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
               
               double riskPoints = MathAbs(openPrice - stopLoss);
               double riskAmount = (riskPoints / tickSize) * tickValue * volume;
               
               totalRisk += riskAmount;
            }
         }
      }
      
      return totalRisk;
   }
   
   //--- Get percentage of equity at risk
   double GetRiskPercentage()
   {
      double totalRisk = GetCurrentRiskExposure();
      m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      if(m_accountEquity <= 0) return 0.0;
      return (totalRisk / m_accountEquity) * 100.0;
   }
};
//+------------------------------------------------------------------+
