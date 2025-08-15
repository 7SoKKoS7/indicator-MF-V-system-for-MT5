#pragma once
class Breakout {
   PivotEngine *pe; MarketData *md; MFVConfig *cfg;
   bool h1Confirmed, retestOk;
public:
   Breakout():pe(NULL),md(NULL),cfg(NULL),h1Confirmed(false),retestOk(false){}
   void Init(PivotEngine* p, MarketData* m, MFVConfig* c){ pe=p; md=m; cfg=c; }
   void Update(){ h1Confirmed=false; retestOk=false; }
   bool H1Confirmed() const { return h1Confirmed; }
   bool RetestOK()   const { return retestOk; }
};


