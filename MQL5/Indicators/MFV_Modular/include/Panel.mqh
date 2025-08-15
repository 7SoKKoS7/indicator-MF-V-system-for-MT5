#pragma once
class PanelView {
   MFVConfig *cfg;
public:
   void Init(MFVConfig* c){ cfg=c; }
   void Render(const TrendEngine&, const PivotEngine&, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&){ /* позже: инфо-панель */ }
   void Cleanup(){ }
};


