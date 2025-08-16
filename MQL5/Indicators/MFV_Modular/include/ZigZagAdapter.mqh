// MQL5 does not support #pragma once reliably; use include guards
#ifndef __MFV_ZIGZAGADAPTER_MQH__
#define __MFV_ZIGZAGADAPTER_MQH__

#include "Config.mqh"
#include "SimpleSwing.mqh"   // fallback

class ZigZagAdapter {
   MFVConfig *cfg;
   string     sym;
   int        zzH1, zzM15, zzM5, zzH4, zzD1;
public:
   ZigZagAdapter():cfg(NULL),sym(""),zzH1(INVALID_HANDLE),zzM15(INVALID_HANDLE),zzM5(INVALID_HANDLE),zzH4(INVALID_HANDLE),zzD1(INVALID_HANDLE){}
   void Init(const string symbol, MFVConfig* c){ sym=symbol; cfg=c; }
   void EnsureAll(){
      zzH1  = ensureZZ(PERIOD_H1,  zzH1);
      zzM15 = ensureZZ(PERIOD_M15, zzM15);
      zzM5  = ensureZZ(PERIOD_M5,  zzM5);
      zzH4  = ensureZZ(PERIOD_H4,  zzH4);
      zzD1  = ensureZZ(PERIOD_D1,  zzD1);
   }
   int Handle(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1)  return zzH1;
      if(tf==PERIOD_M5)  return zzM5;
      if(tf==PERIOD_H4)  return zzH4;
      if(tf==PERIOD_D1)  return zzD1;
      return zzM15;
   }
   // Прогреть все таймфреймы, чтобы при первом рендере уже были валидные хендлы.
   // Это уменьшает задержку при первом появлении линий/данных.
   void PreWarmAll()
     {
      Ensure(PERIOD_M5);
      Ensure(PERIOD_M15);
      Ensure(PERIOD_H1);
      Ensure(PERIOD_H4);
      Ensure(PERIOD_D1);
     }
   // on-demand ensure для произвольного TF
   int Ensure(ENUM_TIMEFRAMES tf){
      if(tf==PERIOD_H1){ zzH1=ensureZZ(tf,zzH1); return zzH1; }
      if(tf==PERIOD_M15){ zzM15=ensureZZ(tf,zzM15); return zzM15; }
      if(tf==PERIOD_M5){ zzM5=ensureZZ(tf,zzM5); return zzM5; }
      if(tf==PERIOD_H4){ zzH4=ensureZZ(tf,zzH4); return zzH4; }
      if(tf==PERIOD_D1){ zzD1=ensureZZ(tf,zzD1); return zzD1; }
      return INVALID_HANDLE;
   }
private:
   int ensureZZ(ENUM_TIMEFRAMES tf, int handle)
   {
      // Если хендл уже валиден, переиспользуем
      if(handle != INVALID_HANDLE)
      {
         int bc = BarsCalculated(handle);
         if(bc >= 0) return handle;
         IndicatorRelease(handle); // пересоздадим ниже
      }

      // Порядок поиска: локальная фиксированная копия → стандартные пути MT5
      string names[] =
      {
         "MFV_Modular\\ThirdParty\\ZigZag_Fixed",
         "\\Indicators\\MFV_Modular\\ThirdParty\\ZigZag_Fixed",
         "ZigZag",
         "\\Indicators\\Examples\\ZigZag",
         "\\Indicators\\ZigZag"
      };

      for(int i=0; i<ArraySize(names); ++i)
      {
         int h = iCustom(sym, tf, names[i], cfg.ZZ_Depth, cfg.ZZ_Deviation, cfg.ZZ_Backstep);
         if(h != INVALID_HANDLE)
            return h;
      }
      return INVALID_HANDLE; // адаптер сообщит PivotEngine, который переключится на fallback
   }
};

#endif // __MFV_ZIGZAGADAPTER_MQH__


