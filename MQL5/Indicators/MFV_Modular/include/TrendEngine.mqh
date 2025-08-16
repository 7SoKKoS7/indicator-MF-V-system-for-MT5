#ifndef __MFV_TRENDENGINE_MQH__
#define __MFV_TRENDENGINE_MQH__

class TrendEngine {
   PivotEngine *pe; MFVConfig *cfg;
   TFTrend h1, m15, m5;
 private:
   int Sign(TrendDir d){ return d==TD_Up ? +1 : (d==TD_Down ? -1 : 0); }
   
   // Fallback-направление, когда lastSwing неизвестен (например, FastPivot).
   // Если Close находится выше середины между H и L — Up, ниже — Down, иначе Flat.
   TrendDir DirByMid(ENUM_TIMEFRAMES tf, const DualPivot &dp)
     {
      if(dp.High<=0.0 || dp.Low<=0.0) return TD_Flat;
      const double mid = 0.5*(dp.High + dp.Low);
      const double px  = iClose(_Symbol, tf, 1);
      const double tol = 2*_Point;
      if(px > mid + tol) return TD_Up;
      if(px < mid - tol) return TD_Down;
      return TD_Flat;
     }
   TrendDir DirByPivot(ENUM_TIMEFRAMES tf, const DualPivot &dp)
     {
      // Если lastSwing неизвестен — используем fallback по середине диапазона.
      if(dp.lastSwing == 0)
         return DirByMid(tf, dp);
      // используем закрытый бар
      double close = iClose(_Symbol, tf, 1);
      double eps = _Point * 2.0; // небольшой допуск
      if(close > dp.High + eps) return TD_Up;
      if(close < dp.Low  - eps) return TD_Down;
      return TD_Flat;
     }
 public:
   void Init(PivotEngine &p, MFVConfig &c){ pe=&p; cfg=&c; }
   void UpdateAllTF(const PivotEngine &pivot)
     {
      DualPivot dH1(pivot.Get(PERIOD_H1));
      DualPivot dM15(pivot.Get(PERIOD_M15));
      DualPivot dM5(pivot.Get(PERIOD_M5));

      TrendDir dirH1 = DirByPivot(PERIOD_H1, dH1);
      TrendDir dirM15= DirByPivot(PERIOD_M15, dM15);
      TrendDir dirM5 = DirByPivot(PERIOD_M5, dM5);

      // Перс-ТП сила: сколько ТФ согласны с направлением данного ТФ (не считаем FLAT)
      TFTrend th1; th1.dir = dirH1;
      TFTrend tm15; tm15.dir = dirM15;
      TFTrend tm5; tm5.dir = dirM5;
      TrendDir dirs[3]; dirs[0]=th1.dir; dirs[1]=tm15.dir; dirs[2]=tm5.dir;
      int sH1=0, sM15=0, sM5=0;
      for(int i=0;i<3;++i) if(dirs[i]==th1.dir && th1.dir!=TD_Flat) ++sH1;
      for(int i=0;i<3;++i) if(dirs[i]==tm15.dir && tm15.dir!=TD_Flat) ++sM15;
      for(int i=0;i<3;++i) if(dirs[i]==tm5.dir && tm5.dir!=TD_Flat) ++sM5;

      th1.strength  = sH1; th1.ts  = TimeCurrent();
      tm15.strength = sM15; tm15.ts = TimeCurrent();
      tm5.strength  = sM5; tm5.ts  = TimeCurrent();

      h1 = th1; m15 = tm15; m5 = tm5;
     }
   TFTrend Get(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1) return h1;
      if(tf==PERIOD_M5) return m5;
      return m15;
     }
   int TrendStrength() const { return 0; }
};

#endif // __MFV_TRENDENGINE_MQH__
