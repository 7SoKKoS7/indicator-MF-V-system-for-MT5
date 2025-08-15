#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

struct DualPivot { double High; double Low; int lastSwing; datetime ts;
   DualPivot():High(0),Low(0),lastSwing(0),ts(0){} };

class PivotEngine {
   MarketData *md; MFVConfig *cfg;
   DualPivot m_h1, m_m15, m_m5;
public:
   void Init(MarketData* m, MFVConfig* c){ md=m; cfg=c; }
   void UpdateAllTF(){ m_h1=computeForTf(PERIOD_H1); m_m15=computeForTf(PERIOD_M15); m_m5=computeForTf(PERIOD_M5); }
   DualPivot Get(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1) return m_h1;
      if(tf==PERIOD_M5) return m_m5;
      return m_m15;
   }
private:
   DualPivot computeForTf(ENUM_TIMEFRAMES tf){ DualPivot d; return d; }
};

#endif // __MFV_PIVOTENGINE_MQH__
