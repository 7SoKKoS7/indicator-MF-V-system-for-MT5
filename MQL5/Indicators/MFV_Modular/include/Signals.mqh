#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

class Signals {
   TrendEngine *te; Breakout *br; Filters *fl; MFVConfig *cfg; MFVState *st;
public:
   void Init(TrendEngine &t, Breakout &b, Filters &f, MFVConfig &c, MFVState &s)
   { te=GetPointer(t); br=GetPointer(b); fl=GetPointer(f); cfg=GetPointer(c); st=GetPointer(s); }
   SignalDecision DecideAndUpdate(){
      SignalDecision sd; st->lastStatus="stub"; return sd;
   }
};

#endif // __MFV_SIGNALS_MQH__
