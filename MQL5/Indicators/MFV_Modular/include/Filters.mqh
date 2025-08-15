#pragma once
class Filters {
   MarketData *md; MFVConfig *cfg; FilterVerdict verdict;
public:
   void Init(MarketData* m, MFVConfig* c){ md=m; cfg=c; verdict=FilterVerdict(); }
   void Update(){ verdict.downgrade=0; verdict.block=false; verdict.reasons=""; }
   FilterVerdict Get() const { return verdict; }
};


