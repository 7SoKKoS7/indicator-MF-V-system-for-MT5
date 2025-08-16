#property indicator_chart_window
#property indicator_plots 0

input group "=== Основные ==="
input bool   UseRussian           = false;
input bool   EnableVolumeFilter   = true;
input bool   EnableSessionFilter  = true;
input bool   UseClinchFilter      = true;
input bool   UseImpulseFilter     = true;
input int    H1ClosesNeeded       = 2;
input int    RetestWindowM15      = 12;
input int    RetestWindowM5       = 24;
input double RetestTolATR_M15     = 0.30;
input double RetestTolATR_M5      = 0.50;
input int    PanelFontSize        = 11;   // размер шрифта панели

#include "include/Config.mqh"
#include "include/State.mqh"
#include "include/MarketData.mqh"
#include "include/PivotEngine.mqh"
#include "include/TrendEngine.mqh"
#include "include/Breakout.mqh"
#include "include/Filters.mqh"
#include "include/Signals.mqh"
#include "include/Draw.mqh"
#include "include/Panel.mqh"

// GMLogger for Golden Master CSV
#include "include/GMLogger.mqh"
MFVConfig   gCfg;
MFVState    gSt;
MarketData  gMD;
PivotEngine gPE;
TrendEngine gTE;
Breakout    gBR;
Filters     gFL;
Signals     gSG;
DrawLayer   gDR;
PanelView   gPV;

GMLogger GM;

int OnInit()
{
   gCfg.LoadInputs();
   gMD.Init(_Symbol, PERIOD_CURRENT);
   gPE.Init(gMD, gCfg);
   gTE.Init(gPE, gCfg);
   gBR.Init(gPE, gMD, gCfg);
   gFL.Init(gMD, gCfg);
   gSG.Init(gTE, gBR, gFL, gCfg, gSt);
   gDR.Init(gCfg);
   gPV.Init(gCfg);
   EventSetTimer(1);
   GM.Init("modular");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   gDR.Cleanup();
   gPV.Cleanup();
   GM.Close();
}

// helper для строкового представления тренда
string MFV_TrendStr(TrendDir d)
{
   if(d==TD_Up)   return "Up";
   if(d==TD_Down) return "Down";
   return "Flat";
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if(rates_total<=1) return(0);
   gMD.Refresh();
   gPE.UpdateAllTF();
   gTE.UpdateAllTF(gPE);
   gBR.Update();
   gFL.Update();
   SignalDecision sd(gSG.DecideAndUpdate());
   GM.LogRaw(
      PERIOD_M15,
      iTime(_Symbol, PERIOD_M15, 1),
      SymbolInfoDouble(_Symbol, SYMBOL_BID),
      gPE.Get(PERIOD_M15).High,
      gPE.Get(PERIOD_M15).Low,
      MFV_TrendStr(gTE.Get(PERIOD_M15).dir),
      EnumToString(sd.klass),
      sd.note
   );
   gDR.SyncPivots(gPE);
   gDR.DrawSignal(sd);
   return(rates_total);
}

void OnTimer()
{
   gPV.Render(gTE, gPE, gFL, gBR, gSG, gMD, gCfg, gSt);
}


