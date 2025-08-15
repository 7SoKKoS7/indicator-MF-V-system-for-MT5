#ifndef __MFV_FILTERS_MQH__
#define __MFV_FILTERS_MQH__

class Filters {
   MarketData *md; MFVConfig *cfg; FilterVerdict verdict;
public:
   void Init(MarketData &m, MFVConfig &c){ md=GetPointer(m); cfg=GetPointer(c); verdict=FilterVerdict(); }
   void Update(){ verdict.downgrade=0; verdict.block=false; verdict.reasons=""; }
   FilterVerdict Get() const { return verdict; }
};

#endif // __MFV_FILTERS_MQH__
