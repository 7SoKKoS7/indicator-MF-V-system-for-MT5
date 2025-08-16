#ifndef __MFV_PANEL_MQH__
#define __MFV_PANEL_MQH__

class PanelView {
   MFVConfig *cfg;
public:
   void Init(MFVConfig &c){ cfg=&c; }
   void Render(const TrendEngine& te, const PivotEngine&, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&)
   {
      TFTrend th1(te.Get(PERIOD_H1));
      TFTrend tm15(te.Get(PERIOD_M15));
      TFTrend tm5(te.Get(PERIOD_M5));
      string sH1 = (th1.dir==TD_Up?"Up":(th1.dir==TD_Down?"Down":"Flat"));
      string sM15= (tm15.dir==TD_Up?"Up":(tm15.dir==TD_Down?"Down":"Flat"));
      string sM5 = (tm5.dir==TD_Up?"Up":(tm5.dir==TD_Down?"Down":"Flat"));
      string line = StringFormat("H1:%s(%d)  M15:%s(%d)  M5:%s(%d)", sH1, th1.strength, sM15, tm15.strength, sM5, tm5.strength);
      Comment(line);
   }
   void Cleanup(){ }
};

#endif // __MFV_PANEL_MQH__
