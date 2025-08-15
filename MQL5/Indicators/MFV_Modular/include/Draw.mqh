#pragma once
class DrawLayer {
   MFVConfig *cfg;
public:
   void Init(MFVConfig* c){ cfg=c; }
   void SyncPivots(const PivotEngine &pe){ /* позже: HLINE по TF */ }
   void DrawSignal(const SignalDecision &sd){ /* позже: стрелки и т.п. */ }
   void Cleanup(){ }
};


