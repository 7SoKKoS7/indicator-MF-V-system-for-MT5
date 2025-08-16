#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

#include "ZigZagAdapter.mqh"
#include "SimpleSwing.mqh"

class MarketData; // forward decl
class MFVConfig;  // forward decl

struct DualPivot
  {
   double   High;
   double   Low;
   int      lastSwing;
   datetime ts;

   DualPivot(){ High=0.0; Low=0.0; lastSwing=0; ts=0; }
   DualPivot(const DualPivot &o){ High=o.High; Low=o.Low; lastSwing=o.lastSwing; ts=o.ts; }
  };

class PivotEngine {
   MarketData *md; MFVConfig *cfg;
   ZigZagAdapter zz;
   DualPivot m_h1, m_m15, m_m5;
public:
   void Init(MarketData *m, MFVConfig *c){ md=m; cfg=c; zz.Init(_Symbol, cfg); }
   // Back-compat для существующих вызовов с ссылками
   void Init(MarketData &m, MFVConfig &c){ Init(&m, &c); }
   void UpdateAllTF(){
      zz.EnsureAll();
      m_h1 = computeForTf(PERIOD_H1);
      m_m15 = computeForTf(PERIOD_M15);
      m_m5 = computeForTf(PERIOD_M5);
   }
   DualPivot Get(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1) return m_h1;
      if(tf==PERIOD_M5) return m_m5;
      return m_m15;
   }
private:
   DualPivot computeForTf(ENUM_TIMEFRAMES tf)
   {
      DualPivot dp;
      // Только закрытый бар (shift=1)
      if(cfg!=NULL && cfg.PivotAlgorithm==Pivot_ZigZag)
      {
         int h = zz.Handle(tf);
         if(h != INVALID_HANDLE)
         {
            const int N = 300;
            // ZigZag_Fixed: SetIndexBuffer(0=main,1=HighMap,2=LowMap)
            const int BUF_ZZ = 0, BUF_HIGH = 1, BUF_LOW = 2;
            double highBuf[]; double lowBuf[];
            ArraySetAsSeries(highBuf, true); ArraySetAsSeries(lowBuf, true);
            int hc = CopyBuffer(h, BUF_HIGH, 1, N, highBuf);
            int lc = CopyBuffer(h, BUF_LOW,  1, N, lowBuf);
            if(hc>0 || lc>0)
            {
               double pivotH = 0.0, pivotL = 0.0;
               int shiftH = 0, shiftL = 0;
               bool foundH = false, foundL = false;
               // ZigZag кладёт 0.0 при отсутствии точки, поэтому проверяем > 0.0
               for(int i=0; i<hc; ++i){ if(highBuf[i] > 0.0){ pivotH = highBuf[i]; shiftH = 1+i; foundH=true; break; } }
               for(int i=0; i<lc; ++i){ if(lowBuf[i]  > 0.0){ pivotL = lowBuf[i];  shiftL = 1+i; foundL=true; break; } }

               int lastSwing = 0;
               if(foundH && foundL){ if(shiftH < shiftL) lastSwing = +1; else if(shiftL < shiftH) lastSwing = -1; else lastSwing = 0; }
               else if(foundH) lastSwing = +1;
               else if(foundL) lastSwing = -1;

               int shiftTs = 0;
               if(foundH && foundL) shiftTs = (shiftH < shiftL ? shiftH : shiftL);
               else if(foundH) shiftTs = shiftH;
               else if(foundL) shiftTs = shiftL;

               datetime ts = (shiftTs>0 ? iTime(_Symbol, tf, shiftTs) : (datetime)0);

               dp.High = pivotH;
               dp.Low  = pivotL;
               dp.lastSwing = lastSwing;
               dp.ts = ts;
               return dp;
            }
         }
      }

      // Фоллбек — простая заготовка
      SwingPivot sp(SimpleSwing::Compute(tf));
      dp.High = sp.High; dp.Low = sp.Low; dp.lastSwing = sp.lastSwing; dp.ts = sp.ts;
      return dp;
   }
};

#endif // __MFV_PIVOTENGINE_MQH__
