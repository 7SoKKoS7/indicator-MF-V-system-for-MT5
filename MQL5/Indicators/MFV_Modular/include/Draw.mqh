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
      bool isHigh = (StringFind(name, "_H", StringLen(name)-2) == StringLen(name)-2);
      ObjectSetInteger(0, name, OBJPROP_COLOR, isHigh ? (cfg?cfg.PivotColorH:clrLime) : (cfg?cfg.PivotColorL:clrYellow));
      ObjectSetInteger(0, name, OBJPROP_STYLE, (cfg?cfg.PivotLineStyle:STYLE_DOT));
      ObjectSetInteger(0, name, OBJPROP_WIDTH, (cfg?cfg.PivotLineWidth:1));
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
      // обновляем стиль/ширину/цвет на лету согласно cfg
      ObjectSetInteger(0, name, OBJPROP_STYLE, (cfg?cfg.PivotLineStyle:STYLE_DOT));
      ObjectSetInteger(0, name, OBJPROP_WIDTH, (cfg?cfg.PivotLineWidth:1));
      bool isHigh = (StringFind(name, "_H", StringLen(name)-2) == StringLen(name)-2);
      color desired = isHigh ? (cfg?cfg.PivotColorH:clrLime) : (cfg?cfg.PivotColorL:clrYellow);
      color curCol = (color)ObjectGetInteger(0, name, OBJPROP_COLOR);
      if(curCol != desired)
         ObjectSetInteger(0, name, OBJPROP_COLOR, desired);
   }
public:
   void Init(MFVConfig &c){ cfg=&c; }
   void SyncPivots(const PivotEngine &pe)
   {
      // H1
      DualPivot d(pe.Get(PERIOD_H1));
      string nH = NamePivot(PERIOD_H1, true);
      string nL = NamePivot(PERIOD_H1, false);
      if(d.High>0.0) EnsureHLine(nH, d.High);
      if(d.Low >0.0) EnsureHLine(nL, d.Low);
      UpdateHLine(nH, d.High);
      UpdateHLine(nL, d.Low);

      // M15
      d = DualPivot(pe.Get(PERIOD_M15));
      nH = NamePivot(PERIOD_M15, true);
      nL = NamePivot(PERIOD_M15, false);
      if(d.High>0.0) EnsureHLine(nH, d.High);
      if(d.Low >0.0) EnsureHLine(nL, d.Low);
      UpdateHLine(nH, d.High);
      UpdateHLine(nL, d.Low);

      // M5
      d = DualPivot(pe.Get(PERIOD_M5));
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
      // ObjectsDeleteAll в MQL5 не принимает префикс, поэтому удаляем вручную
      int total = ObjectsTotal(0, 0, -1);
      for(int i = total - 1; i >= 0; --i)
      {
         string nm = ObjectName(0, i, 0);
         if(StringFind(nm, "MFV_Pivot_", 0) == 0)
            ObjectDelete(0, nm);
      }
   }
};

#endif // __MFV_DRAW_MQH__
