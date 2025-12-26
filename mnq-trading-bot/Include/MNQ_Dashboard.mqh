//+------------------------------------------------------------------+
//|                                           MNQ_Dashboard.mqh       |
//|                          Performance Dashboard Library           |
//+------------------------------------------------------------------+
#property copyright "MNQ ScalpMaster"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Dashboard Class                                                   |
//+------------------------------------------------------------------+
class MNQ_Dashboard
{
private:
   color    m_color;
   string   m_labelPrefix;
   int      m_xOffset;
   int      m_yOffset;
   int      m_lineHeight;
   
public:
   //--- Constructor
   MNQ_Dashboard() : m_color(clrLime), m_xOffset(10), m_yOffset(20), m_lineHeight(18)
   {
      m_labelPrefix = "MNQ_Dashboard_";
   }
   
   //--- Initialization
   void Init(color dashColor)
   {
      m_color = dashColor;
      CreateLabels();
   }
   
   //--- Create dashboard labels
   void CreateLabels()
   {
      CreateLabel("Title", "=== MNQ SCALPMASTER ===", 0, m_color, 12, true);
      CreateLabel("Equity", "Equity: ", 1, m_color);
      CreateLabel("DailyPL", "Daily P&L: ", 2, m_color);
      CreateLabel("Trades", "Trades Today: ", 3, m_color);
      CreateLabel("WinRate", "Win Rate: ", 4, m_color);
      CreateLabel("OpenPos", "Open Positions: ", 5, m_color);
      CreateLabel("Risk", "Risk Exposure: ", 6, m_color);
      CreateLabel("Separator", "────────────────────", 7, clrGray);
      CreateLabel("Status", "Status: ", 8, m_color);
   }
   
   //--- Create single label
   void CreateLabel(string name, string text, int line, color clr, int fontSize = 9, bool bold = false)
   {
      string labelName = m_labelPrefix + name;
      int yPos = m_yOffset + (line * m_lineHeight);
      
      ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, m_xOffset);
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, yPos);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, labelName, OBJPROP_TEXT, text);
      ObjectSetString(0, labelName, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   }
   
   //--- Update dashboard
   void Update(double dailyProfit, int tradesToday, double winRate)
   {
      // Update Equity
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      UpdateLabel("Equity", StringFormat("Equity: $%s", FormatNumber(equity)));
      
      // Update Daily P&L with color
      color plColor = dailyProfit >= 0 ? clrLime : clrRed;
      string plSign = dailyProfit >= 0 ? "+" : "";
      UpdateLabel("DailyPL", StringFormat("Daily P&L: %s$%s", plSign, FormatNumber(MathAbs(dailyProfit))), plColor);
      
      // Update Trades
      UpdateLabel("Trades", StringFormat("Trades Today: %d", tradesToday));
      
      // Update Win Rate
      color wrColor = winRate >= 50 ? clrLime : clrYellow;
      UpdateLabel("WinRate", StringFormat("Win Rate: %.1f%%", winRate), wrColor);
      
      // Update Open Positions
      int openPos = CountOpenPositions();
      UpdateLabel("OpenPos", StringFormat("Open Positions: %d", openPos));
      
      // Update Risk Exposure
      double riskPct = CalculateRiskExposure();
      color riskColor = riskPct < 2.0 ? clrLime : (riskPct < 4.0 ? clrYellow : clrRed);
      UpdateLabel("Risk", StringFormat("Risk Exposure: %.2f%%", riskPct), riskColor);
      
      // Update Status
      string status = "✓ ACTIVE";
      color statusColor = clrLime;
      
      if(dailyProfit < 0)
      {
         double equity = AccountInfoDouble(ACCOUNT_EQUITY);
         double maxLoss = equity * 0.03; // 3% daily loss limit
         if(MathAbs(dailyProfit) > maxLoss * 0.8)
         {
            status = "⚠ APPROACHING LIMIT";
            statusColor = clrYellow;
         }
      }
      
      UpdateLabel("Status", StringFormat("Status: %s", status), statusColor);
   }
   
   //--- Update single label
   void UpdateLabel(string name, string text, color clr = EMPTY_VALUE)
   {
      string labelName = m_labelPrefix + name;
      ObjectSetString(0, labelName, OBJPROP_TEXT, text);
      if(clr != EMPTY_VALUE)
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
   }
   
   //--- Count open positions
   int CountOpenPositions()
   {
      int count = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
               count++;
         }
      }
      return count;
   }
   
   //--- Calculate risk exposure percentage
   double CalculateRiskExposure()
   {
      double totalRisk = 0.0;
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double stopLoss = PositionGetDouble(POSITION_SL);
               double volume = PositionGetDouble(POSITION_VOLUME);
               
               if(stopLoss > 0)
               {
                  double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
                  double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
                  
                  double riskPoints = MathAbs(openPrice - stopLoss);
                  double riskAmount = (riskPoints / tickSize) * tickValue * volume;
                  
                  totalRisk += riskAmount;
               }
            }
         }
      }
      
      return equity > 0 ? (totalRisk / equity) * 100.0 : 0.0;
   }
   
   //--- Format number with thousand separators
   string FormatNumber(double number)
   {
      string result = DoubleToString(MathAbs(number), 2);
      string formatted = "";
      int len = StringLen(result);
      int decimalPos = StringFind(result, ".");
      
      if(decimalPos == -1)
         decimalPos = len;
      
      // Add thousand separators
      for(int i = 0; i < decimalPos; i++)
      {
         if(i > 0 && (decimalPos - i) % 3 == 0)
            formatted += ",";
         formatted += StringSubstr(result, i, 1);
      }
      
      // Add decimal part
      if(decimalPos < len)
         formatted += StringSubstr(result, decimalPos);
      
      return formatted;
   }
   
   //--- Destroy dashboard
   void Destroy()
   {
      ObjectsDeleteAll(0, m_labelPrefix);
   }
};
//+------------------------------------------------------------------+
