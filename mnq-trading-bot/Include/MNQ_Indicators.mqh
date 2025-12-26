//+------------------------------------------------------------------+
//|                                          MNQ_Indicators.mqh       |
//|                            Technical Indicators Library          |
//+------------------------------------------------------------------+
#property copyright "MNQ ScalpMaster"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Indicators Class                                                  |
//+------------------------------------------------------------------+
class MNQ_Indicators
{
private:
   int      m_fastEMAHandle;
   int      m_slowEMAHandle;
   int      m_rsiHandle;
   int      m_atrHandle;
   int      m_trendEMAHandle;
   
   int      m_fastEMAPeriod;
   int      m_slowEMAPeriod;
   int      m_rsiPeriod;
   int      m_trendEMAPeriod;
   
public:
   //--- Constructor
   MNQ_Indicators() : m_fastEMAHandle(INVALID_HANDLE), m_slowEMAHandle(INVALID_HANDLE),
                      m_rsiHandle(INVALID_HANDLE), m_atrHandle(INVALID_HANDLE),
                      m_trendEMAHandle(INVALID_HANDLE) {}
   
   //--- Destructor
   ~MNQ_Indicators()
   {
      if(m_fastEMAHandle != INVALID_HANDLE) IndicatorRelease(m_fastEMAHandle);
      if(m_slowEMAHandle != INVALID_HANDLE) IndicatorRelease(m_slowEMAHandle);
      if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_trendEMAHandle != INVALID_HANDLE) IndicatorRelease(m_trendEMAHandle);
   }
   
   //--- Initialization
   bool Init(int fastEMA, int slowEMA, int rsiPeriod, int trendEMA)
   {
      m_fastEMAPeriod = fastEMA;
      m_slowEMAPeriod = slowEMA;
      m_rsiPeriod = rsiPeriod;
      m_trendEMAPeriod = trendEMA;
      
      // Create indicator handles
      m_fastEMAHandle = iMA(_Symbol, PERIOD_CURRENT, fastEMA, 0, MODE_EMA, PRICE_CLOSE);
      m_slowEMAHandle = iMA(_Symbol, PERIOD_CURRENT, slowEMA, 0, MODE_EMA, PRICE_CLOSE);
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE);
      m_atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
      m_trendEMAHandle = iMA(_Symbol, PERIOD_CURRENT, trendEMA, 0, MODE_EMA, PRICE_CLOSE);
      
      // Verify handles
      if(m_fastEMAHandle == INVALID_HANDLE || m_slowEMAHandle == INVALID_HANDLE ||
         m_rsiHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE ||
         m_trendEMAHandle == INVALID_HANDLE)
      {
         Print("Error creating indicator handles!");
         return false;
      }
      
      Print("Indicators Initialized:");
      Print("  - Fast EMA: ", fastEMA);
      Print("  - Slow EMA: ", slowEMA);
      Print("  - RSI: ", rsiPeriod);
      Print("  - Trend EMA: ", trendEMA);
      
      return true;
   }
   
   //--- Get EMA value
   double GetEMA(int period, int shift)
   {
      int handle = (period == m_fastEMAPeriod) ? m_fastEMAHandle :
                   (period == m_slowEMAPeriod) ? m_slowEMAHandle :
                   (period == m_trendEMAPeriod) ? m_trendEMAHandle : INVALID_HANDLE;
      
      if(handle == INVALID_HANDLE) return 0.0;
      
      double buffer[1];
      if(CopyBuffer(handle, 0, shift, 1, buffer) != 1)
      {
         Print("Error copying EMA buffer");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   //--- Get RSI value
   double GetRSI(int shift)
   {
      if(m_rsiHandle == INVALID_HANDLE) return 50.0;
      
      double buffer[1];
      if(CopyBuffer(m_rsiHandle, 0, shift, 1, buffer) != 1)
      {
         Print("Error copying RSI buffer");
         return 50.0;
      }
      
      return buffer[0];
   }
   
   //--- Get ATR value
   double GetATR(int period, int shift)
   {
      if(m_atrHandle == INVALID_HANDLE) return 0.0;
      
      double buffer[1];
      if(CopyBuffer(m_atrHandle, 0, shift, 1, buffer) != 1)
      {
         Print("Error copying ATR buffer");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   //--- Check if volume is high
   bool IsVolumeHigh(double multiplier)
   {
      long currentVolume[];
      long avgVolume[];
      
      // Get current volume
      if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 1, 1, currentVolume) != 1)
         return false;
      
      // Get average volume of last 20 bars
      if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 2, 20, avgVolume) != 20)
         return false;
      
      // Calculate average
      long sum = 0;
      for(int i = 0; i < 20; i++)
         sum += avgVolume[i];
      double average = (double)sum / 20.0;
      
      // Check if current volume is above threshold
      return (currentVolume[0] > average * multiplier);
   }
   
   //--- Detect EMA crossover
   int DetectEMACrossover()
   {
      double fastCurrent = GetEMA(m_fastEMAPeriod, 1);
      double slowCurrent = GetEMA(m_slowEMAPeriod, 1);
      double fastPrev = GetEMA(m_fastEMAPeriod, 2);
      double slowPrev = GetEMA(m_slowEMAPeriod, 2);
      
      // Bullish crossover
      if(fastPrev <= slowPrev && fastCurrent > slowCurrent)
         return 1;
      
      // Bearish crossover
      if(fastPrev >= slowPrev && fastCurrent < slowCurrent)
         return -1;
      
      // No crossover
      return 0;
   }
   
   //--- Get trend direction
   int GetTrendDirection()
   {
      double trendEMA = GetEMA(m_trendEMAPeriod, 1);
      double close = iClose(_Symbol, PERIOD_CURRENT, 1);
      
      if(close > trendEMA * 1.001)  // 0.1% buffer to avoid whipsaws
         return 1;  // Uptrend
      else if(close < trendEMA * 0.999)
         return -1; // Downtrend
      
      return 0;  // Sideways
   }
   
   //--- Calculate momentum
   double GetMomentum(int period)
   {
      double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      double pastClose = iClose(_Symbol, PERIOD_CURRENT, period + 1);
      
      if(pastClose == 0) return 0.0;
      return ((currentClose - pastClose) / pastClose) * 100.0;
   }
   
   //--- Check if price is making higher highs
   bool IsHigherHigh(int lookback)
   {
      double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      
      for(int i = 2; i <= lookback + 1; i++)
      {
         if(iHigh(_Symbol, PERIOD_CURRENT, i) > currentHigh)
            return false;
      }
      
      return true;
   }
   
   //--- Check if price is making lower lows
   bool IsLowerLow(int lookback)
   {
      double currentLow = iLow(_Symbol, PERIOD_CURRENT, 1);
      
      for(int i = 2; i <= lookback + 1; i++)
      {
         if(iLow(_Symbol, PERIOD_CURRENT, i) < currentLow)
            return false;
      }
      
      return true;
   }
};
//+------------------------------------------------------------------+
