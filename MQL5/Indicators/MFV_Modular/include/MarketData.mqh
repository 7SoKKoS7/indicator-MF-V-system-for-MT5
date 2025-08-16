#ifndef __MFV_MARKETDATA_MQH__
#define __MFV_MARKETDATA_MQH__

class MarketData {
   string           symbol;
   ENUM_TIMEFRAMES  baseTimeframe;

   // Ограничение окна истории для Copy* (работаем только с закрытыми барами: shift>=1)
   enum { HISTORY_LIMIT = 1000 };

   // Кэш OHLC для M5/M15/H1 (только закрытые бары, shift=1..)
   datetime m5_time[];   double m5_open[];  double m5_high[];  double m5_low[];  double m5_close[];
   datetime m15_time[];  double m15_open[]; double m15_high[]; double m15_low[]; double m15_close[];
   datetime h1_time[];   double h1_open[];  double h1_high[];  double h1_low[];  double h1_close[];

   // Кэш хендлов индикаторов: ключ (tf,period) → handle
   struct IndiKey { ENUM_TIMEFRAMES tf; int period; };
   IndiKey atrKeys[]; int atrHandles[];
   IndiKey emaKeys[]; int emaHandles[];
   IndiKey rsiKeys[]; int rsiHandles[];

   void ensureSeriesFlags()
   {
      ArraySetAsSeries(m5_time,   true); ArraySetAsSeries(m5_open,  true); ArraySetAsSeries(m5_high,  true); ArraySetAsSeries(m5_low,  true); ArraySetAsSeries(m5_close,  true);
      ArraySetAsSeries(m15_time,  true); ArraySetAsSeries(m15_open, true); ArraySetAsSeries(m15_high, true); ArraySetAsSeries(m15_low,  true); ArraySetAsSeries(m15_close, true);
      ArraySetAsSeries(h1_time,   true); ArraySetAsSeries(h1_open,  true); ArraySetAsSeries(h1_high,  true); ArraySetAsSeries(h1_low,  true); ArraySetAsSeries(h1_close,  true);
   }

   int findHandleIndex(IndiKey &keys[], int &handles[], ENUM_TIMEFRAMES tf, int period) const
   {
      int n = ArraySize(keys);
      for(int i=0; i<n; ++i)
      {
         if(keys[i].tf == tf && keys[i].period == period)
            return i;
      }
      return -1;
   }

   int ensureATRHandle(ENUM_TIMEFRAMES tf, int period)
   {
      int idx = findHandleIndex(atrKeys, atrHandles, tf, period);
      if(idx >= 0)
      {
         int h = atrHandles[idx];
         if(h != INVALID_HANDLE)
         {
            int bc = BarsCalculated(h);
            if(bc >= 0) return h;
            IndicatorRelease(h);
         }
      }
      int hnew = iATR(symbol, tf, period);
      if(idx < 0)
      {
         int n = ArraySize(atrKeys);
         ArrayResize(atrKeys, n+1);
         ArrayResize(atrHandles, n+1);
         atrKeys[n].tf = tf; atrKeys[n].period = period; atrHandles[n] = hnew;
      }
      else
      {
         atrHandles[idx] = hnew;
      }
      return hnew;
   }

   int ensureEMAHandle(ENUM_TIMEFRAMES tf, int period)
   {
      int idx = findHandleIndex(emaKeys, emaHandles, tf, period);
      if(idx >= 0)
      {
         int h = emaHandles[idx];
         if(h != INVALID_HANDLE)
         {
            int bc = BarsCalculated(h);
            if(bc >= 0) return h;
            IndicatorRelease(h);
         }
      }
      int hnew = iMA(symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE);
      if(idx < 0)
      {
         int n = ArraySize(emaKeys);
         ArrayResize(emaKeys, n+1);
         ArrayResize(emaHandles, n+1);
         emaKeys[n].tf = tf; emaKeys[n].period = period; emaHandles[n] = hnew;
      }
      else
      {
         emaHandles[idx] = hnew;
      }
      return hnew;
   }

   int ensureRSIHandle(ENUM_TIMEFRAMES tf, int period)
   {
      int idx = findHandleIndex(rsiKeys, rsiHandles, tf, period);
      if(idx >= 0)
      {
         int h = rsiHandles[idx];
         if(h != INVALID_HANDLE)
         {
            int bc = BarsCalculated(h);
            if(bc >= 0) return h;
            IndicatorRelease(h);
         }
      }
      int hnew = iRSI(symbol, tf, period, PRICE_CLOSE);
      if(idx < 0)
      {
         int n = ArraySize(rsiKeys);
         ArrayResize(rsiKeys, n+1);
         ArrayResize(rsiHandles, n+1);
         rsiKeys[n].tf = tf; rsiKeys[n].period = period; rsiHandles[n] = hnew;
      }
      else
      {
         rsiHandles[idx] = hnew;
      }
      return hnew;
   }
public:
   void Init(const string s, ENUM_TIMEFRAMES tf)
   {
      symbol = s; baseTimeframe = tf; ensureSeriesFlags();
   }

   // Обновляет кеш рядов для M5/M15/H1, только закрытые бары (shift=1)
   bool Refresh()
   {
      ensureSeriesFlags();
      bool ok = true;

      // M5 — начиная с закрытого бара (shift=1)
      int c1 = CopyTime(symbol, PERIOD_M5, 1, HISTORY_LIMIT, m5_time);   ok = ok && (c1 > 0);
      int c2 = CopyOpen(symbol, PERIOD_M5, 1, HISTORY_LIMIT, m5_open);   ok = ok && (c2 > 0);
      int c3 = CopyHigh(symbol, PERIOD_M5, 1, HISTORY_LIMIT, m5_high);   ok = ok && (c3 > 0);
      int c4 = CopyLow(symbol,  PERIOD_M5, 1, HISTORY_LIMIT, m5_low);    ok = ok && (c4 > 0);
      int c5 = CopyClose(symbol,PERIOD_M5, 1, HISTORY_LIMIT, m5_close);  ok = ok && (c5 > 0);

      // M15
      c1 = CopyTime(symbol, PERIOD_M15, 1, HISTORY_LIMIT, m15_time);     ok = ok && (c1 > 0);
      c2 = CopyOpen(symbol, PERIOD_M15, 1, HISTORY_LIMIT, m15_open);     ok = ok && (c2 > 0);
      c3 = CopyHigh(symbol, PERIOD_M15, 1, HISTORY_LIMIT, m15_high);     ok = ok && (c3 > 0);
      c4 = CopyLow(symbol,  PERIOD_M15, 1, HISTORY_LIMIT, m15_low);      ok = ok && (c4 > 0);
      c5 = CopyClose(symbol,PERIOD_M15, 1, HISTORY_LIMIT, m15_close);    ok = ok && (c5 > 0);

      // H1
      c1 = CopyTime(symbol, PERIOD_H1, 1, HISTORY_LIMIT, h1_time);       ok = ok && (c1 > 0);
      c2 = CopyOpen(symbol, PERIOD_H1, 1, HISTORY_LIMIT, h1_open);       ok = ok && (c2 > 0);
      c3 = CopyHigh(symbol, PERIOD_H1, 1, HISTORY_LIMIT, h1_high);       ok = ok && (c3 > 0);
      c4 = CopyLow(symbol,  PERIOD_H1, 1, HISTORY_LIMIT, h1_low);        ok = ok && (c4 > 0);
      c5 = CopyClose(symbol,PERIOD_H1, 1, HISTORY_LIMIT, h1_close);      ok = ok && (c5 > 0);

      return ok;
   }

   // Количество доступных закрытых баров
   int BarsTF(ENUM_TIMEFRAMES tf)
   {
      int total = (int)Bars(symbol, tf);
      return (total > 1 ? total - 1 : 0);
   }

   // Индикаторы по закрытым барам (shift>=1)
   double ATR(ENUM_TIMEFRAMES tf, int period, int shift=1)
   {
      int s = (shift <= 0 ? 1 : shift);
      int h = ensureATRHandle(tf, period);
      if(h == INVALID_HANDLE) return 0.0;
      double buf[]; ArraySetAsSeries(buf, true);
      int copied = CopyBuffer(h, 0, s, HISTORY_LIMIT, buf);
      if(copied <= 0) return 0.0;
      return buf[0];
   }

   double EMA(ENUM_TIMEFRAMES tf, int period, int shift=1)
   {
      int s = (shift <= 0 ? 1 : shift);
      int h = ensureEMAHandle(tf, period);
      if(h == INVALID_HANDLE) return 0.0;
      double buf[]; ArraySetAsSeries(buf, true);
      int copied = CopyBuffer(h, 0, s, HISTORY_LIMIT, buf);
      if(copied <= 0) return 0.0;
      return buf[0];
   }

   double RSI(ENUM_TIMEFRAMES tf, int period, int shift=1)
   {
      int s = (shift <= 0 ? 1 : shift);
      int h = ensureRSIHandle(tf, period);
      if(h == INVALID_HANDLE) return 50.0;
      double buf[]; ArraySetAsSeries(buf, true);
      int copied = CopyBuffer(h, 0, s, HISTORY_LIMIT, buf);
      if(copied <= 0) return 50.0;
      return buf[0];
   }
};

#endif // __MFV_MARKETDATA_MQH__
