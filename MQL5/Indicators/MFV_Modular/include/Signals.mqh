#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

class Signals {
   TrendEngine *te; Breakout *br; Filters *fl; MFVConfig *cfg; MFVState *st;
public:
   void Init(TrendEngine* t, Breakout* b, Filters* f, MFVConfig* c, MFVState* s)
   { te=t; br=b; fl=f; cfg=c; st=s; }
   SignalDecision DecideAndUpdate(){
      SignalDecision sd; st->lastStatus="stub"; return sd;
   }
};

#endif // __MFV_SIGNALS_MQH__
