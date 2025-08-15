#ifndef __MFV_DRAW_MQH__
#define __MFV_DRAW_MQH__

class DrawLayer {
   MFVConfig *cfg;
public:
   void Init(MFVConfig* c){ cfg=c; }
   void SyncPivots(const PivotEngine &pe){ /* позже: HLINE по TF */ }
   void DrawSignal(const SignalDecision &sd){ /* позже: стрелки и т.п. */ }
   void Cleanup(){ }
};

#endif // __MFV_DRAW_MQH__
