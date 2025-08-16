#ifndef __MFV_TRENDENGINE_MQH__
#define __MFV_TRENDENGINE_MQH__

class TrendEngine {
   PivotEngine *pe; MFVConfig *cfg;
   TFTrend h1, m15, m5;
public:
   void Init(PivotEngine &p, MFVConfig &c){ pe=&p; cfg=&c; }
   void UpdateAllTF(){ h1.dir=TD_Flat; m15.dir=TD_Flat; m5.dir=TD_Flat; }
   TFTrend Get(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1) return h1;
      if(tf==PERIOD_M5) return m5;
      return m15;
   }
   int TrendStrength() const { return 0; }
};

#endif // __MFV_TRENDENGINE_MQH__
