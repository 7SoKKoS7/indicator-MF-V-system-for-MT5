//+------------------------------------------------------------------+
//|                                                    MF-V EA v8.2308|
//| Expert Advisor, based on MasterForex-V MultiTF indicator signals  |
//| Uses indicator arrows (Early/Normal/Strong, Exit) to trade       |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

// Inputs
input double   BaseLots           = 0.10;   // Базовый размер лота
input double   EarlyLotMultiplier = 0.50;   // Множитель для ранних (Early) сигналов
input double   NormalLotMultiplier= 0.75;   // Множитель для обычных (Normal) сигналов
input double   StrongLotMultiplier= 1.00;   // Множитель для сильных (Strong) сигналов
input ulong    Magic              = 82308;  // Магик
input int      Slippage           = 10;     // Проскальзывание (пунктов)
input bool     AllowNewPositions  = true;   // Разрешать новые входы
input bool     CloseOnExitSignal  = true;   // Закрывать по сигналу выхода (крестик)

// --- Фиксированные SL/TP (в пунктах 4-знака; для 5 знаков 1 пункт = 10 поинтов)
input bool     UseFixedSLTP       = false;  // Использовать фиксированные SL/TP
input int      FixedSL_Pips       = 200;    // Стоп-лосс в пунктах (0 = не ставить SL)
input int      FixedTP_Pips       = 400;    // Тейк-профит в пунктах (0 = не ставить TP)

// --- Параметры авто SL/TP по MF‑V
input bool     UseAutoSLTP        = true;   // Включить авто‑SL/TP по методике MF‑V
input bool     UseM15PivotForEarly= false;  // Для ранних входов SL по pivot M15 (иначе H1)
input double   SL_AtrK_H1         = 0.10;   // Добавка к SL: k * ATR(H1)
input int      SL_ExtraPoints     = 3;      // Запас к SL в пунктах (4-знак)

enum TPMode { TP_None, TP_RiskReward, TP_PivotHigher };
input TPMode   TakeProfitMode     = TP_RiskReward; // Режим расчёта TP
input double   TP_RR              = 2.0;    // Если TP_RiskReward: отношение риск/прибыль
input bool     TrailByM15Pivot    = true;   // Сопровождение: подтягивать SL к pivot M15
input int      ForceSetStopsAttempts = 40;  // Сколько раз пытаться проставить SL/TP после открытия
input int      ForceSetStopsDelayMs = 500;  // Пауза между попытками (мс)

// Минимальная дистанция (в пипсах 4‑знака) если брокер сообщает StopsLevel=0
input int      FallbackMinPips    = 50;     // Дистанция безопасности, 50 пипсов = 0.0050 для EURUSD

// --- Параметры расчёта MF‑pivot (должны соответствовать индикатору)
input int      InpDepthEA         = 12;     // Глубина ZigZag для пивота
input double   InpDeviationEA     = 5.0;    // Отклонение в пунктах
input double   AtrDeviationK_EA   = 0.0;    // Адаптация порога по ATR(tf)

// Indicator buffers indexing (must match indicator buffers order)
enum BufferIndex {
   BUF_BUY=0,         // BuyArrowBuffer (Normal)
   BUF_SELL=1,        // SellArrowBuffer (Normal)
   BUF_EARLY_BUY=2,   // EarlyBuyBuffer
   BUF_EARLY_SELL=3,  // EarlySellBuffer
   BUF_EXIT=4,        // ExitBuffer (Hard)
   BUF_REVERSE=5,     // ReverseBuffer
   BUF_STRONG_BUY=6,  // StrongBuyBuffer
   BUF_STRONG_SELL=7, // StrongSellBuffer
   BUF_EARLY_EXIT=8   // EarlyExitBuffer (Soft)
};

// State
CTrade      trade;
int         indHandle = INVALID_HANDLE;
datetime    lastBarProcessed = 0;

// Пробуем догружать SL/TP после исполнения сделки, если сервер не принял сразу
bool ApplyStopsIfMissing(const int dir, const double plannedSL, const double plannedTP)
{
   if(!PositionSelect(_Symbol)) return false;
   if((ulong)PositionGetInteger(POSITION_MAGIC) != Magic) return false;
   double curSL = PositionGetDouble(POSITION_SL);
   double curTP = PositionGetDouble(POSITION_TP);
   double entry = PositionGetDouble(POSITION_PRICE_OPEN);

   double sl = plannedSL;
   double tp = plannedTP;
   // Если плановые нули — ничего не делаем
   if(sl<=0.0 && tp<=0.0) return true;

   // Учитываем минимальную дистанцию брокера
   EnsureStopsMinDistance(dir, entry, sl, tp);
   EnsureStopsMinDistanceMarket(dir, sl, tp);
   sl = (sl>0.0 ? NormalizeDouble(sl, _Digits) : 0.0);
   tp = (tp>0.0 ? NormalizeDouble(tp, _Digits) : 0.0);

   bool needMod = false;
   if(sl>0.0 && (curSL<=0.0 || MathAbs(curSL-sl) > _Point)) needMod = true;
   if(TakeProfitMode!=TP_None && tp>0.0 && (curTP<=0.0 || MathAbs(curTP-tp) > _Point)) needMod = true;
   if(!needMod) return true;

   bool ok = trade.PositionModify(_Symbol, (sl>0.0?sl:curSL), (TakeProfitMode!=TP_None && tp>0.0?tp:curTP));
   if(!ok) Print("[MFV EA] PositionModify to set SL/TP failed: ", _LastError);
   return ok;
}

//+------------------------------------------------------------------+
//| Pivot calculation (confirmed only, closed bars)                   |
//+------------------------------------------------------------------+
double CalcConfirmedPivot(const ENUM_TIMEFRAMES tf)
{
   int bars = iBars(_Symbol, tf);
   if(bars < InpDepthEA + 2) return 0.0;
   int count = MathMin(bars, 300);
   double close[]; ArraySetAsSeries(close, true);
   if(CopyClose(_Symbol, tf, 1, count, close) <= 0) return 0.0; // исключаем текущий бар

   double deviation = InpDeviationEA * _Point;
   if(AtrDeviationK_EA > 0.0)
   {
      int atrH = iATR(_Symbol, tf, 14);
      double aBuf[]; ArraySetAsSeries(aBuf, true);
      if(atrH != INVALID_HANDLE && CopyBuffer(atrH, 0, 1, 1, aBuf) == 1)
      {
         double atrDev = AtrDeviationK_EA * aBuf[0];
         if(atrDev > deviation) deviation = atrDev;
      }
   }

   double last_p = close[count-1];
   int    last_i = count-1;
   int    dir    = 0; // 1 — максимум, -1 — минимум
   const int minDist = MathMax(1, InpDepthEA);
   double confirmed = 0.0;
   for(int i=count-2; i>=1; --i)
   {
      double px = close[i];
      if(dir == 0)
      {
         if(MathAbs(px - last_p) > deviation)
         { dir = (px > last_p ? 1 : -1); last_p = px; last_i = i; }
      }
      else if(dir == 1)
      {
         if(px > last_p){ last_p = px; last_i = i; }
         else if((last_p - px) > deviation && (last_i - i) >= minDist){ confirmed = last_p; break; }
      }
      else
      {
         if(px < last_p){ last_p = px; last_i = i; }
         else if((px - last_p) > deviation && (last_i - i) >= minDist){ confirmed = last_p; break; }
      }
   }
   return confirmed;
}

double GetATR(const ENUM_TIMEFRAMES tf)
{
   int h = iATR(_Symbol, tf, 14); if(h==INVALID_HANDLE) return 0.0;
   double a[]; ArraySetAsSeries(a,true);
   if(CopyBuffer(h,0,1,1,a)==1) return a[0];
   return 0.0;
}

double GetMinStopDistance()
{
   long stops = 0;
   SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL, stops);
   double dist = (double)stops * _Point;
   if(dist<=0.0)
   {
      // если брокер не даёт StopsLevel, используем настраиваемый минимум в пипсах
      double pip = ((_Digits==5 || _Digits==3) ? 10.0*_Point : _Point);
      dist = MathMax(5*_Point, (double)FallbackMinPips * pip);
   }
   return dist;
}

void EnsureStopsMinDistance(const int dir, const double entry, double &sl, double &tp)
{
   double minDist = GetMinStopDistance();
   // Если брокер не требует дистанции, используем хотя бы 5 пунктов как минимум
   if(minDist <= 0.0) minDist = 5*_Point;

   if(dir>0)
   {
      if(sl > 0.0 && (entry - sl) < minDist) sl = entry - minDist;
      if(tp > 0.0 && (tp - entry) < minDist) tp = entry + minDist;
   }
   else if(dir<0)
   {
      if(sl > 0.0 && (sl - entry) < minDist) sl = entry + minDist;
      if(tp > 0.0 && (entry - tp) < minDist) tp = entry - minDist;
   }
}

// Учитывает минимальную дистанцию относительно РЫНОЧНОЙ цены (Bid/Ask)
void EnsureStopsMinDistanceMarket(const int dir, double &sl, double &tp)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minDist = GetMinStopDistance();
   if(minDist <= 0.0) minDist = 5*_Point;

   if(dir>0)
   {
      if(sl > 0.0 && (bid - sl) < minDist) sl = bid - minDist;
      if(tp > 0.0 && (tp - ask) < minDist) tp = ask + minDist;
      if(sl >= bid) sl = bid - minDist;
      if(tp > 0.0 && tp <= ask) tp = ask + minDist;
   }
   else if(dir<0)
   {
      if(sl > 0.0 && (sl - ask) < minDist) sl = ask + minDist;
      if(tp > 0.0 && (bid - tp) < minDist) tp = bid - minDist;
      if(sl <= ask) sl = ask + minDist;
      if(tp > 0.0 && tp >= bid) tp = bid - minDist;
   }

   sl = (sl>0.0 ? NormalizeDouble(sl, _Digits) : 0.0);
   tp = (tp>0.0 ? NormalizeDouble(tp, _Digits) : 0.0);
}

// Возвращает SL и TP по методике MF‑V
void ComputeSLTP(const int dir, const bool isEarly, const double entryPrice, double &outSL, double &outTP)
{
   outSL = 0.0; outTP = 0.0;

   // Режим фиксированных стопов (пункты 4-знака; для 5 знаков 1 пункт = 10 поинтов)
   if(UseFixedSLTP)
   {
      double pip = ((_Digits==5 || _Digits==3) ? 10.0*_Point : _Point);
      double slDist = (FixedSL_Pips > 0 ? (double)FixedSL_Pips * pip : 0.0);
      double tpDist = (FixedTP_Pips > 0 ? (double)FixedTP_Pips * pip : 0.0);
      if(slDist>0.0) outSL = (dir>0 ? entryPrice - slDist : entryPrice + slDist);
      if(tpDist>0.0) outTP = (dir>0 ? entryPrice + tpDist : entryPrice - tpDist);
      return;
   }

   if(!UseAutoSLTP) return;

   // Пивоты
   double pivotH1 = CalcConfirmedPivot(PERIOD_H1);
   double pivotM15 = CalcConfirmedPivot(PERIOD_M15);
   double pivotH4 = CalcConfirmedPivot(PERIOD_H4);

   // База для SL: pivot H1, либо M15 для ранних при включённой опции
   double basePivot = ((isEarly && UseM15PivotForEarly && pivotM15>0.0) ? pivotM15 : pivotH1);
   double atrH1 = GetATR(PERIOD_H1);
   double extra = SL_AtrK_H1 * atrH1 + SL_ExtraPoints * _Point;

   if(basePivot>0.0)
   {
      if(dir>0) outSL = basePivot - extra; else outSL = basePivot + extra;
   }
   else
   {
      // Fallback: ATR-базовый SL, если пивот недоступен
      double atrM15 = GetATR(PERIOD_M15);
      double pad = (SL_AtrK_H1>0.0 ? SL_AtrK_H1*atrH1 : 0.0) + SL_ExtraPoints*_Point + 0.5*atrM15;
      if(dir>0) outSL = entryPrice - pad; else outSL = entryPrice + pad;
   }

   // Обеспечиваем корректность сторон относительно цены входа
   if(dir>0 && (outSL<=0.0 || outSL>=entryPrice)) outSL = entryPrice - MathMax(5*_Point, 0.5*GetATR(PERIOD_M15));
   if(dir<0 && (outSL<=entryPrice)) outSL = entryPrice + MathMax(5*_Point, 0.5*GetATR(PERIOD_M15));

   // TakeProfit
   if(TakeProfitMode == TP_RiskReward && outSL>0.0)
   {
      double risk = MathAbs(entryPrice - outSL);
      if(dir>0) outTP = entryPrice + TP_RR * risk; else outTP = entryPrice - TP_RR * risk;
   }
   else if(TakeProfitMode == TP_PivotHigher)
   {
      // Цель — ближайший pivot старшего ТФ по направлению: H4 предпочтительно, если есть; иначе H1
      double target = 0.0;
      if(dir>0)
      {
         if(pivotH4>entryPrice) target = pivotH4; else if(pivotH1>entryPrice) target = pivotH1;
      }
      else
      {
         if(pivotH4<entryPrice && pivotH4>0.0) target = pivotH4; else if(pivotH1<entryPrice && pivotH1>0.0) target = pivotH1;
      }
      if(target>0.0) outTP = target;
   }

   // Финальная нормализация и страховка направлений
   outSL = NormalizeDouble(outSL, _Digits);
   outTP = NormalizeDouble(outTP, _Digits);
   if(dir>0)
   {
      if(outTP<=entryPrice && TakeProfitMode!=TP_None)
      {
         double risk = MathAbs(entryPrice - outSL);
         outTP = NormalizeDouble(entryPrice + TP_RR * MathMax(risk, 5*_Point), _Digits);
      }
   }
   else if(dir<0)
   {
      if(outTP>=entryPrice && TakeProfitMode!=TP_None)
      {
         double risk = MathAbs(entryPrice - outSL);
         outTP = NormalizeDouble(entryPrice - TP_RR * MathMax(risk, 5*_Point), _Digits);
      }
   }
}

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber((long)Magic);
   trade.SetDeviationInPoints(Slippage);
   // Use indicator with default parameters (no arguments after path)
   indHandle = iCustom(_Symbol, PERIOD_CURRENT, "MasterForex_Pivot_my_v82308");
   if(indHandle == INVALID_HANDLE)
   {
      Print("[MFV EA] iCustom failed. Ensure 'MasterForex_Pivot_my_v82308.ex5' is in Indicators.");
      return(INIT_FAILED);
   }
   lastBarProcessed = 0;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(indHandle != INVALID_HANDLE)
   {
      IndicatorRelease(indHandle);
      indHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Helper: get open position direction for this symbol/magic        |
//+------------------------------------------------------------------+
int GetOpenDirection()
{
   // Проверяем только позицию по текущему символу и нашему Magic
   if(!PositionSelect(_Symbol)) return 0;
   if((ulong)PositionGetInteger(POSITION_MAGIC) != Magic) return 0;
   long type = PositionGetInteger(POSITION_TYPE);
   return (type==POSITION_TYPE_BUY ? +1 : -1);
}

//+------------------------------------------------------------------+
//| Helper: close any open position for this symbol/magic            |
//+------------------------------------------------------------------+
bool CloseOpenPosition()
{
   if(!PositionSelect(_Symbol)) return true;
   if((ulong)PositionGetInteger(POSITION_MAGIC) != Magic) return true;
   bool ok = trade.PositionClose(_Symbol, (ulong)Slippage);
   if(!ok) Print("[MFV EA] Close failed: ", _LastError);
   return ok;
}

//+------------------------------------------------------------------+
//| Helper: open trade with lot multiplier and MF-V SL/TP            |
//+------------------------------------------------------------------+
bool OpenTrade(const int dir, const double lotMult, const string tag)
{
   double lots = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), BaseLots * lotMult);
   lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   lots = MathRound(lots / SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   bool ok=false;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry = (dir>0? ask : bid);

   double sl=0.0, tp=0.0;
   // Признак «раннего» сигнала берём из тега
   bool isEarly = (StringFind(tag, "Early")>=0);
   ComputeSLTP(dir, isEarly, entry, sl, tp);

   bool noTP = (UseFixedSLTP && FixedTP_Pips <= 0) || (TakeProfitMode==TP_None);

   // Если SL/TP не рассчитались (нулевые) — ставим безопасный минимальный стоп, чтобы ордера были со стопами
   if(sl <= 0.0)
   {
      double minStop = MathMax(GetMinStopDistance(), 0.5*GetATR(PERIOD_M15));
      if(dir>0) sl = entry - minStop; else sl = entry + minStop;
   }
   if(!noTP && tp<=0.0)
   {
      double risk = MathAbs(entry - sl);
      if(dir>0) tp = entry + TP_RR * risk; else tp = entry - TP_RR * risk;
   }

   // Приводим SL/TP к минимально допустимой дистанции: сначала от цены входа, затем от текущего рынка
   EnsureStopsMinDistance(dir, entry, sl, tp);
   EnsureStopsMinDistanceMarket(dir, sl, tp);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   // Проверяем допустимость значений перед отправкой ордера
   if(dir>0)
   {
      if(!noTP && tp>0.0 && tp<=entry) tp = entry + GetMinStopDistance();
      if(sl>0.0 && sl>=entry) sl = entry - GetMinStopDistance();
      EnsureStopsMinDistanceMarket(dir, sl, tp);
      ok = trade.Buy(lots, _Symbol, 0.0, sl, (noTP?0.0:tp), tag);
   }
   else
   {
      if(!noTP && tp>0.0 && tp>=entry) tp = entry - GetMinStopDistance();
      if(sl>0.0 && sl<=entry) sl = entry + GetMinStopDistance();
      EnsureStopsMinDistanceMarket(dir, sl, tp);
      ok = trade.Sell(lots, _Symbol, 0.0, sl, (noTP?0.0:tp), tag);
   }
   if(!ok)
   {
      Print("[MFV EA] Open failed: ", _LastError, " (", tag, ")");
      return false;
   }

   // Некоторые брокеры игнорируют SL/TP при немедленном открытии — выставим их отдельным модифаем с повторами
   for(int attempt=0; attempt<ForceSetStopsAttempts; ++attempt)
   {
      if(ApplyStopsIfMissing(dir, sl, (noTP?0.0:tp))) break;
      Sleep((uint)ForceSetStopsDelayMs);
   }
   return true;
}

//+------------------------------------------------------------------+
//| Main tick                                                        |
//+------------------------------------------------------------------+
void OnTick()
{
   if(indHandle == INVALID_HANDLE) return;
   // Process only once per closed bar
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 1);
   if(t1 == 0 || t1 == lastBarProcessed) return;

   // Read last closed-bar values from indicator buffers
   double bStrongBuy[], bStrongSell[], bBuy[], bSell[], bEarlyBuy[], bEarlySell[], bExit[];
   ArraySetAsSeries(bStrongBuy, true); ArraySetAsSeries(bStrongSell, true);
   ArraySetAsSeries(bBuy, true);       ArraySetAsSeries(bSell, true);
   ArraySetAsSeries(bEarlyBuy, true);  ArraySetAsSeries(bEarlySell, true);
   ArraySetAsSeries(bExit, true);

   bool ok = true;
   ok = ok && (CopyBuffer(indHandle, BUF_STRONG_BUY, 1, 1, bStrongBuy) == 1);
   ok = ok && (CopyBuffer(indHandle, BUF_STRONG_SELL,1, 1, bStrongSell)== 1);
   ok = ok && (CopyBuffer(indHandle, BUF_BUY,        1, 1, bBuy)        == 1);
   ok = ok && (CopyBuffer(indHandle, BUF_SELL,       1, 1, bSell)       == 1);
   ok = ok && (CopyBuffer(indHandle, BUF_EARLY_BUY,  1, 1, bEarlyBuy)   == 1);
   ok = ok && (CopyBuffer(indHandle, BUF_EARLY_SELL, 1, 1, bEarlySell)  == 1);
   ok = ok && (CopyBuffer(indHandle, BUF_EXIT,       1, 1, bExit)       == 1);
   if(!ok)
   {
      Print("[MFV EA] CopyBuffer failed");
      lastBarProcessed = t1; // avoid tight loop
      return;
   }

   int dir = GetOpenDirection();

   // Exit on hard exit signal
   if(CloseOnExitSignal && dir!=0 && bExit[0] != EMPTY_VALUE)
   {
      CloseOpenPosition();
      dir = 0;
   }

   if(!AllowNewPositions)
   {
      lastBarProcessed = t1;
      return;
   }

   // Determine entry priority: Strong > Normal > Early
   int sigDir = 0; double lotMult = 0.0; string tag = "";
   if(bStrongBuy[0] != EMPTY_VALUE) { sigDir = +1; lotMult = StrongLotMultiplier; tag = "StrongBuy"; }
   else if(bStrongSell[0] != EMPTY_VALUE) { sigDir = -1; lotMult = StrongLotMultiplier; tag = "StrongSell"; }
   else if(bBuy[0] != EMPTY_VALUE) { sigDir = +1; lotMult = NormalLotMultiplier; tag = "Buy"; }
   else if(bSell[0] != EMPTY_VALUE) { sigDir = -1; lotMult = NormalLotMultiplier; tag = "Sell"; }
   else if(bEarlyBuy[0] != EMPTY_VALUE) { sigDir = +1; lotMult = EarlyLotMultiplier; tag = "EarlyBuy"; }
   else if(bEarlySell[0] != EMPTY_VALUE) { sigDir = -1; lotMult = EarlyLotMultiplier; tag = "EarlySell"; }

   if(sigDir != 0)
   {
      // If opposite direction already open — close first
      if(dir != 0 && dir != sigDir)
      {
         if(!CloseOpenPosition()) { lastBarProcessed = t1; return; }
         dir = 0;
      }
      if(dir == 0)
      {
          OpenTrade(sigDir, lotMult, StringFormat("MFV %s", tag));
      }
   }

   // Сопровождение: подтягивать SL к pivot M15 при профите
   if(TrailByM15Pivot && PositionSelect(_Symbol) && (ulong)PositionGetInteger(POSITION_MAGIC)==Magic)
   {
      // Если по какой-то причине SL/TP отсутствуют — попробуем снова проставить на лету (recovery)
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);
      int    pDir  = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?+1:-1);
      bool noTP = (UseFixedSLTP && FixedTP_Pips <= 0) || (TakeProfitMode==TP_None);
      if(curSL<=0.0 || (!noTP && curTP<=0.0))
      {
         double entry = PositionGetDouble(POSITION_PRICE_OPEN);
         double slR=0.0,tpR=0.0; ComputeSLTP(pDir, /*isEarly*/false, entry, slR, tpR);
         ApplyStopsIfMissing(pDir, slR, (noTP?0.0:tpR));
      }

      double pivotM15 = CalcConfirmedPivot(PERIOD_M15);
      if(pivotM15>0.0)
      {
         long pType = PositionGetInteger(POSITION_TYPE);
         double curSL = PositionGetDouble(POSITION_SL);
         if(curSL <= 0.0) { lastBarProcessed = t1; return; }
         double price = (pType==POSITION_TYPE_BUY? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
         // Trail only towards profit, add minimal offset
         double newSL = curSL;
         double offset = MathMax(SL_ExtraPoints * _Point, GetMinStopDistance());
         if(pType==POSITION_TYPE_BUY)
         {
            double candidate = pivotM15 - offset;
            if(candidate > curSL && candidate < price)
               newSL = candidate;
         }
         else
         {
            double candidate = pivotM15 + offset;
            if((curSL==0.0 || candidate < curSL) && candidate > price)
               newSL = candidate;
         }
         if(newSL != curSL)
            trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
      }
   }

   lastBarProcessed = t1;
}

//+------------------------------------------------------------------+
//| Set SL/TP right after actual deal appears (robust)               |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   string sym = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   if(sym != _Symbol) return;
   long mg = (long)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(mg != (long)Magic) return;
   int dType = (int)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
   if(dType != DEAL_TYPE_BUY && dType != DEAL_TYPE_SELL) return;

   int dir = (dType==DEAL_TYPE_BUY? +1 : -1);
   double price = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
   string comm = HistoryDealGetString(trans.deal, DEAL_COMMENT);
   bool isEarly = (StringFind(comm, "Early")>=0);

   double sl=0.0, tp=0.0;
   ComputeSLTP(dir, isEarly, price, sl, tp);
   EnsureStopsMinDistance(dir, price, sl, tp);
   EnsureStopsMinDistanceMarket(dir, sl, tp);
   sl = (sl>0.0? NormalizeDouble(sl,_Digits):0.0);
   bool noTP = (UseFixedSLTP && FixedTP_Pips <= 0) || (TakeProfitMode==TP_None);
   tp = (noTP?0.0:(tp>0.0?NormalizeDouble(tp,_Digits):0.0));

   // Повторные попытки если сервер занят/заморожен
   for(int attempt=0; attempt<ForceSetStopsAttempts; ++attempt)
   {
      if(PositionSelect(_Symbol) && (ulong)PositionGetInteger(POSITION_MAGIC)==Magic)
      {
         if(trade.PositionModify(_Symbol, sl, tp)) break;
      }
      Sleep((uint)ForceSetStopsDelayMs);
   }
}


