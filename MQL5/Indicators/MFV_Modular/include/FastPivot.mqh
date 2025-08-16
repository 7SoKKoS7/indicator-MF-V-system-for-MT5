#ifndef __MFV_FASTPIVOT_MQH__
#define __MFV_FASTPIVOT_MQH__

#include "Config.mqh"
#include "MarketData.mqh"
#include "PivotEngine.mqh" // для DualPivot

namespace FastPivot
  {
  // Быстрый приблизительный расчёт последних H/L по закрытым барам без iCustom.
  // Реализует урезанный ZigZag: берёт последний локальный максимум/минимум с ограничением по глубине/девиации.
  // Возвращает true, если удалось найти обе точки.
  bool Compute(ENUM_TIMEFRAMES tf, const MFVConfig &cfg, MarketData &md, DualPivot &out)
    {
     // 1) Обновить данные по нужному ТФ (закрытые бары)
     if(!md.Refresh()) return false;

     // 2) Считать ценовые ряды на закрытых барах
     const int N = 600; // окно просмотра — маленькое, быстрое
     double hi[], lo[];
     ArraySetAsSeries(hi, true);
     ArraySetAsSeries(lo, true);
     int gotH = CopyHigh(_Symbol, tf, 1, N, hi);
     int gotL = CopyLow (_Symbol, tf, 1, N, lo);
     if(gotH <= 0 || gotL <= 0) return false;

     // 3) Параметры "похожи" на ZigZag
     const int depth     = (int)MathMax(3, cfg.ZZ_Depth);
     const int backstep  = (int)MathMax(1, cfg.ZZ_Backstep);
     const double devPts = MathMax(_Point, cfg.ZZ_Deviation * _Point);

     // 4) Найти последний локальный максимум и минимум
     int shH = -1, shL = -1;
     double pH = 0.0, pL = 0.0;

     // Поиск max: точка должна быть выше соседей в окне backstep и не ближе depth к предыдущей
     for(int i=0; i<gotH-depth; ++i)
       {
        bool isPeak = true;
        for(int k=1; k<=backstep && i+k<gotH; ++k)
          if(hi[i] <= hi[i+k]) { isPeak=false; break; }
        if(!isPeak) continue;
        // Девиация: пик должен выделяться от последнего найденного минимума
        if(pL>0.0 && (hi[i]-pL) < devPts) continue;
        pH = hi[i]; shH = 1+i; break;
       }

     // Поиск min
     for(int i=0; i<gotL-depth; ++i)
       {
        bool isTrough = true;
        for(int k=1; k<=backstep && i+k<gotL; ++k)
          if(lo[i] >= lo[i+k]) { isTrough=false; break; }
        if(!isTrough) continue;
        if(pH>0.0 && (pH-lo[i]) < devPts) continue;
        pL = lo[i]; shL = 1+i; break;
       }

     if(pH<=0.0 && pL<=0.0) return false;

     DualPivot d; d.High=pH; d.Low=pL; d.lastSwing=0; d.ts=(datetime)TimeCurrent();
     out = d;
     return true;
    }
  }
#endif


