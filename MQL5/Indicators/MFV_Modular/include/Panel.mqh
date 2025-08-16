#ifndef __MFV_PANEL_MQH__
#define __MFV_PANEL_MQH__

class PanelView {
   MFVConfig *cfg;
public:
   void Init(MFVConfig &c){ cfg=&c; }
   void Render(const TrendEngine&, const PivotEngine&, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&){ /* позже: инфо-панель */ }
   void Cleanup(){ }
};

#endif // __MFV_PANEL_MQH__
