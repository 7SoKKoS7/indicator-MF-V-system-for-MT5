#pragma once
enum TrendDir { TD_Flat=0, TD_Up=1, TD_Down=2 };

struct TFTrend { TrendDir dir; int strength; datetime ts;
   TFTrend():dir(TD_Flat),strength(0),ts(0){} };

enum SigClass { Sig_None=0, Sig_EarlyBuy, Sig_EarlySell, Sig_NormalBuy, Sig_NormalSell,
                Sig_StrongBuy, Sig_StrongSell, Sig_EarlyExit, Sig_HardExit, Sig_Reversal };

struct SignalDecision { SigClass klass; datetime t; double price; string note;
   SignalDecision():klass(Sig_None),t(0),price(0),note(""){} };

struct FilterVerdict { int downgrade; bool block; string reasons;
   FilterVerdict():downgrade(0),block(false),reasons(""){} };

struct MFVState {
   datetime lastArrowTime;
   datetime lastReverseTime;
   TFTrend H1; TFTrend M15; TFTrend M5;
   string lastStatus;
   MFVState():lastArrowTime(0),lastReverseTime(0),lastStatus(""){}
};


