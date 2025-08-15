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

int OnInit()
{
   gCfg.LoadInputs();
   gMD.Init(_Symbol, PERIOD_CURRENT);
   gPE.Init(&gMD, &gCfg);
   gTE.Init(&gPE, &gCfg);
   gBR.Init(&gPE, &gMD, &gCfg);
   gFL.Init(&gMD, &gCfg);
   gSG.Init(&gTE, &gBR, &gFL, &gCfg, &gSt);
   gDR.Init(&gCfg);
   gPV.Init(&gCfg);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   gDR.Cleanup();
   gPV.Cleanup();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if(rates_total<=1) return(0);
   gMD.Refresh();
   gPE.UpdateAllTF();
   gTE.UpdateAllTF();
   gBR.Update();
   gFL.Update();
   SignalDecision sd = gSG.DecideAndUpdate();
   gDR.SyncPivots(gPE);
   gDR.DrawSignal(sd);
   return(rates_total);
}

void OnTimer()
{
   gPV.Render(gTE, gPE, gFL, gBR, gSG, gMD, gCfg, gSt);
}


