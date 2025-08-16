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
   string FormatTf(const TFTrend &t, const string name)
   {
      string d = DirText(t.dir);
      if(t.dir==TD_Flat) return name+":"+d; // без (0)
      return name+":"+d+"("+IntegerToString(t.strength)+")";
   }
public:
   void Init(MFVConfig &c){ cfg=&c; kPanelLabel = "MFV_Panel_Status"; }
   void Render(const TrendEngine& te, const PivotEngine&, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&)
   {
      TFTrend th1(te.Get(PERIOD_H1));
      TFTrend tm15(te.Get(PERIOD_M15));
      TFTrend tm5(te.Get(PERIOD_M5));
      auto fmt = [&](const char* name, const TFTrend& t)->string
      {
         string base = (cfg && cfg.PanelUseArrows ? Arrow(t.dir) : DirText(t.dir));
         if(cfg && cfg.PanelShowStrength && t.dir!=TD_Flat)
            base = base + "(" + IntegerToString(t.strength) + ")";
         return StringFormat("%s:%s", name, base);
      };
      string line = fmt("H1", th1) + "  " + fmt("M15", tm15) + "  " + fmt("M5", tm5);
      if(EnsureLabelAt(0)) UpdateLabelTextAt(0, line);
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
