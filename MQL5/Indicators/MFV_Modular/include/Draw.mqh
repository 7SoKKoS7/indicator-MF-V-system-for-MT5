#ifndef __MFV_DRAW_MQH__
#define __MFV_DRAW_MQH__

#include "PivotEngine.mqh"

class MFVConfig;       // fwd
struct SignalDecision; // fwd

class DrawLayer {
   MFVConfig *cfg;
private:
   string NamePivot(ENUM_TIMEFRAMES tf, bool isHigh)
   {
      string t = (tf==PERIOD_H1 ? "H1" : (tf==PERIOD_M5 ? "M5" : "M15"));
      return StringFormat("MFV_Pivot_%s_%s", t, (isHigh?"H":"L"));
   }

   bool EnsureHLine(const string name, const double price)
   {
      if(price <= 0.0)
         return false;
      if(ObjectFind(0, name) >= 0)
         return true;
      bool ok = ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      if(!ok) return false;
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrSilver);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK,  true);
      return true;
   }

   void UpdateHLine(const string name, const double price)
   {
      if(ObjectFind(0, name) < 0) return;
      double cur = ObjectGetDouble(0, name, OBJPROP_PRICE);
      const double tol = _Point * 0.1;
      if(MathAbs(cur - price) > tol)
         ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }
public:
   void Init(MFVConfig &c){ cfg=&c; }
   void SyncPivots(const PivotEngine &pe)
   {
      // H1
      DualPivot d = pe.Get(PERIOD_H1);
      string nH = NamePivot(PERIOD_H1, true);
      string nL = NamePivot(PERIOD_H1, false);
      if(d.High>0.0) EnsureHLine(nH, d.High);
      if(d.Low >0.0) EnsureHLine(nL, d.Low);
      UpdateHLine(nH, d.High);
      UpdateHLine(nL, d.Low);

      // M15
      d = pe.Get(PERIOD_M15);
      nH = NamePivot(PERIOD_M15, true);
      nL = NamePivot(PERIOD_M15, false);
      if(d.High>0.0) EnsureHLine(nH, d.High);
      if(d.Low >0.0) EnsureHLine(nL, d.Low);
      UpdateHLine(nH, d.High);
      UpdateHLine(nL, d.Low);

      // M5
      d = pe.Get(PERIOD_M5);
      nH = NamePivot(PERIOD_M5, true);
      nL = NamePivot(PERIOD_M5, false);
      if(d.High>0.0) EnsureHLine(nH, d.High);
      if(d.Low >0.0) EnsureHLine(nL, d.Low);
      UpdateHLine(nH, d.High);
      UpdateHLine(nL, d.Low);
   }
   void DrawSignal(const SignalDecision &sd){ /* позже: стрелки и т.п. */ }
   void Cleanup()
   {
      const string prefix = "MFV_Pivot_";
      int total = (int)ObjectTotal(0);
      for(int i=total-1; i>=0; --i)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, prefix) == 0)
            ObjectDelete(0, name);
      }
   }
};

#endif // __MFV_DRAW_MQH__
