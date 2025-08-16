#ifndef __MFV_STATE_MQH__
#define __MFV_STATE_MQH__

enum TrendDir { TD_Flat=0, TD_Up=1, TD_Down=2 };

struct TFTrend { TrendDir dir; int strength; datetime ts;
   TFTrend():dir(TD_Flat),strength(0),ts(0){}
   TFTrend(const TFTrend &o){ dir=o.dir; strength=o.strength; ts=o.ts; } };

enum SigClass { Sig_None=0, Sig_EarlyBuy, Sig_EarlySell, Sig_NormalBuy, Sig_NormalSell,
                Sig_StrongBuy, Sig_StrongSell, Sig_EarlyExit, Sig_HardExit, Sig_Reversal };

struct SignalDecision {
   SigClass klass; datetime t; double price; string note;

   // Явный конструктор по умолчанию
   SignalDecision()
   {
      klass = Sig_None;
      t     = 0;
      price = 0.0;
      note  = "";
   }

   // Копирующий конструктор
   SignalDecision(const SignalDecision &other)
   {
      klass = other.klass;
      t     = other.t;
      price = other.price;
      note  = other.note;
   }
};

struct FilterVerdict { int downgrade; bool block; string reasons;
   FilterVerdict():downgrade(0),block(false),reasons(""){} };

class MFVState {
public:
   datetime lastArrowTime;
   datetime lastReverseTime;
   TFTrend H1; TFTrend M15; TFTrend M5;
   string lastStatus;
   MFVState():lastArrowTime(0),lastReverseTime(0),lastStatus(""){}
};

#endif // __MFV_STATE_MQH__
