#ifndef __MFV_BREAKOUT_MQH__
#define __MFV_BREAKOUT_MQH__

class Breakout {
   PivotEngine *pe; MarketData *md; MFVConfig *cfg;
   bool h1Confirmed, retestOk;
public:
   Breakout():pe(NULL),md(NULL),cfg(NULL),h1Confirmed(false),retestOk(false){}
   void Init(PivotEngine &p, MarketData &m, MFVConfig &c){ pe=GetPointer(p); md=GetPointer(m); cfg=GetPointer(c); }
   void Update(){ h1Confirmed=false; retestOk=false; }
   bool H1Confirmed() const { return h1Confirmed; }
   bool RetestOK()   const { return retestOk; }
};

#endif // __MFV_BREAKOUT_MQH__
