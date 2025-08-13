//+------------------------------------------------------------------+
//| MasterForex-V MultiTF Indicator v8.2308                          |
//| Индикатор с подтверждёнными MF-pivot и дополнительными сигналами |
//| Улучшенная версия с дополнительными настройками                  |
//| Соответствует стратегии MasterForex-V                             |
//+------------------------------------------------------------------+
#property copyright "MasterForex-V"
#property link      "https://www.masterforex-v.org/"
#property version   "8.230"
#property strict
// Убираем предупреждения тестера о зависимости от встроенного ZigZag
#property tester_indicator "ZigZag"

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9

// --- Breakout confirmation settings
enum ConfirmMode { Confirm_Off, Confirm_StrongOnly, Confirm_StrongAndNormal, Confirm_All };

//--- Input Parameters / Входные параметры
input group "=== Основные настройки ==="
input bool   UseRussian = false;              // Подписи на русском языке
input bool   ShowClassicPivot = false;         // Показывать классические уровни Pivot
input bool   ShowStatusInfo = true;           // Показывать информацию о статусе
input bool   EnableVolumeFilter = true;       // Фильтр по объему
input bool   EnableSessionFilter = true;      // Фильтр торговых сессий

input group "=== Пивоты High/Low и ТФ ==="
input bool   ShowPivotHighLow = true;         // Рисовать Pivot High/Low на всех ТФ
input bool   UseTF_H4 = true;                 // Использовать H4 dual-pivot
input bool   UseTF_D1 = true;                 // Использовать D1 dual-pivot

input group "=== Сессии ==="
input int    SessionGMTOffset = 2;            // Смещение серверного времени относительно GMT (пример: 2 для GMT+2)

input group "=== Настройки ZigZag ==="
input int    InpDepth = 12;                   // Глубина ZigZag
input double InpDeviation = 5.0;              // Отклонение в пунктах
input double AtrDeviationK = 0.0;             // Коэф. ATR для адаптивного порога (0=выкл)

input group "=== Фильтры MasterForex-V ==="
input double MinVolumeMultiplier = 1.2;       // Минимальный множитель объема
input int    MinTrendStrength = 2;            // Минимальная сила тренда (1-3)
input int    MinEarlyTrendStrength = 1;       // Минимальная сила тренда для ранних входов (1-3)
input bool   UseRiskManagement = true;        // Использовать управление рисками
input double MaxRiskPercent = 2.0;            // Максимальный риск в %

input group "=== Подтверждение пробоя Pivot (H1) ==="
input ConfirmMode BreakoutConfirm = Confirm_StrongOnly; // Режим подтверждения
input int    H1ClosesNeeded       = 2;     // Сколько H1-закрытий за pivot (1-2)
input int    RetestWindowM15      = 12;    // Окно ретеста в M15-барах (до 3 ч)
input double RetestTolATR_M15     = 0.25;  // Допуск касания: ±0.25*ATR(M15)
input double WickRejectMin        = 0.60;  // Мин. доля тени в диапазоне бара
input bool   UseRetestVolume      = true;  // Учитывать объём на ретесте
input double RetestVolMult        = 1.20;  // Объём ретеста > 1.2x среднего
input bool   RetestAllowM5        = true;  // Разрешить ретест на M5 как альтернативу M15
input int    RetestWindowM5       = 36;    // Окно ретеста в M5-барах (около 3 ч)
input double RetestTolATR_M5      = 0.35;  // Допуск касания: ±0.35*ATR(M5)

input group "=== Импульс-откат (MF A-B-C на M15) ==="
input bool   UseImpulseFilter     = true;   // Включить фильтр импульса/отката
input double ImpulseMinRatio      = 1.5;    // |B−A| / |C−B| минимум для "здорового" импульса
input double PullbackMaxFib       = 0.618;  // Максимальная глубина отката (доля импульса)
input int    ImpulseBackWindowM15 = 48;     // Поиск A перед B (M15-баров)
input int    PullbackWindowM15    = 12;     // Поиск C после B (M15-баров)

input group "=== Фильтр рыночной фазы (Flat/Trend) ==="
input bool   UseMarketPhaseFilter = true;   // Включить фильтр флет/тренд
input double FlatMedianThreshold  = 1.20;   // Порог медианы соотношений качелей (ниже — флет)

input group "=== Clinch вокруг Pivot H1 (MF-V) ==="
input bool   UseClinchFilter   = true;        // Включить фильтр «схватки»
input double ClinchAtrK        = 0.50;        // Полуширина зоны: k * ATR(H1)
input int    ClinchLookbackH1  = 24;          // Сколько H1-баров анализировать
input int    ClinchFlipsMin    = 3;           // Минимум перебросов через pivotH1
input double ClinchRangeMaxATR = 1.20;        // Макс. диапазон за Lookback в ATR(H1)
input bool   ShowClinchZoneOnlyIfTouched = true; // Показывать зону только если цена входила в неё за Lookback

input group "=== Цвета стрелок ==="
input color  BuyArrowColor = clrLime;         // Цвет стрелки покупки
input color  SellArrowColor = clrRed;         // Цвет стрелки продажи
input color  EarlyBuyColor = clrDodgerBlue;   // Цвет ранней покупки
input color  EarlySellColor = clrDeepSkyBlue; // Цвет ранней продажи
input color  ExitColor = clrGray;             // Цвет выхода
input color  ReverseColor = clrAqua;          // Цвет разворота
input color  StrongSignalColor = clrYellow;   // Цвет сильного сигнала
input color  EarlyExitColor = clrSandyBrown;  // Цвет раннего выхода

input group "=== Цвета линий Pivot ==="
input color  PivotHighColor = clrRed;         // Цвет Pivot High (сопротивление)
input color  PivotLowColor  = clrLime;        // Цвет Pivot Low  (поддержка)
input color  PivotH1Color = clrBlue;          // Цвет H1 Pivot
input color  PivotM15Color = clrGreen;        // Цвет M15 Pivot
input color  PivotM5Color = clrOrange;        // Цвет M5 Pivot
input color  PivotH4Color = clrMagenta;       // Цвет H4 Pivot
input color  PivotD1Color = clrDimGray;       // Цвет D1 Pivot

input group "=== Размеры стрелок ==="
input int    ArrowWidth = 2;                  // Толщина стрелок
input int    ArrowOffset = 10;                // Смещение стрелок в пунктах

input group "=== Отображение сигналов ==="
input bool   ShowStrongSignals  = true;       // Показывать сильные (жёлтые) входы
input bool   ShowNormalSignals  = true;       // Показывать обычные (зел/красн.) входы
input bool   ShowEarlySignals   = true;       // Показывать ранние (голубые) входы
input bool   ShowExitSignals    = true;       // Показывать выходы (крестик/ранний выход)
input bool   ShowReversalSignals= true;       // Показывать развороты (аква)
input bool   ShowHistorySignals = true;       // Исторические стрелки (иначе — только последнюю)
input int    SignalsLookbackBars= 500;        // Ограничение истории стрелок (закрытые бары)
input int    MinBarsBetweenArrows = 6;        // Минимум баров между одинаковыми стрелками

// Якорение стрелок к базовому ТФ, чтобы сигналы были одинаковыми на всех графиках
enum AnchorMode { Anchor_Current, Anchor_M5 };
input AnchorMode SignalAnchor = Anchor_M5;    // На каком ТФ фиксировать время сигнала при отрисовке

// --- Exit mode settings
enum ExitMode { Exit_H1, Exit_EntryTF, Exit_Nearest, Exit_SoftHard };
input ExitMode ExitLogic = Exit_H1;           // Режим выхода (по умолчанию H1)
input double   ExitNearestAtrK = 0.25;        // Мин. дистанция до пивота в ATR(M15) для режима Nearest

// --- Consensus filter settings
enum ConsensusMode { Cons_Off, Cons_PanelOnly, Cons_GateStrong, Cons_GateStrongNormal, Cons_BlockAll };
input ConsensusMode  Consensus   = Cons_PanelOnly;
input int   EmaFast = 50;
input int   EmaSlow = 200;
input int   RsiPeriod = 14;
input double EmaSlopeMin = 0.0;              // минимальный наклон EMA50 в пунктах цены
input int   RsiOB = 70, RsiOS = 30;          // границы перекуп/перепрод
input int   RsiHyst = 5;                     // гистерезис

//--- Buy arrow / Стрелка покупки
#property indicator_label1  "BuyArrow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Sell arrow / Стрелка продажи
#property indicator_label2  "SellArrow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Additional plot labels for Data Window
#property indicator_label3  "EarlyBuy"
#property indicator_label4  "EarlySell"
#property indicator_label5  "Exit"
#property indicator_label6  "Reverse"
#property indicator_label7  "StrongBuy"
#property indicator_label8  "StrongSell"
#property indicator_label9  "EarlyExit"

//--- Buffers for various signals / Буферы сигналов
double BuyArrowBuffer[];    // сильный сигнал покупки
double SellArrowBuffer[];   // сильный сигнал продажи
double EarlyBuyBuffer[];    // ранний вход покупка
double EarlySellBuffer[];   // ранний вход продажа
double ExitBuffer[];        // крестик выхода
double ReverseBuffer[];     // метка разворота
double StrongBuyBuffer[];   // очень сильный сигнал покупки
double StrongSellBuffer[];  // очень сильный сигнал продажи
double EarlyExitBuffer[];   // ранний выход

//--- ATR(H1) и Clinch-кэш
int    atrH1Handle = INVALID_HANDLE;
double lastAtrH1   = 0.0;
datetime lastClinchCalcOnH1 = 0;

struct ClinchStatus
{
   bool     isClinch;
   bool     touched;  // цена заходила в зону за период Lookback
   int      flips;
   double   range;
   double   atr;
   double   zoneTop;
   double   zoneBot;
   datetime fromTime;
   datetime toTime;
};

enum SigClass { SigNone, SigEarly, SigNormal, SigStrong };

// --- Dual-pivot per timeframe (High/Low) non-repainting cache
struct TFPivots
{
   double   high;       // последний подтверждённый swing High (начал нисходящее колено)
   datetime high_time;
   double   low;        // последний подтверждённый swing Low (начал восходящее колено)
   datetime low_time;
   int      lastSwing;  // +1: последний подтверждённый Low (вверх), -1: High (вниз)
};

static TFPivots pivH1, pivM15, pivM5, pivH4, pivD1;
static datetime pivotsLastUpdate = 0;
static bool pivotsEverReady = false; // станет true, когда H1/M15/M5 получат оба уровня H/L

// ZigZag handles per TF
int zzH1 = INVALID_HANDLE, zzM15 = INVALID_HANDLE, zzM5 = INVALID_HANDLE, zzH4 = INVALID_HANDLE, zzD1 = INVALID_HANDLE;

int CopyCloseH1(const int bars, double &buf[])
{
   ArraySetAsSeries(buf, true);
   int got = CopyClose(_Symbol, PERIOD_H1, 0, bars, buf);
   return got;
}

// Универсальная подкачка истории: триггер загрузки, проверка синхронизации, оценка факта наличия
bool EnsureHistory(const string sym, ENUM_TIMEFRAMES tf, int needBars)
{
   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int got = CopyRates(sym, tf, 0, needBars, rates);
   bool synced = (SeriesInfoInteger(sym, tf, SERIES_SYNCHRONIZED) != 0);
   int have = (int)Bars(sym, tf);
   return (got > 0 || have >= MathMin(needBars, 100)) && synced;
}

// Проверка готовности буфера встроенного ZigZag
bool EnsureZigZagReady(int handle)
{
   if(handle == INVALID_HANDLE) return false;
   int bc = BarsCalculated(handle);
   return (bc > 0);
}

// Вычисляет A-B-C на M15 в направлении dir (+1/-1)
// Возвращает true, если импульс "здоровый" (ratio >= ImpulseMinRatio) и откат не глубже PullbackMaxFib
bool CheckImpulsePullback_M15(const int dir, double &outRatio)
{
   outRatio = 0.0;
   if(!UseImpulseFilter) return true;

   // Ищем локальный максимум/минимум B в направлении тренда как точку импульса
   double b = (dir>0 ? iHigh(_Symbol, PERIOD_M15, 1) : iLow(_Symbol, PERIOD_M15, 1));
   int bIndex = 1;

   // Найти A до B в окне ImpulseBackWindowM15 как противоположный экстремум
   double a = b; int aIndex = bIndex;
   int back = MathMin(MathMax(ImpulseBackWindowM15, 3), 96);
   for(int i=2; i<=back; ++i)
   {
      double hi = iHigh(_Symbol, PERIOD_M15, i);
      double lo = iLow(_Symbol, PERIOD_M15, i);
      if(dir>0){ if(lo < a){ a = lo; aIndex = i; } }
      else     { if(hi > a){ a = hi; aIndex = i; } }
   }

   // Найти C после B как противоположное движение в окне PullbackWindowM15
   double c = b; int cIndex = bIndex;
   int fwd = MathMin(MathMax(PullbackWindowM15, 2), 48);
   for(int j=1; j<=fwd; ++j)
   {
      double hi = iHigh(_Symbol, PERIOD_M15, j);
      double lo = iLow(_Symbol, PERIOD_M15, j);
      if(dir>0){ if(lo < c){ c = lo; cIndex = j; } }
      else     { if(hi > c){ c = hi; cIndex = j; } }
   }

   double impulse = MathAbs(b - a);
   double pullback = MathAbs(c - b);
   if(impulse <= 0.0) return false;
   outRatio = (pullback>0.0 ? (impulse / pullback) : 999.0);

   // Глубина отката от импульса (Фибо): доля |C−B|/|B−A|
   double fibDepth = (impulse>0.0 ? (pullback / impulse) : 0.0);
   bool ratioOk = (outRatio >= ImpulseMinRatio);
   bool depthOk = (fibDepth <= PullbackMaxFib);
   return (ratioOk && depthOk);
}
int CopyRatesH1(const int bars, MqlRates &r[])
{
   ArraySetAsSeries(r, true);
   int got = CopyRates(_Symbol, PERIOD_H1, 0, bars, r);
   return got;
}

// Оценка рыночной фазы по трём последним качелям (отрезкам) на M15
// Метод: находим экстремумы простым проходом и считаем длины трёх последних колен; 
// берём отношения соседних длин, считаем медиану. Если медиана < FlatMedianThreshold — флет.
bool IsFlatPhase_M15()
{
   if(!UseMarketPhaseFilter) return false; // не считаем флет, фильтр выключен

   // Соберём последние N баров для детекции качелей
   const int N = 200;
   double h[], l[]; ArraySetAsSeries(h, true); ArraySetAsSeries(l, true);
   if(CopyHigh(_Symbol, PERIOD_M15, 0, N, h) < 3 || CopyLow(_Symbol, PERIOD_M15, 0, N, l) < 3)
      return false;

   // Поиск локальных экстремумов простым правилом (3-точечный)
   int idxs[256]; double px[256]; int cnt=0;
   for(int i= N-2; i>=1 && cnt<256; --i)
   {
      bool isHi = (h[i] > h[i+1] && h[i] > h[i-1]);
      bool isLo = (l[i] < l[i+1] && l[i] < l[i-1]);
      if(isHi || isLo){ idxs[cnt]=i; px[cnt]=(isHi? h[i]: l[i]); cnt++; }
   }
   if(cnt < 6) return false; // нужно хотя бы 3 колена (6 экстремумов)

   // Возьмём три последних колена (между 4 экстремумами)
   double len1 = MathAbs(px[0] - px[1]);
   double len2 = MathAbs(px[1] - px[2]);
   double len3 = MathAbs(px[2] - px[3]);
   if(len1<=0 || len2<=0 || len3<=0) return false;

   // Отношения длин соседних колен
   double r1 = (len1>len2 ? len1/len2 : len2/len1);
   double r2 = (len2>len3 ? len2/len3 : len3/len2);
   double r3 = (len1>len3 ? len1/len3 : len3/len1);

   // Медиана трёх значений (ручная сортировка из 3)
   double a=r1, b=r2, c=r3;
   if(a>b){ double t=a; a=b; b=t; }
   if(b>c){ double t=b; b=c; c=t; }
   if(a>b){ double t=a; a=b; b=t; }
   double med = b;

   return (med < FlatMedianThreshold);
}
// Проверка закрепления H1 за соответствующим уровнем: для buy — PivotHigh_H1, для sell — PivotLow_H1
bool CheckH1Breakout(const double pivotH1_H, const double pivotH1_L, const int dir)
{
   // dir = +1 buy, -1 sell
   double c0 = iClose(_Symbol, PERIOD_H1, 1);
    if(H1ClosesNeeded <= 1)
       return (dir>0 ? c0>pivotH1_H : c0<pivotH1_L);
   double c1 = iClose(_Symbol, PERIOD_H1, 2);
    return (dir>0 ? (c0>pivotH1_H && c1>pivotH1_H) : (c0<pivotH1_L && c1<pivotH1_L));
}

// Ретест уровня H1 на M15 с отскоком: для buy ретест PivotHigh_H1, для sell — PivotLow_H1
bool CheckRetestBounce_M15(const double pivotH1Level, const int dir, datetime fromTime)
{
   // Используем завершенные бары M15, не более 48
   // Правильный вызов ATR через хэндл и CopyBuffer
   int atrHandle = iATR(_Symbol, PERIOD_M15, 14);
   if(atrHandle == INVALID_HANDLE) return false;
   double atrBuf[]; ArraySetAsSeries(atrBuf, true);
   double atr = 0.0;
   if(CopyBuffer(atrHandle, 0, 1, 1, atrBuf) == 1)
      atr = atrBuf[0];
   if(atr<=0) return false;
    double half = RetestTolATR_M15 * atr;
    double top  = pivotH1Level + half, bot = pivotH1Level - half;

   // Начинаем с конца закрытого H1-часа
   int shStart = iBarShift(_Symbol, PERIOD_M15, fromTime, false);
   int bars = MathMin(MathMax(RetestWindowM15, 1), 48);
   for(int i=shStart-1, seen=0; i>=1 && seen<bars; --i, ++seen)
   {
      datetime t = iTime(_Symbol, PERIOD_M15, i);
      if(t <= fromTime) continue; // только строго после закрытия часа

      double o=iOpen(_Symbol,PERIOD_M15,i),
             h=iHigh(_Symbol,PERIOD_M15,i),
             l=iLow(_Symbol,PERIOD_M15,i),
             c=iClose(_Symbol,PERIOD_M15,i);
      long   v=iVolume(_Symbol,PERIOD_M15,i);

      bool touched = (h>=bot && l<=top);
      if(!touched) continue;

      double rangeBar = MathMax(h-l, _Point);
      double wick     = (dir>0 ? h-c : c-l);
      bool wickOk     = (rangeBar>0 ? (wick / rangeBar >= WickRejectMin) : false);
       bool closeOk    = (dir>0 ? c>pivotH1Level : c<pivotH1Level);

      bool volOk = true;
      if(UseRetestVolume)
      {
         double avg=0.0; int cnt=0;
         for(int k=i+1; k<=i+20; ++k){ long vv=iVolume(_Symbol,PERIOD_M15,k); if(vv<=0) continue; avg += (double)vv; cnt++; }
         if(cnt>0) avg/=cnt; else avg=0.0;
         volOk = (avg>0.0 ? ( (double)v >= RetestVolMult*avg ) : true);
      }
      if(closeOk && wickOk && volOk) return true;
   }
   return false;
}

bool CheckRetestBounce_M5(const double pivotH1Level, const int dir, datetime fromTime)
{
   int shStart = iBarShift(_Symbol, PERIOD_M5, fromTime, false);
   int bars = MathMin(MathMax(RetestWindowM5, 1), 120);
   int atrHandle = iATR(_Symbol, PERIOD_M5, 14);
   double aBuf[]; ArraySetAsSeries(aBuf, true);
   double atr = 0.0; if(atrHandle!=INVALID_HANDLE && CopyBuffer(atrHandle,0,1,1,aBuf)==1) atr=aBuf[0];
   if(atr<=0) return false;
    double half = RetestTolATR_M5 * atr;
    double top  = pivotH1Level + half, bot = pivotH1Level - half;
   for(int i=shStart-1, seen=0; i>=1 && seen<bars; --i, ++seen)
   {
      datetime t = iTime(_Symbol, PERIOD_M5, i);
      if(t <= fromTime) continue;
      double o=iOpen(_Symbol,PERIOD_M5,i),
             h=iHigh(_Symbol,PERIOD_M5,i),
             l=iLow(_Symbol,PERIOD_M5,i),
             c=iClose(_Symbol,PERIOD_M5,i);
      long   v=iVolume(_Symbol,PERIOD_M5,i);
      bool touched = (h>=bot && l<=top);
      if(!touched) continue;
      double rangeBar = MathMax(h-l, _Point);
      double wick     = (dir>0 ? h-c : c-l);
      bool wickOk     = (rangeBar>0 ? (wick / rangeBar >= WickRejectMin) : false);
       bool closeOk    = (dir>0 ? c>pivotH1Level : c<pivotH1Level);
      bool volOk = true;
      if(UseRetestVolume)
      {
         double avg=0.0; int cnt=0;
         for(int k=i+1; k<=i+20; ++k){ long vv=iVolume(_Symbol,PERIOD_M5,k); if(vv<=0) continue; avg += (double)vv; cnt++; }
         if(cnt>0) avg/=cnt; else avg=0.0;
         volOk = (avg>0.0 ? ( (double)v >= RetestVolMult*avg ) : true);
      }
      if(closeOk && wickOk && volOk) return true;
   }
   return false;
}
bool EnsureH1History(const int minBars)
{
   // Принудительно запрашиваем историю H1, чтобы расчеты работали на любом текущем таймфрейме
   MqlRates tmp[]; ArraySetAsSeries(tmp, true);
   int got = CopyRates(_Symbol, PERIOD_H1, 0, minBars, tmp);
   return (got >= minBars);
}

double GetATR_H1()
{
   double a[];
   ArraySetAsSeries(a, true);
   if(CopyBuffer(atrH1Handle, 0, 1, 1, a) == 1) // закрытый бар
      return a[0];
   return lastAtrH1 > 0 ? lastAtrH1 : 0.0;
}

//+------------------------------------------------------------------+
//| ZigZag access helpers and dual-pivot extraction                   |
//+------------------------------------------------------------------+
int GetZZHandle(const ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_H1:  return zzH1;
      case PERIOD_M15: return zzM15;
      case PERIOD_M5:  return zzM5;
      case PERIOD_H4:  return zzH4;
      case PERIOD_D1:  return zzD1;
      default:         return INVALID_HANDLE;
   }
}

// Сколько баров запрашивать для поиска последних подтверждённых H/L
int GetScanBarsForTF(const ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M5:  return 2000;  // ~7 дней
      case PERIOD_M15: return 800;   // ~8-9 дней
      case PERIOD_H1:  return 400;   // ~16-17 дней
      case PERIOD_H4:  return 200;   // ~33 дней
      case PERIOD_D1:  return 150;   // ~пару лет
      default:         return 1000;
   }
}

bool EnsureTFHistory(const ENUM_TIMEFRAMES tf, const int minBars)
{
   // Универсальная обвязка: триггерим загрузку и проверяем синхронизацию серии
   MqlRates tmp[]; ArraySetAsSeries(tmp, true);
   int got = CopyRates(_Symbol, tf, 0, minBars, tmp);
   bool synced = (SeriesInfoInteger(_Symbol, tf, SERIES_SYNCHRONIZED) != 0);
   int have = (int)Bars(_Symbol, tf);
   return (synced && (got > 0 || have >= MathMin(minBars, 100)));
}

// Читает ZigZag и обновляет подтверждённые High/Low для заданного ТФ.
// Используются только закрытые бары (индексы >=1). Не затирает противоположную сторону.
bool CalculatePivots(const ENUM_TIMEFRAMES tf, TFPivots &io)
{
   int h = GetZZHandle(tf);
   if(h == INVALID_HANDLE) return false;

   // Убедимся, что история подгружена минимум под наш скан
   int scan = GetScanBarsForTF(tf);
   EnsureTFHistory(tf, scan);
   int bars = iBars(_Symbol, tf);
   int cnt = MathMin(bars, scan);
   if(cnt < InpDepth + 5) return false;

   double bufHigh[], bufLow[]; ArraySetAsSeries(bufHigh, true); ArraySetAsSeries(bufLow, true);
   // Читаем только ЗАКРЫТЫЕ бары: старт с индекса 1 и ограничение по 3000 элементов
   int closed = MathMax(0, bars - 1);
   int want   = MathMin(closed, MathMin(3000, cnt));
   if(want <= 0) return false;
   // Стандартный ZigZag: буфер 1 — High, буфер 2 — Low (на некоторых билдах один из них может быть пуст)
   int gotH = CopyBuffer(h, 1, 1, want, bufHigh);
   int gotL = CopyBuffer(h, 2, 1, want, bufLow);

   double lastHigh=0.0, lastLow=0.0; int shHigh=-1, shLow=-1;
   int startShift = 1; // мы читали буферы с позиции 1 (закрытый бар)
   if(gotH>0)
      for(int i=0; i<want; ++i)
      {
         double v=bufHigh[i];
         if(v!=0.0 && v!=EMPTY_VALUE && MathIsValidNumber(v))
         {
            lastHigh=v; shHigh=startShift + i; break;
         }
      }
   if(gotL>0)
      for(int i=0; i<want; ++i)
      {
         double v=bufLow[i];
         if(v!=0.0 && v!=EMPTY_VALUE && MathIsValidNumber(v))
         {
            lastLow=v; shLow=startShift + i; break;
         }
      }

   // Fallback: если map-буферы пусты, читаем основной буфер ZigZag и классифицируем H/L по бару
   if((shHigh<0 || shLow<0))
   {
      double bufMain[]; ArraySetAsSeries(bufMain, true);
      int gotM = CopyBuffer(h, 0, 1, want, bufMain);
      if(gotM>0)
      {
         for(int i=0; i<want && (shHigh<0 || shLow<0); ++i)
         {
            int sh = startShift + i;
            double v = bufMain[i];
            if(v==0.0 || v==EMPTY_VALUE || !MathIsValidNumber(v)) continue;
            double hi = iHigh(_Symbol, tf, sh);
            double lo = iLow(_Symbol,  tf, sh);
            if(shHigh<0 && MathAbs(v-hi) <= 2*_Point){ lastHigh=v; shHigh=sh; }
            if(shLow <0 && MathAbs(v-lo) <= 2*_Point){ lastLow =v; shLow =sh; }
         }
      }
   }

   bool updated=false;
   // ATR-адаптация: требуем минимальную длину качели (если ATR недоступен — не блокируем обновление)
   if(AtrDeviationK > 0.0 && lastHigh>0.0 && lastLow>0.0)
   {
      int atrH = iATR(_Symbol, tf, 14);
      double aBuf[]; ArraySetAsSeries(aBuf, true);
      double atrTf = 0.0; if(atrH!=INVALID_HANDLE && CopyBuffer(atrH,0,1,1,aBuf)==1) atrTf=aBuf[0];
      if(atrTf>0.0)
      {
         double thr = MathMax(InpDeviation*_Point, AtrDeviationK*atrTf);
         if(MathAbs(lastHigh-lastLow) < thr) { /* слишком коротко — оставляем как есть */ }
      }
   }

   if(lastHigh>0.0 && shHigh>=1)
   {
      datetime t = iTime(_Symbol, tf, shHigh);
      if(t > io.high_time){ io.high = lastHigh; io.high_time = t; updated=true; }
   }
   if(lastLow>0.0 && shLow>=1)
   {
      datetime t = iTime(_Symbol, tf, shLow);
      if(t > io.low_time){ io.low = lastLow; io.low_time = t; updated=true; }
   }

   if(io.high_time==0 && io.low_time==0) return updated;
   if(io.high_time >= io.low_time && io.high_time!=0) io.lastSwing = -1; else if(io.low_time > io.high_time && io.low_time!=0) io.lastSwing = +1;
   return updated;
}

void UpdatePivotsCache()
{
   datetime now = TimeCurrent();
   // До первой инициализации НЕ троттлим, чтобы уйти от "Waiting for data..." на минуту
   if(pivotsEverReady && pivotsLastUpdate!=0 && (now - pivotsLastUpdate) <= 60) return;

   bool u1 = CalculatePivots(PERIOD_H1,  pivH1);
   bool u2 = CalculatePivots(PERIOD_M15, pivM15);
   bool u3 = CalculatePivots(PERIOD_M5,  pivM5);
   if(UseTF_H4) CalculatePivots(PERIOD_H4, pivH4);
   if(UseTF_D1) CalculatePivots(PERIOD_D1, pivD1);

   bool ok1 = (pivH1.high>0.0 && pivH1.low>0.0);
   bool ok2 = (pivM15.high>0.0 && pivM15.low>0.0);
   bool ok3 = (pivM5.high>0.0 && pivM5.low>0.0);
   // Включаем троттлинг только когда готова базовая тройка (H1/M15/M5)
   pivotsEverReady = (ok1 && ok2 && ok3);
   // Фиксируем метку времени только когда хотя бы что-то обновили или всё готово
   if(u1 || u2 || u3 || pivotsEverReady)
      pivotsLastUpdate = now;
}

// Тренд по dual‑pivot: Up если Close[1] > PivotLow и последний swing=Up; Down если Close[1] < PivotHigh и swing=Down.
int DetermineTrend(const TFPivots &p, const double close_t1, const double tol_param=0.0)
{
   if(p.high<=0.0 || p.low<=0.0) return 0;
   double tol = (tol_param>0.0 ? tol_param : MathMax(2*_Point, (AtrDeviationK>0.0 ? 0.1*GetATR_H1() : 2*_Point)));
   if(p.lastSwing==+1 && close_t1 > (p.low + tol))  return +1;
   if(p.lastSwing== -1 && close_t1 < (p.high - tol)) return -1;
   return 0;
}

// Handles for consensus filters
int ema50H = INVALID_HANDLE, ema200H = INVALID_HANDLE, rsiH = INVALID_HANDLE;

bool ReadFilters(const int shift, int &emaDir, bool &rsiOK, double &rsiValOut)
{
   emaDir = 0; rsiOK = true; rsiValOut = 50.0;
   if(Consensus == Cons_Off) return true; // ничего не делаем, но не ломаем

   // Берём последний закрытый M15-бар устойчиво (без exact=true)
   datetime tM15 = iTime(_Symbol, PERIOD_M15, 1);
   int shM15 = iBarShift(_Symbol, PERIOD_M15, tM15, false);
   if(shM15 < 1) return false;

   double ema50[2], ema200[2], rsi[1];
   if(CopyBuffer(ema50H,  0, shM15, 2, ema50)  != 2) return false;
   if(CopyBuffer(ema200H, 0, shM15, 2, ema200) != 2) return false;
   if(CopyBuffer(rsiH,    0, shM15, 1, rsi)    != 1) return false;

   double dSlope = ema50[0] - ema50[1];
   // Нормализуем наклон на ATR(M15); если EmaSlopeMin=0 — не фильтруем по наклону
   double atrM15 = 0.0;
   int atrH = iATR(_Symbol, PERIOD_M15, 14);
   double aBuf[]; ArraySetAsSeries(aBuf, true);
   if(atrH != INVALID_HANDLE && CopyBuffer(atrH, 0, shM15, 1, aBuf) == 1) atrM15 = aBuf[0];
   double slopeThresh = (EmaSlopeMin > 0.0 ? (atrM15 > 0.0 ? EmaSlopeMin * atrM15 : EmaSlopeMin * _Point) : 0.0);
   bool slopeOK = (slopeThresh == 0.0) ? true : (MathAbs(dSlope) >= slopeThresh);
   if(slopeOK)
   {
      if(ema50[0] > ema200[0]) emaDir = +1;
      else if(ema50[0] < ema200[0]) emaDir = -1;
      else emaDir = 0;
   }
   else emaDir = 0;

   rsiValOut = rsi[0];
   // rsiOK будет окончательно определён по направлению входа (+1/-1) внешне
   return true;
}

SigClass ApplyConsensus(SigClass sc, const int dir, const int emaDir, const bool rsiGood, bool &okOut)
{
   okOut = true;
   if(Consensus == Cons_Off || Consensus == Cons_PanelOnly) return sc;
   int votes = 1; // MF-ядро
   if(emaDir == dir) votes++;
   if(rsiGood) votes++;
   okOut = (votes >= 2);
   if(okOut) return sc;

   if(Consensus == Cons_GateStrong && sc == SigStrong) return SigNormal;
   if(Consensus == Cons_GateStrongNormal)
   {
      if(sc == SigStrong) return SigNormal;
      if(sc == SigNormal) return SigEarly;
   }
   if(Consensus == Cons_BlockAll) return SigNone;
   return sc;
}
// Clinch по коридору [PivotLow_H1..PivotHigh_H1]
ClinchStatus CalcClinchH1Band(const TFPivots &ph1, const int lookback, const int flipsMin,
                              const double rangeMaxATR)
{
   ClinchStatus cs; ZeroMemory(cs);
   cs.isClinch=false;
   cs.touched=false;

   int needBars = MathMax(lookback, 6);
   MqlRates r[];
   int gotRates = CopyRatesH1(needBars, r);
   if(gotRates < 6) return cs;
   int useBars = MathMin(needBars, gotRates);

   cs.atr = GetATR_H1();

   double hi = r[0].high, lo = r[0].low;
   for(int i=0;i<useBars;i++)
   {
      if(r[i].high > hi) hi = r[i].high;
      if(r[i].low  < lo) lo = r[i].low;
   }
   cs.range = hi - lo;

   double c[];
   int gotClose = CopyCloseH1(needBars, c);
   if(gotClose < 2) return cs;
   int useClose = MathMin(useBars, gotClose);

    double mid = 0.0;
    if(ph1.high>0.0 && ph1.low>0.0) mid = 0.5*(ph1.high + ph1.low);
    int flips = 0;
    int prevSign = 0;
    for(int i=useClose-1; i>=0; i--) // от старых к новым
    {
       double diff = c[i] - mid;
       int sgn = (diff > 0 ? 1 : (diff < 0 ? -1 : 0));
       if(sgn == 0) continue;
       if(prevSign == 0) prevSign = sgn;
       else if(sgn != prevSign) { flips++; prevSign = sgn; }
    }
   cs.flips = flips;

   // Fallback: если ATR индикатора ещё ноль, при достаточной истории оцениваем ATR как средний True Range (period 14)
   if(cs.atr <= 0 && useBars >= 15)
   {
      int period = 14;
      double sumTR = 0.0;
      for(int i=1; i<=period; i++)
      {
         double high = r[i].high;
         double low  = r[i].low;
         double prevClose = r[i+1].close;
         double tr = MathMax(high - low, MathMax(MathAbs(high - prevClose), MathAbs(low - prevClose)));
         sumTR += tr;
      }
      cs.atr = sumTR / 14.0;
   }

    // Коридор клинча — между последними подтверждёнными Low/High на H1
    cs.zoneTop = ph1.high;
    cs.zoneBot = ph1.low;
   if(cs.zoneTop < cs.zoneBot){ double t=cs.zoneTop; cs.zoneTop=cs.zoneBot; cs.zoneBot=t; }
   for(int i=0;i<useBars;i++)
   {
      if(r[i].low <= cs.zoneTop && r[i].high >= cs.zoneBot)
      {
         cs.touched = true;
         break;
      }
   }

   bool flipsOk = (cs.flips >= flipsMin);
   bool rangeOk = (cs.range <= rangeMaxATR * cs.atr);
   cs.isClinch = flipsOk && rangeOk;

   cs.toTime   = r[0].time;
   cs.fromTime = r[needBars-1].time;
   lastAtrH1   = cs.atr;
   return cs;
}

void DrawClinchZone(const string name, const ClinchStatus &cs, const double pivotH1, const bool isClinch)
{
    // Перерисуем как коридор High/Low, но для обратной совместимости оставим имя
    double top  = cs.zoneTop;
    double bot  = cs.zoneBot;
   if(top < bot){ double t=top; top=bot; bot=t; }

   // Границы по времени
   int idx = MathMax(1, ClinchLookbackH1-1);
   datetime tL = iTime(_Symbol, PERIOD_H1, idx);
   datetime tR = TimeCurrent();

   if(ObjectFind(0,name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, tL, top, tR, bot);
   else
   {
      ObjectSetInteger(0, name, OBJPROP_TIME,  0, tL);
      ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, top);
      ObjectSetInteger(0, name, OBJPROP_TIME,  1, tR);
      ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, bot);
   }

   ObjectSetInteger(0, name, OBJPROP_BACK,   true);
   ObjectSetInteger(0, name, OBJPROP_STYLE,  STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,  1);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
    ObjectSetInteger(0, name, OBJPROP_COLOR,  isClinch ? clrPaleTurquoise : clrAliceBlue);
}

SigClass ApplyClinch(const SigClass s, const bool clinch)
{
   if(!clinch) return s;
   if(s == SigStrong) return SigNormal;
   if(s == SigNormal) return SigEarly;
   return SigNone; // SigEarly -> блок
}

//--- Dual-pivot используется для H4/D1 при включённых флагах UseTF_H4/UseTF_D1

//--- Classic Pivot levels / Классические уровни Pivot
double pivotLevel, r1Level, r2Level, s1Level, s2Level;

//--- Objects for classic Pivot lines / Объекты для линий классических Pivot
string objPivot = "MF_ClassicPivot";
string objR1    = "MF_ClassicR1";
string objR2    = "MF_ClassicR2";
string objS1    = "MF_ClassicS1";
string objS2    = "MF_ClassicS2";

// (устаревший кэш одинарного pivot удалён)

//--- Структура для анализа тренда MasterForex-V
struct TrendAnalysis
{
   int h1, m15, m5, h4, d1;
   int strength;  // 1-3 сила тренда
   bool volumeConfirmed;
   bool sessionValid;
};

//--- Структура для анализа объема MasterForex-V
struct VolumeAnalysis
{
   bool m5VolumeConfirmed;
   bool m15VolumeConfirmed;
   bool h1VolumeConfirmed;
   int confirmedTimeframes;  // Количество подтвержденных таймфреймов (0-3)
};

//+------------------------------------------------------------------+
//| Проверка торговой сессии MasterForex-V                            |
//+------------------------------------------------------------------+
bool IsValidTradingSession()
{
   if(!EnableSessionFilter) return true;

   // Преобразуем серверное время в GMT через настраиваемый сдвиг.
   // SessionGMTOffset — смещение сервера относительно GMT (например, 2 для GMT+2)
   datetime serverTime = TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);
   int hourServer = dt.hour;
   int hourGMT = hourServer - SessionGMTOffset;
   if(hourGMT < 0)  hourGMT += 24;
   if(hourGMT >= 24) hourGMT -= 24;

   int hour = hourGMT;

   // Лондонская сессия (8:00-16:00 GMT)
   if(hour >= 8 && hour < 16) return true;

   // Нью-Йоркская сессия (13:00-21:00 GMT)
   if(hour >= 13 && hour < 21) return true;

   // Токийская сессия (0:00-8:00 GMT)
   if(hour >= 0 && hour < 8) return true;

   return false;
}

//+------------------------------------------------------------------+
//| Анализ объема на конкретном таймфрейме MasterForex-V             |
//+------------------------------------------------------------------+
bool IsVolumeConfirmedOnTimeframe(ENUM_TIMEFRAMES tf)
{
   if(!EnableVolumeFilter) return true;
   
   // Используем завершенный бар для более точного анализа
   double currentVolume = (double)iVolume(_Symbol, tf, 1);
   double avgVolume = 0;
   
   // Средний объем за последние 20 завершенных баров
   for(int i = 2; i <= 21; i++)
   {
      avgVolume += (double)iVolume(_Symbol, tf, i);
   }
   avgVolume /= 20;
   
   return currentVolume > avgVolume * MinVolumeMultiplier;
}

//+------------------------------------------------------------------+
//| Анализ объема на 3 таймфреймах MasterForex-V                     |
//+------------------------------------------------------------------+
void AnalyzeVolumeOnMasterForexTimeframes(VolumeAnalysis &analysis)
{
   ZeroMemory(analysis);
   analysis.confirmedTimeframes = 0;
   
   // Анализ объема на M5
   analysis.m5VolumeConfirmed = IsVolumeConfirmedOnTimeframe(PERIOD_M5);
   if(analysis.m5VolumeConfirmed) analysis.confirmedTimeframes++;
   
   // Анализ объема на M15
   analysis.m15VolumeConfirmed = IsVolumeConfirmedOnTimeframe(PERIOD_M15);
   if(analysis.m15VolumeConfirmed) analysis.confirmedTimeframes++;
   
   // Анализ объема на H1
   analysis.h1VolumeConfirmed = IsVolumeConfirmedOnTimeframe(PERIOD_H1);
   if(analysis.h1VolumeConfirmed) analysis.confirmedTimeframes++;
}

//+------------------------------------------------------------------+
//| Анализ силы тренда MasterForex-V                                  |
//+------------------------------------------------------------------+
int CalculateTrendStrength(int trendH1, int trendM15, int trendM5, int trendH4, int trendD1)
{
   int strength = 0;
   
   // Базовые таймфреймы
   if(trendH1 == trendM15 && trendH1 == trendM5 && trendH1 != 0) strength += 2;
   else if(trendH1 == trendM15 || trendH1 == trendM5) strength += 1;
   
   // Высшие таймфреймы
   if(trendH1 == trendH4 && trendH1 != 0) strength += 1;
   if(trendH1 == trendD1 && trendH1 != 0) strength += 1;
   
   return MathMin(strength, 3);
}

//+------------------------------------------------------------------+
//| Initialization / Инициализация                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Инициализация буферов
   SetIndexBuffer(0, BuyArrowBuffer,   INDICATOR_DATA);
   SetIndexBuffer(1, SellArrowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(2, EarlyBuyBuffer,   INDICATOR_DATA);
   SetIndexBuffer(3, EarlySellBuffer,  INDICATOR_DATA);
   SetIndexBuffer(4, ExitBuffer,       INDICATOR_DATA);
   SetIndexBuffer(5, ReverseBuffer,    INDICATOR_DATA);
   SetIndexBuffer(6, StrongBuyBuffer,  INDICATOR_DATA);
   SetIndexBuffer(7, StrongSellBuffer, INDICATOR_DATA);
   SetIndexBuffer(8, EarlyExitBuffer,  INDICATOR_DATA);

   // Настройка буферов как серийных
   ArraySetAsSeries(BuyArrowBuffer,   true);
   ArraySetAsSeries(SellArrowBuffer,  true);
   ArraySetAsSeries(EarlyBuyBuffer,   true);
   ArraySetAsSeries(EarlySellBuffer,  true);
   ArraySetAsSeries(ExitBuffer,       true);
   ArraySetAsSeries(ReverseBuffer,    true);
   ArraySetAsSeries(StrongBuyBuffer,  true);
   ArraySetAsSeries(StrongSellBuffer, true);

   // Настройка имени индикатора
   IndicatorSetString(INDICATOR_SHORTNAME, "MasterForex-V MultiTF v8.2308");

   // Настройка стрелок
   PlotIndexSetInteger(0, PLOT_ARROW, 233); // up arrow
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // down arrow
   PlotIndexSetInteger(2, PLOT_ARROW, 241); // early up
   PlotIndexSetInteger(3, PLOT_ARROW, 242); // early down
   PlotIndexSetInteger(4, PLOT_ARROW, 251); // cross exit
   PlotIndexSetInteger(5, PLOT_ARROW, 221); // reversal mark
   PlotIndexSetInteger(6, PLOT_ARROW, 225); // strong buy
   PlotIndexSetInteger(7, PLOT_ARROW, 226); // strong sell
   PlotIndexSetInteger(8, PLOT_ARROW, 252); // early exit

   // Настройка цветов
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, BuyArrowColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, SellArrowColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, EarlyBuyColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, EarlySellColor);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, ExitColor);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, ReverseColor);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, StrongSignalColor);
   PlotIndexSetInteger(7, PLOT_LINE_COLOR, StrongSignalColor);
   
   // Инициализация индикаторов волатильности
   atrH1Handle = iATR(_Symbol, PERIOD_H1, 14);
   if(atrH1Handle == INVALID_HANDLE)
      return(INIT_FAILED);
   PlotIndexSetInteger(8, PLOT_LINE_COLOR, EarlyExitColor);

   // Инициализация ZigZag per TF (built-in) с проверкой хэндлов
   zzH1  = iCustom(_Symbol, PERIOD_H1,  "ZigZag", InpDepth, InpDeviation, 3);
   if(zzH1 == INVALID_HANDLE)
      zzH1 = iCustom(_Symbol, PERIOD_H1,  "ZigZag", InpDepth, InpDeviation, 3);
   if(zzH1 == INVALID_HANDLE)
   {
      Print(__FUNCTION__, ": ZigZag H1 INVALID_HANDLE");
      return(INIT_FAILED);
   }

   zzM15 = iCustom(_Symbol, PERIOD_M15, "ZigZag", InpDepth, InpDeviation, 3);
   if(zzM15 == INVALID_HANDLE)
      zzM15 = iCustom(_Symbol, PERIOD_M15, "ZigZag", InpDepth, InpDeviation, 3);
   if(zzM15 == INVALID_HANDLE)
   {
      Print(__FUNCTION__, ": ZigZag M15 INVALID_HANDLE");
      return(INIT_FAILED);
   }

   zzM5  = iCustom(_Symbol, PERIOD_M5,  "ZigZag", InpDepth, InpDeviation, 3);
   if(zzM5 == INVALID_HANDLE)
      zzM5  = iCustom(_Symbol, PERIOD_M5,  "ZigZag", InpDepth, InpDeviation, 3);
   if(zzM5 == INVALID_HANDLE)
   {
      Print(__FUNCTION__, ": ZigZag M5 INVALID_HANDLE");
      return(INIT_FAILED);
   }
   if(UseTF_H4)
   {
      zzH4 = iCustom(_Symbol, PERIOD_H4, "ZigZag", InpDepth, InpDeviation, 3);
      if(zzH4 == INVALID_HANDLE)
         zzH4 = iCustom(_Symbol, PERIOD_H4, "ZigZag", InpDepth, InpDeviation, 3);
      if(zzH4 == INVALID_HANDLE)
         Print(__FUNCTION__, ": ZigZag H4 INVALID_HANDLE (optional)");
   }
   if(UseTF_D1)
   {
      zzD1 = iCustom(_Symbol, PERIOD_D1, "ZigZag", InpDepth, InpDeviation, 3);
      if(zzD1 == INVALID_HANDLE)
         zzD1 = iCustom(_Symbol, PERIOD_D1, "ZigZag", InpDepth, InpDeviation, 3);
      if(zzD1 == INVALID_HANDLE)
         Print(__FUNCTION__, ": ZigZag D1 INVALID_HANDLE (optional)");
   }
   pivotsLastUpdate = 0;

    // Инициализация фильтров консенсуса
    ema50H  = iMA(_Symbol, PERIOD_M15, EmaFast, 0, MODE_EMA, PRICE_CLOSE);
    ema200H = iMA(_Symbol, PERIOD_M15, EmaSlow, 0, MODE_EMA, PRICE_CLOSE);
    rsiH    = iRSI(_Symbol, PERIOD_M15, RsiPeriod, PRICE_CLOSE);

   // Лёгкий прогрев ZigZag, чтобы избежать -1 в логах (триггерим вычисление буферов)
   auto WarmupZZ = [](int h)
   {
      if(h==INVALID_HANDLE) return;
      double tmp[]; ArraySetAsSeries(tmp,true);
      CopyBuffer(h,0,1,2,tmp); CopyBuffer(h,1,1,2,tmp); CopyBuffer(h,2,1,2,tmp);
   };
   WarmupZZ(zzH1); WarmupZZ(zzM15); WarmupZZ(zzM5); if(UseTF_H4) WarmupZZ(zzH4); if(UseTF_D1) WarmupZZ(zzD1);

   // Протоколирование наличия истории (без принудительного вывода -1 по ZZ на старте)
   PrintFormat("INIT: H1=%d M15=%d M5=%d",
               Bars(_Symbol,PERIOD_H1), Bars(_Symbol,PERIOD_M15), Bars(_Symbol,PERIOD_M5));
   if(UseTF_H4 || UseTF_D1)
      PrintFormat("INIT+: H4=%d D1=%d",
                  Bars(_Symbol,PERIOD_H4), Bars(_Symbol,PERIOD_D1));

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialization / Деинициализация                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Удаление объектов при деинициализации
   ObjectDelete(0, "MFV_STATUS_TREND");
   ObjectDelete(0, "MFV_STATUS_M5");
   ObjectDelete(0, "MFV_STATUS_M15");
   ObjectDelete(0, "MFV_STATUS_H1");
   ObjectDelete(0, "MFV_STATUS_H4");
   ObjectDelete(0, "MFV_STATUS_D1");
   ObjectDelete(0, "MFV_STATUS_STRENGTH");
   ObjectDelete(0, "MFV_STATUS_VOLUME");
   ObjectDelete(0, "MFV_STATUS_SESSION");
   ObjectDelete(0, "MFV_STATUS_SIGNAL");
   ObjectDelete(0, "MFV_STATUS_CLINCH");
   
   if(!ShowClassicPivot)
   {
      ObjectDelete(0, objPivot);
      ObjectDelete(0, objR1);
      ObjectDelete(0, objR2);
      ObjectDelete(0, objS1);
      ObjectDelete(0, objS2);
    ObjectDelete(0, "MFV_WARMUP");
   }

   // Удаление линий и зон, созданных индикатором (dual‑pivot)
   ObjectDelete(0, "PivotH1_H");
   ObjectDelete(0, "PivotH1_L");
   ObjectDelete(0, "PivotM15_H");
   ObjectDelete(0, "PivotM15_L");
   ObjectDelete(0, "PivotM5_H");
   ObjectDelete(0, "PivotM5_L");
   ObjectDelete(0, "PivotH4_H");
   ObjectDelete(0, "PivotH4_L");
   ObjectDelete(0, "PivotD1_H");
   ObjectDelete(0, "PivotD1_L");
   ObjectDelete(0, "H1_CLINCH_ZONE");
   ObjectDelete(0, objPivot);
   ObjectDelete(0, objR1);
   ObjectDelete(0, objR2);
   ObjectDelete(0, objS1);
   ObjectDelete(0, objS2);

   // Дополнительные строки статуса
   ObjectDelete(0, "MFV_STATUS_PHASE");
   ObjectDelete(0, "MFV_STATUS_CONS");

   // Освобождение ресурсов индикаторов (во избежание утечек хэндлов)
   if(atrH1Handle != INVALID_HANDLE) { IndicatorRelease(atrH1Handle); atrH1Handle = INVALID_HANDLE; }
   if(ema50H      != INVALID_HANDLE) { IndicatorRelease(ema50H);      ema50H      = INVALID_HANDLE; }
   if(ema200H     != INVALID_HANDLE) { IndicatorRelease(ema200H);     ema200H     = INVALID_HANDLE; }
   if(rsiH        != INVALID_HANDLE) { IndicatorRelease(rsiH);        rsiH        = INVALID_HANDLE; }
   if(zzH1        != INVALID_HANDLE) { IndicatorRelease(zzH1);        zzH1        = INVALID_HANDLE; }
   if(zzM15       != INVALID_HANDLE) { IndicatorRelease(zzM15);       zzM15       = INVALID_HANDLE; }
   if(zzM5        != INVALID_HANDLE) { IndicatorRelease(zzM5);        zzM5        = INVALID_HANDLE; }
   if(zzH4        != INVALID_HANDLE) { IndicatorRelease(zzH4);        zzH4        = INVALID_HANDLE; }
   if(zzD1        != INVALID_HANDLE) { IndicatorRelease(zzD1);        zzD1        = INVALID_HANDLE; }
}

// (legacy single-pivot functions removed — using dual-pivot via ZigZag buffers)

//+------------------------------------------------------------------+
//| Determine trend / Определение тренда                              |
//+------------------------------------------------------------------+
int GetTrend(double price, double pivot, double tol_param=0.0)
{
   double tol = (tol_param>0.0 ? tol_param : MathMax(2*_Point, (AtrDeviationK>0.0 ? 0.1*GetATR_H1() : 2*_Point)));
   if(price > pivot + tol) return 1;
   if(price < pivot - tol) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate classic Pivot levels / Расчет классических уровней Pivot |
//+------------------------------------------------------------------+
void CalculateClassicPivotLevels(string symbol, ENUM_TIMEFRAMES tf)
{
   double high  = iHigh(symbol, tf, 1);
   double low   = iLow(symbol, tf, 1);
   double close = iClose(symbol, tf, 1);

   pivotLevel = (high + low + close) / 3.0;
   r1Level    = 2 * pivotLevel - low;
   s1Level    = 2 * pivotLevel - high;
   r2Level    = pivotLevel + (high - low);
   s2Level    = pivotLevel - (high - low);
}

//+------------------------------------------------------------------+
//| Draw or update horizontal line / Отрисовка или обновление линии  |
//+------------------------------------------------------------------+
void DrawOrUpdateLine(string name, double price, color clr, int width=1, ENUM_LINE_STYLE style=STYLE_DOT)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   else
   {
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }
}

// Отрисовка стрелки, привязанной к времени базового ТФ (для единых сигналов на всех графиках)
void DrawAnchoredArrow(double &buffer[], const double priceAtCurrentTF, const color col)
{
   // Стрелки пишутся в буфер по индексу [shift]; определим shift через якорный ТФ (обычно M5)
   int shiftCurrent = 1; // рисуем на закрытом баре текущего ТФ
   if(SignalAnchor == Anchor_Current)
   {
      buffer[shiftCurrent] = priceAtCurrentTF;
      return;
   }
   // Anchor_M5: берём время закрытия бара M5[1], ищем соответствующий бар на текущем ТФ
   datetime tAnchor = iTime(_Symbol, PERIOD_M5, 1);
   if(tAnchor == 0)
   {
      buffer[shiftCurrent] = priceAtCurrentTF; // fallback
      return;
   }
   int sh = iBarShift(_Symbol, (ENUM_TIMEFRAMES)Period(), tAnchor, false);
   if(sh < 1) sh = 1;
   buffer[sh] = priceAtCurrentTF;
}
// Отрисовка статуса «разогрева» истории/буферов
void DrawWarmupStatus(const bool okH1, const int haveH1, const int needH1,
                      const bool okM15, const int haveM15, const int needM15,
                      const bool okM5, const int haveM5, const int needM5)
{
   const string nm = "MFV_WARMUP";
   if(okH1 && okM15 && okM5)
   {
      ObjectDelete(0, nm);
      return;
   }

   string txt = StringFormat("Warm-up | H1 %d/%d  M15 %d/%d  M5 %d/%d",
                             haveH1, needH1, haveM15, needM15, haveM5, needM5);

   if(ObjectFind(0, nm) < 0)
   {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER, 0);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, 8);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(0, nm, OBJPROP_BACK, false);
      ObjectSetInteger(0, nm, OBJPROP_COLOR, clrSilver);
   }
   ObjectSetString(0, nm, OBJPROP_TEXT, txt);
}

// Полная очистка всех буферов стрелок
void ClearAllArrowBuffers()
{
   ArrayInitialize(BuyArrowBuffer,   EMPTY_VALUE);
   ArrayInitialize(SellArrowBuffer,  EMPTY_VALUE);
   ArrayInitialize(EarlyBuyBuffer,   EMPTY_VALUE);
   ArrayInitialize(EarlySellBuffer,  EMPTY_VALUE);
   ArrayInitialize(ExitBuffer,       EMPTY_VALUE);
   ArrayInitialize(ReverseBuffer,    EMPTY_VALUE);
   ArrayInitialize(StrongBuyBuffer,  EMPTY_VALUE);
   ArrayInitialize(StrongSellBuffer, EMPTY_VALUE);
   ArrayInitialize(EarlyExitBuffer,  EMPTY_VALUE);
}
//+------------------------------------------------------------------+
//| Draw single status row / Отрисовка строки статуса                |
//+------------------------------------------------------------------+
void DrawRowLabel(string name, string text, int y)
{
   if(!ShowStatusInfo) return;
   
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
     
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Main calculation / Основной расчет                                |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   // Проверка входных данных
   if(rates_total < 2) return(0);
   
   ArraySetAsSeries(price, true);
    
    // «Тёплый старт»: динамически оцениваем необходимый минимум истории и готовность ZigZag
   const int needM5  = MathMax(600,  InpDepth*20 + RetestWindowM5  + 200);
   const int needM15 = MathMax(400,  InpDepth*10 + RetestWindowM15 + 200);
   const int needH1  = MathMax(200,  H1ClosesNeeded*10 + 200);
   const int needH4  = MathMax(150,  InpDepth*6  + 120);
   const int needD1  = MathMax(120,  InpDepth*4  + 90);

    bool ok5  = EnsureHistory(_Symbol, PERIOD_M5,  needM5);
    bool ok15 = EnsureHistory(_Symbol, PERIOD_M15, needM15);
    bool okH1 = EnsureHistory(_Symbol, PERIOD_H1,  needH1);
    bool okH4 = (!UseTF_H4) ? true : EnsureHistory(_Symbol, PERIOD_H4, needH4);
    bool okD1 = (!UseTF_D1) ? true : EnsureHistory(_Symbol, PERIOD_D1, needD1);

    bool zzReady5  = EnsureZigZagReady(zzM5);
    bool zzReady15 = EnsureZigZagReady(zzM15);
    bool zzReadyH1 = EnsureZigZagReady(zzH1);
    bool zzReadyH4 = (!UseTF_H4) ? true : EnsureZigZagReady(zzH4);
    bool zzReadyD1 = (!UseTF_D1) ? true : EnsureZigZagReady(zzD1);

    if(!(ok5 && ok15 && okH1 && okH4 && okD1 && zzReady5 && zzReady15 && zzReadyH1 && zzReadyH4 && zzReadyD1))
    {
       DrawWarmupStatus(okH1, Bars(_Symbol,PERIOD_H1),  needH1,
                        ok15, Bars(_Symbol,PERIOD_M15), needM15,
                        ok5,  Bars(_Symbol,PERIOD_M5),  needM5);
       // Не блокируем расчёты полностью: ниже применим «грациозную деградацию».
    }
   
   // Изменение размера буферов
   ArrayResize(BuyArrowBuffer,   rates_total);
   ArrayResize(SellArrowBuffer,  rates_total);
   ArrayResize(EarlyBuyBuffer,   rates_total);
   ArrayResize(EarlySellBuffer,  rates_total);
   ArrayResize(ExitBuffer,       rates_total);
   ArrayResize(ReverseBuffer,    rates_total);
   ArrayResize(StrongBuyBuffer,  rates_total);
   ArrayResize(StrongSellBuffer, rates_total);

   // Жёстко очищаем буферы на каждом тике перед рисованием, чтобы не оставались артефакты
   ClearAllArrowBuffers();

   // Инициализация буферов для текущего бара
   BuyArrowBuffer[0]   = EMPTY_VALUE;
   SellArrowBuffer[0]  = EMPTY_VALUE;
   EarlyBuyBuffer[0]   = EMPTY_VALUE;
   EarlySellBuffer[0]  = EMPTY_VALUE;
   ExitBuffer[0]       = EMPTY_VALUE;
   ReverseBuffer[0]    = EMPTY_VALUE;
   StrongBuyBuffer[0]  = EMPTY_VALUE;
   StrongSellBuffer[0] = EMPTY_VALUE;
   EarlyExitBuffer[0]  = EMPTY_VALUE;

   // Ограничение глубины отрисовки стрелок, чтобы убрать «рандомные» хвосты на старой истории
   if(!ShowHistorySignals)
   {
      // Исторические стрелки отключены — рисуем только на баре [1], остальное очищено выше
   }
   else
   {
      // Лимит по истории — всё, что дальше SignalsLookbackBars, оставляем пустым
      int maxKeep = MathMax(50, MathMin(SignalsLookbackBars, rates_total-1));
      for(int i=maxKeep+1; i<rates_total; ++i)
      {
         BuyArrowBuffer[i]   = EMPTY_VALUE;
         SellArrowBuffer[i]  = EMPTY_VALUE;
         EarlyBuyBuffer[i]   = EMPTY_VALUE;
         EarlySellBuffer[i]  = EMPTY_VALUE;
         ExitBuffer[i]       = EMPTY_VALUE;
         ReverseBuffer[i]    = EMPTY_VALUE;
         StrongBuyBuffer[i]  = EMPTY_VALUE;
         StrongSellBuffer[i] = EMPTY_VALUE;
         EarlyExitBuffer[i]  = EMPTY_VALUE;
      }
   }

   // Работаем ТОЛЬКО с закрытыми барами для логики
   double price_prev = price[1];

   // Статические переменные для отслеживания состояния
   static int    lastSignal   = 0;   // 1 buy, -1 sell, 0 none
   static double lastPivot    = 0.0; // legacy for H1
   static int    lastTrendH1  = 0;
   static int    lastTrendM15 = 0;
   // Пивоты, зафиксированные на баре входа (для разных режимов выхода)
   static double lastPivotH1AtEntry  = 0.0;
   static double lastPivotM15AtEntry = 0.0;
   static double lastPivotM5AtEntry  = 0.0;
   static double lastExitPivot       = 0.0; // выбранный уровень выхода для режимов Exit_H1/EntryTF/Nearest
   static bool   earlyExitShown      = false; // чтобы ранний выход рисовался один раз на позицию
   static int    lastArrowBarBuy     = -10000;
   static int    lastArrowBarSell    = -10000;
   static int    lastArrowBarEarlyB  = -10000;
   static int    lastArrowBarEarlyS  = -10000;

   // Обновление dual‑pivot значений
   UpdatePivotsCache();
   
   // Грациозная деградация: если какой‑то TF ещё не готов, не блокируем весь расчёт —
   // просто пропустим соответствующие проверки/условия далее.

   // Определение трендов
   double cH1  = iClose(_Symbol, PERIOD_H1, 1);
   double cM15 = iClose(_Symbol, PERIOD_M15, 1);
   double cM5  = iClose(_Symbol, PERIOD_M5, 1);
   int trendH1  = DetermineTrend(pivH1,  cH1);
   int trendM15 = DetermineTrend(pivM15, cM15);
   int trendM5  = DetermineTrend(pivM5,  cM5);
   int trendH4  = 0, trendD1=0;
   if(UseTF_H4){ double cH4 = iClose(_Symbol, PERIOD_H4, 1); trendH4 = DetermineTrend(pivH4, cH4); }
   if(UseTF_D1){ double cD1 = iClose(_Symbol, PERIOD_D1, 1); trendD1 = DetermineTrend(pivD1, cD1); }

   // Анализ MasterForex-V
   TrendAnalysis analysis;
   analysis.h1 = trendH1;
   analysis.m15 = trendM15;
   analysis.m5 = trendM5;
   analysis.h4 = trendH4;
   analysis.d1 = trendD1;
   analysis.strength = CalculateTrendStrength(trendH1, trendM15, trendM5, trendH4, trendD1);
   analysis.sessionValid = IsValidTradingSession();

   // Анализ объема на 3 таймфреймах MasterForex-V
   VolumeAnalysis volumeAnalysis;
   AnalyzeVolumeOnMasterForexTimeframes(volumeAnalysis);
   analysis.volumeConfirmed = (volumeAnalysis.confirmedTimeframes >= 2); // Минимум 2 из 3

   // Формирование строк статуса
   string strH1  = trendH1 > 0  ? "↑" : (trendH1 < 0  ? "↓" : "-");
   string strM15 = trendM15 > 0 ? "↑" : (trendM15 < 0 ? "↓" : "-");
   string strM5  = trendM5 > 0  ? "↑" : (trendM5 < 0  ? "↓" : "-");
   string trendFmt = UseRussian ? "Тренд H1: %s  M15: %s  M5: %s"
                                : "Trend H1: %s  M15: %s  M5: %s";
   string trendStatus = StringFormat(trendFmt, strH1, strM15, strM5);

   string levelM5  = (pivM5.high>0.0 && pivM5.low>0.0)
      ? StringFormat("Pivot M5: H=%s | L=%s",  DoubleToString(pivM5.high,  _Digits), DoubleToString(pivM5.low,  _Digits))
      : StringFormat("Pivot M5: H=%s | L=%s",  "–", "–");
   string levelM15 = (pivM15.high>0.0 && pivM15.low>0.0)
      ? StringFormat("Pivot M15: H=%s | L=%s", DoubleToString(pivM15.high, _Digits), DoubleToString(pivM15.low, _Digits))
      : StringFormat("Pivot M15: H=%s | L=%s",  "–", "–");
   string levelH1  = (pivH1.high>0.0 && pivH1.low>0.0)
      ? StringFormat("Pivot H1: H=%s | L=%s",  DoubleToString(pivH1.high,  _Digits), DoubleToString(pivH1.low,  _Digits))
      : StringFormat("Pivot H1: H=%s | L=%s",  "–", "–");
   string levelH4  = (UseTF_H4 ? ((pivH4.high>0.0 && pivH4.low>0.0)
      ? StringFormat("Pivot H4: H=%s | L=%s",  DoubleToString(pivH4.high,  _Digits), DoubleToString(pivH4.low,  _Digits))
      : StringFormat("Pivot H4: H=%s | L=%s",  "–", "–")) : "");
   string levelD1  = (UseTF_D1 ? ((pivD1.high>0.0 && pivD1.low>0.0)
      ? StringFormat("Pivot D1: H=%s | L=%s",  DoubleToString(pivD1.high,  _Digits), DoubleToString(pivD1.low,  _Digits))
      : StringFormat("Pivot D1: H=%s | L=%s",  "–", "–")) : "");

   // Дополнительная информация MasterForex-V
   string strengthText = UseRussian ? 
      StringFormat("Сила тренда: %d/3", analysis.strength) :
      StringFormat("Trend strength: %d/3", analysis.strength);
   
   string volumeText = UseRussian ?
      StringFormat("Объем M5:%s M15:%s H1:%s (%d/3)", 
         volumeAnalysis.m5VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.m15VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.h1VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.confirmedTimeframes) :
      StringFormat("Volume M5:%s M15:%s H1:%s (%d/3)",
         volumeAnalysis.m5VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.m15VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.h1VolumeConfirmed ? "✓" : "✗",
         volumeAnalysis.confirmedTimeframes);
   
   string sessionText = UseRussian ?
      StringFormat("Сессия: %s", analysis.sessionValid ? "✓" : "✗") :
      StringFormat("Session: %s", analysis.sessionValid ? "✓" : "✗");

   // Отрисовка статуса
   DrawRowLabel("MFV_STATUS_TREND", trendStatus, 10);
   DrawRowLabel("MFV_STATUS_M5",    levelM5,     30);
   DrawRowLabel("MFV_STATUS_M15",   levelM15,    50);
   DrawRowLabel("MFV_STATUS_H1",    levelH1,     70);
   if(UseTF_H4) DrawRowLabel("MFV_STATUS_H4",    levelH4,     90);  else ObjectDelete(0, "MFV_STATUS_H4");
   if(UseTF_D1) DrawRowLabel("MFV_STATUS_D1",    levelD1,     110); else ObjectDelete(0, "MFV_STATUS_D1");
   DrawRowLabel("MFV_STATUS_STRENGTH", strengthText, 130);
   DrawRowLabel("MFV_STATUS_VOLUME", volumeText, 150);
   DrawRowLabel("MFV_STATUS_SESSION", sessionText, 170);

   // Логика сигналов MasterForex-V
   bool firedStrongBuy=false, firedStrongSell=false, firedBuy=false, firedSell=false;
   bool firedEarlyBuy=false, firedEarlySell=false, firedHardExit=false, firedEarlyExit=false, firedReversal=false;
   bool canTrade = analysis.sessionValid && analysis.volumeConfirmed && analysis.strength >= MinTrendStrength;
   bool earlyCanTrade = analysis.sessionValid && analysis.volumeConfirmed && analysis.strength >= MinEarlyTrendStrength;

   // Детектор фазы рынка (флет): даунгрейд классов до Early
   bool isFlat = IsFlatPhase_M15();

   // Расчет CLINCH по коридору [PivotLow_H1..PivotHigh_H1] (не чаще 1 H1-бара)
   static ClinchStatus clinchState;
   EnsureH1History(MathMax(ClinchLookbackH1 + 20, 100));
   datetime lastH1Bar = iTime(_Symbol, PERIOD_H1, 0);
   if(UseClinchFilter && (lastClinchCalcOnH1 == 0 || lastH1Bar == 0 || lastH1Bar != lastClinchCalcOnH1))
   {
      clinchState = CalcClinchH1Band(pivH1, ClinchLookbackH1, ClinchFlipsMin,
                                     ClinchRangeMaxATR);
      lastClinchCalcOnH1 = (lastH1Bar == 0 ? TimeCurrent() : lastH1Bar);
      // Отрисовываем зону, если отключен фильтр показа или если зона была потрогана ценой
      if(!ShowClinchZoneOnlyIfTouched || clinchState.touched)
      {
         // Не рисуем клинч, если диапазон за Lookback слишком большой относительно ATR(H1)
         if(clinchState.atr > 0 && clinchState.range <= ClinchRangeMaxATR * clinchState.atr)
            DrawClinchZone("H1_CLINCH_ZONE", clinchState, 0.0, clinchState.isClinch);
         else
            ObjectDelete(0, "H1_CLINCH_ZONE");
      }
      else
         ObjectDelete(0, "H1_CLINCH_ZONE");
   }

   // Для Long: дополнительно требуем, чтобы M5 пробил свой PivotHigh_M5 и был pullback (обеспечивается фильтрами подтверждения/импульса)
   if(trendH1 == 1 && trendM15 == 1 && trendM5 == 1 && (cM5 > pivM5.high) && canTrade)
   {
      SigClass sc = (analysis.strength >= 3) ? SigStrong : SigNormal;
      sc = ApplyClinch(sc, UseClinchFilter ? clinchState.isClinch : false);

      // Подтверждение пробоя H1 pivot по правилам
      if(BreakoutConfirm != Confirm_Off)
      {
         int dir = +1;
         bool needConfirm =
            (BreakoutConfirm==Confirm_All) ||
            (BreakoutConfirm==Confirm_StrongOnly      && sc==SigStrong) ||
            (BreakoutConfirm==Confirm_StrongAndNormal && (sc==SigStrong || sc==SigNormal));
         if(needConfirm && !clinchState.isClinch)
         {
             bool okH1  = CheckH1Breakout(pivH1.high, pivH1.low, dir);
          datetime h1_open = iTime(_Symbol, PERIOD_H1, 1);
          datetime fromTime = h1_open + PeriodSeconds(PERIOD_H1);
             bool okRetM15 = CheckRetestBounce_M15(pivH1.high, dir, fromTime);
             bool okRetM5  = (RetestAllowM5 ? CheckRetestBounce_M5(pivH1.high, dir, fromTime) : false);
            bool okRet = (okRetM15 || okRetM5);
            bool okBoth = okH1 && okRet;
            if(sc==SigStrong && !okBoth)        sc = SigNormal;
            else if(sc==SigNormal && !okH1)     sc = SigEarly;
         }
      }

      // Импульс-откат на M15: апгрейд Early→Normal при здоровом импульсе, даунгрейд при слишком глубоком откате
      if(UseImpulseFilter)
      {
         double ratio=0.0;
         bool okImpulse = CheckImpulsePullback_M15(+1, ratio);
         if(sc==SigEarly && okImpulse) sc = SigNormal; // апгрейд раннего за счёт здорового импульса
         if(!okImpulse && sc==SigNormal) sc = SigEarly; // глубокий откат — понижаем
      }
      if(isFlat && sc!=SigNone) sc = SigEarly;
      // Consensus voting (after Clinch, before rendering)
      int emaDir=0; bool rsiOK=true; double rsiVal=50.0; bool consOK=true;
      if(ReadFilters(1, emaDir, rsiOK, rsiVal))
      {
         // для покупок: rsi ок, если не перекуплено; для продаж: не перепродано
         int localDir = +1;
         rsiOK = (rsiVal <= (RsiOB - RsiHyst));
         sc = ApplyConsensus(sc, localDir, emaDir, rsiOK, consOK);
      }

      if(sc == SigStrong && ShowStrongSignals && ( (rates_total-1) - lastArrowBarBuy >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(StrongBuyBuffer, price[1] - ArrowOffset * _Point, StrongSignalColor);
         firedStrongBuy = true;
         lastArrowBarBuy = rates_total-1;
      }
      else if(sc == SigNormal && ShowNormalSignals && ( (rates_total-1) - lastArrowBarBuy >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(BuyArrowBuffer, price[1] - ArrowOffset * _Point, BuyArrowColor);
         firedBuy = true;
         lastArrowBarBuy = rates_total-1;
      }
      // если понижен до SigEarly — отрисуем ранний вход
      else if(sc == SigEarly && ShowEarlySignals && ( (rates_total-1) - lastArrowBarEarlyB >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(EarlyBuyBuffer, price[1] - ArrowOffset * _Point, EarlyBuyColor);
         firedEarlyBuy = true;
         lastArrowBarEarlyB = rates_total-1;
      }
       lastSignal = 1;
       earlyExitShown = false; // новая позиция — сбрасываем флаг раннего выхода
       // Зафиксировать уровни на момент входа
       lastPivotH1AtEntry  = pivH1.low;   // Long: выходим по пробою PivotLow_H1
       lastPivotM15AtEntry = pivM15.low;  // Soft: PivotLow_M15
       lastPivotM5AtEntry  = pivM5.low;
       // Выбрать целевой уровень выхода в зависимости от режима
       if(ExitLogic == Exit_H1)
       {
          lastExitPivot = lastPivotH1AtEntry;
       }
       else if(ExitLogic == Exit_EntryTF)
       {
          lastExitPivot = lastPivotM5AtEntry;
       }
       else if(ExitLogic == Exit_Nearest)
       {
          // Выбор ближайшего пивота среди M5/M15/H1 с учётом минимальной дистанции в ATR(M15)
          int atrHandleN = iATR(_Symbol, PERIOD_M15, 14);
          double aBuf[]; ArraySetAsSeries(aBuf, true);
          double atrM15 = 0.0; if(atrHandleN!=INVALID_HANDLE && CopyBuffer(atrHandleN,0,1,1,aBuf)==1) atrM15=aBuf[0];
          double minAllowed = ExitNearestAtrK * atrM15;
          double candidates[3]; candidates[0]=lastPivotM5AtEntry; candidates[1]=lastPivotM15AtEntry; candidates[2]=lastPivotH1AtEntry;
          // дистанция считаем от цены входа (закрытая цена бара входа)
          double entryPrice = price[1];
          double best = lastPivotH1AtEntry; double bestDist = 1e100;
          for(int ci=0; ci<3; ++ci)
          {
             double pv = candidates[ci];
             double d  = MathAbs(entryPrice - pv);
             if(minAllowed>0.0 && d < minAllowed) continue; // слишком близко
             if(d < bestDist){ bestDist=d; best=pv; }
          }
          lastExitPivot = best;
       }
       // legacy совместимость
       lastPivot = lastPivotH1AtEntry;
   }
   else if(trendH1 == -1 && trendM15 == -1 && trendM5 == -1 && (cM5 < pivM5.low) && canTrade)
   {
      SigClass sc = (analysis.strength >= 3) ? SigStrong : SigNormal;
      sc = ApplyClinch(sc, UseClinchFilter ? clinchState.isClinch : false);

      // Подтверждение пробоя H1 pivot по правилам
      if(BreakoutConfirm != Confirm_Off)
      {
         int dir = -1;
         bool needConfirm =
            (BreakoutConfirm==Confirm_All) ||
            (BreakoutConfirm==Confirm_StrongOnly      && sc==SigStrong) ||
            (BreakoutConfirm==Confirm_StrongAndNormal && (sc==SigStrong || sc==SigNormal));
         if(needConfirm && !clinchState.isClinch)
         {
            bool okH1  = CheckH1Breakout(pivH1.high, pivH1.low, dir);
          datetime h1_open2 = iTime(_Symbol, PERIOD_H1, 1);
          datetime fromTime2 = h1_open2 + PeriodSeconds(PERIOD_H1);
          bool okRetM15b = CheckRetestBounce_M15(pivH1.low, dir, fromTime2);
          bool okRetM5b  = (RetestAllowM5 ? CheckRetestBounce_M5(pivH1.low, dir, fromTime2) : false);
          bool okRet = (okRetM15b || okRetM5b);
            bool okBoth = okH1 && okRet;
            if(sc==SigStrong && !okBoth)        sc = SigNormal;
            else if(sc==SigNormal && !okH1)     sc = SigEarly;
         }
      }

      if(UseImpulseFilter)
      {
         double ratio=0.0;
         bool okImpulse = CheckImpulsePullback_M15(-1, ratio);
         if(sc==SigEarly && okImpulse) sc = SigNormal;
         if(!okImpulse && sc==SigNormal) sc = SigEarly;
      }
      if(isFlat && sc!=SigNone) sc = SigEarly;
      // Consensus voting (after Clinch, before rendering)
      int emaDir2=0; bool rsiOK2=true; double rsiVal2=50.0; bool consOK2=true;
      if(ReadFilters(1, emaDir2, rsiOK2, rsiVal2))
      {
         int localDir2 = -1;
         rsiOK2 = (rsiVal2 >= (RsiOS + RsiHyst));
         sc = ApplyConsensus(sc, localDir2, emaDir2, rsiOK2, consOK2);
      }

       if(sc == SigStrong && ShowStrongSignals && ( (rates_total-1) - lastArrowBarSell >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(StrongSellBuffer, price[1] + ArrowOffset * _Point, StrongSignalColor);
         firedStrongSell = true;
         lastArrowBarSell = rates_total-1;
      }
      else if(sc == SigNormal && ShowNormalSignals && ( (rates_total-1) - lastArrowBarSell >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(SellArrowBuffer, price[1] + ArrowOffset * _Point, SellArrowColor);
         firedSell = true;
         lastArrowBarSell = rates_total-1;
      }
      else if(sc == SigEarly && ShowEarlySignals && ( (rates_total-1) - lastArrowBarEarlyS >= MinBarsBetweenArrows) )
      {
         DrawAnchoredArrow(EarlySellBuffer, price[1] + ArrowOffset * _Point, EarlySellColor);
         firedEarlySell = true;
         lastArrowBarEarlyS = rates_total-1;
      }
       lastSignal = -1;
       earlyExitShown = false; // новая позиция — сбрасываем флаг раннего выхода
       lastPivotH1AtEntry  = pivH1.high;  // Short: выходим по пробою PivotHigh_H1
       lastPivotM15AtEntry = pivM15.high; // Soft: PivotHigh_M15
        lastPivotM5AtEntry  = pivM5.high;
       if(ExitLogic == Exit_H1)
       {
          lastExitPivot = lastPivotH1AtEntry;
       }
       else if(ExitLogic == Exit_EntryTF)
       {
          lastExitPivot = lastPivotM5AtEntry;
       }
       else if(ExitLogic == Exit_Nearest)
       {
          int atrHandleN2 = iATR(_Symbol, PERIOD_M15, 14);
          double aBuf2[]; ArraySetAsSeries(aBuf2, true);
          double atrM152 = 0.0; if(atrHandleN2!=INVALID_HANDLE && CopyBuffer(atrHandleN2,0,1,1,aBuf2)==1) atrM152=aBuf2[0];
          double minAllowed2 = ExitNearestAtrK * atrM152;
          double candidates2[3]; candidates2[0]=lastPivotM5AtEntry; candidates2[1]=lastPivotM15AtEntry; candidates2[2]=lastPivotH1AtEntry;
          double entryPrice2 = price[1];
          double best2 = lastPivotH1AtEntry; double bestDist2 = 1e100;
          for(int cj=0; cj<3; ++cj)
          {
             double pv = candidates2[cj];
             double d  = MathAbs(entryPrice2 - pv);
             if(minAllowed2>0.0 && d < minAllowed2) continue;
             if(d < bestDist2){ bestDist2=d; best2=pv; }
          }
          lastExitPivot = best2;
       }
       lastPivot = lastPivotH1AtEntry;
   }
   else if(trendH1 == 1 && trendM5 == 1 && trendM15 != 1 && earlyCanTrade && ShowEarlySignals && ( (rates_total-1) - lastArrowBarEarlyB >= MinBarsBetweenArrows) )
   {
      DrawAnchoredArrow(EarlyBuyBuffer, price[1] - ArrowOffset * _Point, EarlyBuyColor);
      firedEarlyBuy = true;
      lastArrowBarEarlyB = rates_total-1;
   }
   else if(trendH1 == -1 && trendM5 == -1 && trendM15 != -1 && earlyCanTrade && ShowEarlySignals && ( (rates_total-1) - lastArrowBarEarlyS >= MinBarsBetweenArrows) )
   {
      DrawAnchoredArrow(EarlySellBuffer, price[1] + ArrowOffset * _Point, EarlySellColor);
      firedEarlySell = true;
      lastArrowBarEarlyS = rates_total-1;
   }

   // Логика выхода (переключаемая)
   if(ExitLogic == Exit_SoftHard)
   {
       // Soft: по M15 pivot (не сбрасываем lastSignal) — отрисовываем один раз на позицию
       if(ShowExitSignals && !earlyExitShown && lastSignal == 1 && lastPivotM15AtEntry>0.0 && price_prev < lastPivotM15AtEntry)
      {
         EarlyExitBuffer[1] = price[1];
         firedEarlyExit = true;
          earlyExitShown = true;
      }
       else if(ShowExitSignals && !earlyExitShown && lastSignal == -1 && lastPivotM15AtEntry>0.0 && price_prev > lastPivotM15AtEntry)
      {
         EarlyExitBuffer[1] = price[1];
         firedEarlyExit = true;
          earlyExitShown = true;
      }
      // Hard: по H1 pivot (сброс состояния)
       if(ShowExitSignals && lastSignal == 1 && lastPivotH1AtEntry>0.0 && price_prev < lastPivotH1AtEntry)
      {
          ExitBuffer[1] = price[1];
          lastSignal = 0;
          earlyExitShown = false;
         firedHardExit = true;
      }
       else if(ShowExitSignals && lastSignal == -1 && lastPivotH1AtEntry>0.0 && price_prev > lastPivotH1AtEntry)
      {
          ExitBuffer[1] = price[1];
          lastSignal = 0;
          earlyExitShown = false;
         firedHardExit = true;
      }
   }
   else
   {
      // Один целевой уровень в зависимости от режима (H1, EntryTF, Nearest)
       if(ShowExitSignals && lastSignal == 1 && lastExitPivot>0.0 && price_prev < lastExitPivot)
      {
         ExitBuffer[1] = price[1];
          lastSignal = 0;
          earlyExitShown = false;
         firedHardExit = true;
      }
      else if(ShowExitSignals && lastSignal == -1 && lastExitPivot>0.0 && price_prev > lastExitPivot)
      {
         ExitBuffer[1] = price[1];
          lastSignal = 0;
          earlyExitShown = false;
         firedHardExit = true;
      }
   }

   // Ранний выход по смене тренда M15 против позиции (кроме Exit_SoftHard, где soft = пересечение M15 pivot)
     if(ExitLogic != Exit_SoftHard && ShowExitSignals)
   {
       if(!earlyExitShown && lastSignal == 1 && trendM15 < 0)
      {
         EarlyExitBuffer[1] = price[1];
         firedEarlyExit = true;
          earlyExitShown = true;
      }
       else if(!earlyExitShown && lastSignal == -1 && trendM15 > 0)
      {
         EarlyExitBuffer[1] = price[1];
         firedEarlyExit = true;
          earlyExitShown = true;
      }
   }

   // Логика разворота (привязанная к текущему ТФ, рисуем только на закрытом баре)
   if(ShowReversalSignals && trendH1 == trendM15 && trendH1 != 0 && trendH1 != lastTrendH1 && lastTrendH1 != 0)
   {
      ReverseBuffer[1] = price[1];
      firedReversal = true;
   }
   lastTrendH1  = trendH1;
   lastTrendM15 = trendM15;

   // Текущий сигнал (строка статуса)
   string signalText = "-";
   if(firedStrongBuy)  signalText = (UseRussian ? "Сигнал: Сильная покупка" : "Signal: Strong BUY");
   else if(firedStrongSell) signalText = (UseRussian ? "Сигнал: Сильная продажа" : "Signal: Strong SELL");
   else if(firedBuy)    signalText = (UseRussian ? "Сигнал: Покупка" : "Signal: BUY");
   else if(firedSell)   signalText = (UseRussian ? "Сигнал: Продажа" : "Signal: SELL");
   else if(firedEarlyBuy)  signalText = (UseRussian ? "Сигнал: Ранний BUY" : "Signal: Early BUY");
   else if(firedEarlySell) signalText = (UseRussian ? "Сигнал: Ранний SELL" : "Signal: Early SELL");
   else if(firedEarlyExit) signalText = (UseRussian ? "Сигнал: Ранний выход" : "Signal: Early EXIT");
   else if(firedHardExit)  signalText = (UseRussian ? "Сигнал: Выход (H1 Pivot)" : "Signal: HARD EXIT");
   else if(firedReversal)  signalText = (UseRussian ? "Сигнал: Разворот" : "Signal: Reversal");
   DrawRowLabel("MFV_STATUS_SIGNAL", signalText, 190);

   // Статус CLINCH (коридор H1 High/Low)
   double rangeAtr = (clinchState.atr > 0.0 ? (clinchState.range / clinchState.atr) : 0.0);
   string clinchOn = clinchState.isClinch ? (UseRussian ? "✓" : "✓") : (UseRussian ? "✗" : "✗");
   string clinchText = UseRussian ?
       StringFormat("Схватка: %s, flips=%d, range=%.2f ATR, band=H/L", clinchOn, clinchState.flips, rangeAtr) :
       StringFormat("Clinch: %s, flips=%d, range=%.2f ATR, band=H/L", clinchOn, clinchState.flips, rangeAtr);
   DrawRowLabel("MFV_STATUS_CLINCH", clinchText, 210);

   // Фаза рынка (Flat/Trend) — строкой под Clinch
   string phaseText = UseRussian ?
      StringFormat("Фаза: %s", isFlat ? "Флет" : "Тренд") :
      StringFormat("Phase: %s", isFlat ? "Flat" : "Trend");
   DrawRowLabel("MFV_STATUS_PHASE", phaseText, 230);

   // Панель консенсуса, если включено
   if(Consensus != Cons_Off)
   {
      int emaD=0; bool rOK=true; double rV=50.0; bool kons=true; string sOK="-";
      int dirPanel = 0; bool rsiGoodPanel = true;
      if(ReadFilters(1, emaD, rOK, rV))
      {
         // Сформируем статус 2/3 без изменения сигналов
         int votes=1; if(emaD!=0) votes++; // MF-ядро + EMA (направление учтём ниже)
         // Направление берём по H1-тренду, если он определён
         dirPanel = (trendH1>0?+1:(trendH1<0?-1:0));
         if(dirPanel!=0){ if(emaD==dirPanel){} else votes--; }
         rsiGoodPanel = (dirPanel>0 ? (rV <= (RsiOB - RsiHyst)) : (dirPanel<0 ? (rV >= (RsiOS + RsiHyst)) : true));
         if(rsiGoodPanel) votes++;
         bool ok2 = (votes>=2);
         sOK = ok2? (UseRussian?"2/3 ✓":"2/3 ✓") : (UseRussian?"2/3 ✗":"2/3 ✗");
      }
      string consText = UseRussian ?
         StringFormat("Консенсус: %s  | EMA:%s | RSI:%s", sOK, (emaD>0?"↑":(emaD<0?"↓":"–")), ( (trendH1==0)?"–":( (dirPanel>0 ? (rV <= (RsiOB - RsiHyst)) : (rV >= (RsiOS + RsiHyst)) )?"✓":"✗") )) :
         StringFormat("Consensus: %s  | EMA:%s | RSI:%s", sOK, (emaD>0?"↑":(emaD<0?"↓":"–")), ( (trendH1==0)?"–":( (dirPanel>0 ? (rV <= (RsiOB - RsiHyst)) : (rV >= (RsiOS + RsiHyst)) )?"✓":"✗") ));
      DrawRowLabel("MFV_STATUS_CONS", consText, 250);
   }

   // Отрисовка dual‑pivot линий (названия согласно ТЗ)
   if(ShowPivotHighLow)
   {
      if(pivH1.high>0.0)  DrawOrUpdateLine("PivotH1_H",  pivH1.high,  PivotHighColor, 2, STYLE_DASHDOTDOT);
      if(pivH1.low>0.0)   DrawOrUpdateLine("PivotH1_L",  pivH1.low,   PivotLowColor,  2, STYLE_DASHDOTDOT);
      if(pivM15.high>0.0) DrawOrUpdateLine("PivotM15_H", pivM15.high, PivotHighColor, 1, STYLE_DASHDOTDOT);
      if(pivM15.low>0.0)  DrawOrUpdateLine("PivotM15_L", pivM15.low,  PivotLowColor,  1, STYLE_DASHDOTDOT);
      if(pivM5.high>0.0)  DrawOrUpdateLine("PivotM5_H",  pivM5.high,  PivotHighColor, 1, STYLE_DASHDOTDOT);
      if(pivM5.low>0.0)   DrawOrUpdateLine("PivotM5_L",  pivM5.low,   PivotLowColor,  1, STYLE_DASHDOTDOT);
      if(UseTF_H4)
      {
         if(pivH4.high>0.0) DrawOrUpdateLine("PivotH4_H", pivH4.high, PivotHighColor, 1, STYLE_DASHDOTDOT);
         if(pivH4.low>0.0)  DrawOrUpdateLine("PivotH4_L", pivH4.low,  PivotLowColor,  1, STYLE_DASHDOTDOT);
      }
      if(UseTF_D1)
      {
         if(pivD1.high>0.0) DrawOrUpdateLine("PivotD1_H", pivD1.high, PivotHighColor, 1, STYLE_DASHDOTDOT);
         if(pivD1.low>0.0)  DrawOrUpdateLine("PivotD1_L", pivD1.low,  PivotLowColor,  1, STYLE_DASHDOTDOT);
      }
   }

   // Отрисовка классических уровней Pivot (Daily) — как отдельная подсистема
   if(ShowClassicPivot)
   {
      CalculateClassicPivotLevels(_Symbol, PERIOD_D1);
      DrawOrUpdateLine(objPivot, pivotLevel, clrYellow,     2, STYLE_SOLID);
      DrawOrUpdateLine(objR1,    r1Level,    clrDodgerBlue, 1, STYLE_DOT);
      DrawOrUpdateLine(objR2,    r2Level,    clrDodgerBlue, 1, STYLE_DOT);
      DrawOrUpdateLine(objS1,    s1Level,    clrOrange,     1, STYLE_DOT);
      DrawOrUpdateLine(objS2,    s2Level,    clrOrange,     1, STYLE_DOT);
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
