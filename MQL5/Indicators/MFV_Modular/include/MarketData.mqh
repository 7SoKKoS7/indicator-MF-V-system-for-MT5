#pragma once
class MarketData {
   string sym; ENUM_TIMEFRAMES baseTf;
public:
   void Init(const string s, ENUM_TIMEFRAMES tf){ sym=s; baseTf=tf; }
   void Refresh(){ /* позже: CopyRates/CopyClose с окном, shift=1 */ }
   int  BarsTF(ENUM_TIMEFRAMES tf){ return Bars(sym, tf); }
   double ATR(ENUM_TIMEFRAMES tf, int period){ return 0.0; }
   double EMA(ENUM_TIMEFRAMES tf, int period, int shift){ return 0.0; }
   double RSI(ENUM_TIMEFRAMES tf, int period, int shift){ return 50.0; }
};


