#ifndef __MFV_FASTPIVOT_MQH__
#define __MFV_FASTPIVOT_MQH__
#include "Config.mqh"
#include "MarketData.mqh"

// Быстрый приблизительный расчёт последних H/L на закрытых барах.
// НЕТ зависимостей от PivotEngine/DualPivot, чтобы не создавать циклические include.
// Возвращает true, если удалось найти хотя бы одну точку (High или Low).
namespace FastPivot
  {
   bool Compute(ENUM_TIMEFRAMES tf,
                const MFVConfig &cfg,
                MarketData &md,
                double &outHigh,
                double &outLow,
                datetime &outTs)
     {
      outHigh = 0.0;
      outLow  = 0.0;
      outTs   = (datetime)0;

      // 1) Обновляем данные (используем закрытые бары)
      if(!md.Refresh()) return false;

      // 2) Берём небольшое окно истории — быстро и достаточно для "тёплого старта"
      const int N = 600;
      double hi[], lo[];
      ArraySetAsSeries(hi, true);
      ArraySetAsSeries(lo, true);
      const int gotH = CopyHigh(_Symbol, tf, 1, N, hi);
      const int gotL = CopyLow (_Symbol, tf, 1, N, lo);
      if(gotH <= 0 || gotL <= 0) return false;

      // 3) Параметры, аналогичные ZigZag
      const int depth     = (int)MathMax(3,  cfg.ZZ_Depth);
      const int backstep  = (int)MathMax(1,  cfg.ZZ_Backstep);
      const double devPts = MathMax(_Point,  cfg.ZZ_Deviation * _Point);

      // 4) Поиск последнего локального максимума
      int shH = -1;
      for(int i=0; i<gotH-depth; ++i)
        {
         bool peak = true;
         for(int k=1; k<=backstep && i+k<gotH; ++k)
            if(hi[i] <= hi[i+k]) { peak=false; break; }
         if(!peak) continue;
         outHigh = hi[i];
         shH = 1+i;
         break;
        }

      // 5) Поиск последнего локального минимума
      int shL = -1;
      for(int i=0; i<gotL-depth; ++i)
        {
         bool trough = true;
         for(int k=1; k<=backstep && i+k<gotL; ++k)
            if(lo[i] >= lo[i+k]) { trough=false; break; }
         if(!trough) continue;
         outLow = lo[i];
         shL = 1+i;
         break;
        }

      // 6) Грубая фильтрация по девиации, чтобы не отдавать "шум"
      if(outHigh>0.0 && outLow>0.0 && (outHigh - outLow) < devPts)
        {
         // слишком близко — оставим только более "выраженную" точку
         if(shH < shL) outLow = 0.0; else outHigh = 0.0;
        }

      if(outHigh<=0.0 && outLow<=0.0) return false;

      outTs = TimeCurrent();
      return true;
     }
  }
#endif
