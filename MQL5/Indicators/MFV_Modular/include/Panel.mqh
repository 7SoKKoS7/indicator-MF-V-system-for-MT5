#ifndef __MFV_PANEL_MQH__
#define __MFV_PANEL_MQH__

class PanelView {
   MFVConfig *cfg;
   const string kPanelLabel = "MFV_Panel_Status";
private:
   bool EnsureLabel()
   {
      if(ObjectFind(0, kPanelLabel) < 0)
      {
         if(!ObjectCreate(0, kPanelLabel, OBJ_LABEL, 0, 0, 0)) return false;
         ObjectSetInteger(0, kPanelLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, kPanelLabel, OBJPROP_XDISTANCE, 8);
         ObjectSetInteger(0, kPanelLabel, OBJPROP_YDISTANCE, 8);
         ObjectSetString (0, kPanelLabel, OBJPROP_FONT, "Tahoma");
         ObjectSetInteger(0, kPanelLabel, OBJPROP_FONTSIZE, (cfg?cfg.PanelFontSize:11));
         ObjectSetInteger(0, kPanelLabel, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, kPanelLabel, OBJPROP_BACK,  false);
      }
      else
      {
         // обновляем размер на лету, если пользователь поменял инпут
         ObjectSetInteger(0, kPanelLabel, OBJPROP_FONTSIZE, (cfg?cfg.PanelFontSize:11));
      }
      return true;
   }

   void UpdateLabelText(const string text)
   {
      string cur = ObjectGetString(0, kPanelLabel, OBJPROP_TEXT);
      if(cur != text)
         ObjectSetString(0, kPanelLabel, OBJPROP_TEXT, text);
   }

   string DirText(TrendDir d){ return (d==TD_Up?"UP":(d==TD_Down?"DOWN":"FLAT")); }
   string FormatTf(const TFTrend &t, const string name)
   {
      string d = DirText(t.dir);
      if(t.dir==TD_Flat) return name+":"+d; // без (0)
      return name+":"+d+"("+IntegerToString(t.strength)+")";
   }
public:
   void Init(MFVConfig &c){ cfg=&c; }
   void Render(const TrendEngine& te, const PivotEngine&, const Filters&,
               const Breakout&, const Signals&, const MarketData&,
               const MFVConfig&, const MFVState&)
   {
      TFTrend th1(te.Get(PERIOD_H1));
      TFTrend tm15(te.Get(PERIOD_M15));
      TFTrend tm5(te.Get(PERIOD_M5));
      string line = FormatTf(th1, "H1") + "  " + FormatTf(tm15, "M15") + "  " + FormatTf(tm5, "M5");
      if(EnsureLabel()) UpdateLabelText(line);
   }
   void Cleanup(){ if(ObjectFind(0, kPanelLabel) >= 0) ObjectDelete(0, kPanelLabel); }
};

#endif // __MFV_PANEL_MQH__
