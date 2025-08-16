#ifndef __MFV_PANEL_MQH__
#define __MFV_PANEL_MQH__

class PanelView {
   MFVConfig *cfg;
   string kPanelLabel;
 private:
   int LineHeight() const { return ((cfg && cfg.PanelFontSize>0)?cfg.PanelFontSize:11) + 4; }

   bool EnsureLabelAt(const int idx)
   {
      string name = StringFormat("MFV_Panel_Status_%d", idx);
      if(ObjectFind(0, name) < 0)
      {
         if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) return false;
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 8);
      }
      // обновляем шрифт/позицию на лету
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, (cfg?cfg.PanelFontSize:11));
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, (cfg?cfg.PanelYOffset:24) + idx * LineHeight());
      ObjectSetString (0, name, OBJPROP_FONT, "Tahoma");
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BACK,  false);
      return true;
   }

   void UpdateLabelTextAt(const int idx, const string text)
   {
      string name = StringFormat("MFV_Panel_Status_%d", idx);
      string cur = ObjectGetString(0, name, OBJPROP_TEXT);
      if(cur != text)
         ObjectSetString(0, name, OBJPROP_TEXT, text);
   }

   string Arrow(TrendDir d)
   {
      if(d==TD_Up)   return "\xE2\x86\x91"; // Unicode up arrow
      if(d==TD_Down) return "\xE2\x86\x93"; // Unicode down arrow
      return "-";
   }
   string DirText(TrendDir d){ return (d==TD_Up?"UP":(d==TD_Down?"DOWN":"FLAT")); }
   string FormatTrendSeg(const string name, const TFTrend &t)
   {
      string base = (cfg && cfg.PanelUseArrows ? Arrow(t.dir) : DirText(t.dir));
      if(cfg && cfg.PanelShowStrength && t.dir!=TD_Flat)
         base = base + "(" + IntegerToString(t.strength) + ")";
      return name + ":" + base;
   }
   string Px(double v)
   {
      if(v<=0.0) return "—";
      return DoubleToString(v, _Digits);
   }
   string FormatPivotLine(const string label, const DualPivot &dp)
   {
      return StringFormat("%s: H=%s | L=%s", label, Px(dp.High), Px(dp.Low));
   }
 public:
   void Init(MFVConfig &c){ cfg=&c; kPanelLabel = "MFV_Panel_Status"; }
   void Render(const TrendEngine& te, PivotEngine& pe, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&)
   {
      // Строка трендов
      TFTrend th1(te.Get(PERIOD_H1));
      TFTrend tm15(te.Get(PERIOD_M15));
      TFTrend tm5(te.Get(PERIOD_M5));
      string line0 = FormatTrendSeg("H1", th1) + "  " + FormatTrendSeg("M15", tm15) + "  " + FormatTrendSeg("M5", tm5);
      if(EnsureLabelAt(0)) UpdateLabelTextAt(0, line0);

      // Pivot-строки
      int idx = 1;
      DualPivot d5(pe.ComputeNow(PERIOD_M5));
      if(EnsureLabelAt(idx)) UpdateLabelTextAt(idx++, FormatPivotLine("Pivot M5", d5));

      DualPivot d15(pe.ComputeNow(PERIOD_M15));
      if(EnsureLabelAt(idx)) UpdateLabelTextAt(idx++, FormatPivotLine("Pivot M15", d15));

      DualPivot d1h(pe.ComputeNow(PERIOD_H1));
      if(EnsureLabelAt(idx)) UpdateLabelTextAt(idx++, FormatPivotLine("Pivot H1", d1h));

      if(cfg && cfg.ShowPivotH4)
        {
         DualPivot d4(pe.ComputeNow(PERIOD_H4));
         if(EnsureLabelAt(idx)) UpdateLabelTextAt(idx++, FormatPivotLine("Pivot H4", d4));
        }
      if(cfg && cfg.ShowPivotD1)
        {
         DualPivot dD(pe.ComputeNow(PERIOD_D1));
         if(EnsureLabelAt(idx)) UpdateLabelTextAt(idx++, FormatPivotLine("Pivot D1", dD));
        }
   }
   void Cleanup()
   {
      // удалить все лейблы панели
      int total = ObjectsTotal(0, 0, -1);
      for(int i=total-1;i>=0;--i)
      {
         string nm = ObjectName(0, i, 0);
         if(StringFind(nm, "MFV_Panel_Status_", 0) == 0)
            ObjectDelete(0, nm);
      }
   }
};

#endif // __MFV_PANEL_MQH__
