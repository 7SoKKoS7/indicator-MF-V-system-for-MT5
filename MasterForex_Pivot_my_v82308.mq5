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

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9

// --- Breakout confirmation settings
enum ConfirmMode { Confirm_Off, Confirm_StrongOnly, Confirm_StrongAndNormal, Confirm_All };

//--- Input Parameters / Входные параметры
input group "=== Основные настройки ==="
input bool   UseRussian = false;              // Подписи на русском языке
input bool   ShowClassicPivot = true;         // Показывать классические уровни Pivot
input bool   ShowStatusInfo = true;           // Показывать информацию о статусе
input bool   EnableVolumeFilter = true;       // Фильтр по объему
input bool   EnableSessionFilter = true;      // Фильтр торговых сессий

input group "=== Сессии ==="
input int    SessionGMTOffset = 2;            // Смещение серверного времени относительно GMT (пример: 2 для GMT+2)

input group "=== Настройки ZigZag ==="
input int    InpDepth = 12;                   // Глубина ZigZag
input double InpDeviation = 5.0;              // Отклонение в пунктах

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

input group "=== Импульс-откат (MF A-B-C на M15) ==="
input bool   UseImpulseFilter     = true;   // Включить фильтр импульса/отката
input double ImpulseMinRatio      = 1.5;    // |B−A| / |C−B| минимум для "здорового" импульса
input double PullbackMaxFib       = 0.618;  // Максимальная глубина отката (доля импульса)
input int    ImpulseBackWindowM15 = 48;     // Поиск A перед B (M15-баров)
input int    PullbackWindowM15    = 12;     // Поиск C после B (M15-баров)

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
input color  PivotH1Color = clrBlue;          // Цвет H1 Pivot
input color  PivotM15Color = clrGreen;        // Цвет M15 Pivot
input color  PivotM5Color = clrOrange;        // Цвет M5 Pivot
input color  PivotH4Color = clrMagenta;       // Цвет H4 Pivot
input color  PivotD1Color = clrDimGray;       // Цвет D1 Pivot

input group "=== Размеры стрелок ==="
input int    ArrowWidth = 2;                  // Толщина стрелок
input int    ArrowOffset = 10;                // Смещение стрелок в пунктах

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

int CopyCloseH1(const int bars, double &buf[])
{
   ArraySetAsSeries(buf, true);
   int got = CopyClose(_Symbol, PERIOD_H1, 0, bars, buf);
   return got;
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

bool CheckH1Breakout(const double pivotH1, const int dir)
{
   // dir = +1 buy, -1 sell
   double c0 = iClose(_Symbol, PERIOD_H1, 1);
   if(H1ClosesNeeded <= 1)
      return (dir>0 ? c0>pivotH1 : c0<pivotH1);
   double c1 = iClose(_Symbol, PERIOD_H1, 2);
   return (dir>0 ? (c0>pivotH1 && c1>pivotH1) : (c0<pivotH1 && c1<pivotH1));
}

bool CheckRetestBounce_M15(const double pivotH1, const int dir, datetime fromTime)
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
   double top  = pivotH1 + half, bot = pivotH1 - half;

   int bars = MathMin(MathMax(RetestWindowM15, 1), 48);
   for(int i=1; i<=bars; ++i)
   {
      datetime t = iTime(_Symbol, PERIOD_M15, i);
      if(t < fromTime) break; // ретест должен быть после пробоя

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
      bool closeOk    = (dir>0 ? c>pivotH1 : c<pivotH1);

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

ClinchStatus CalcClinchH1(const double pivotH1, const int lookback, const int flipsMin,
                          const double rangeMaxATR, const double kATR)
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

   int flips = 0;
   int prevSign = 0;
   for(int i=useClose-1; i>=0; i--) // от старых к новым
   {
      double diff = c[i] - pivotH1;
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

   // Зона вокруг pivot и факт касания ценой за Lookback
   double half = kATR * cs.atr;
   cs.zoneTop = pivotH1 + half;
   cs.zoneBot = pivotH1 - half;
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
   // Нормализуем границы цены
   double half = ClinchAtrK * GetATR_H1();
   double top  = pivotH1 + half;
   double bot  = pivotH1 - half;
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

//--- For new levels on H4 and D1 / Для H4 и D1 новых уровней
double mfPivotH4;
double mfPivotD1;

//--- Classic Pivot levels / Классические уровни Pivot
double pivotLevel, r1Level, r2Level, s1Level, s2Level;

//--- Objects for classic Pivot lines / Объекты для линий классических Pivot
string objPivot = "MF_ClassicPivot";
string objR1    = "MF_ClassicR1";
string objR2    = "MF_ClassicR2";
string objS1    = "MF_ClassicS1";
string objS2    = "MF_ClassicS2";

//--- Кэш для оптимизации
struct PivotCache
{
   double h1, m15, m5, h4, d1;
   datetime lastUpdate;
   bool isValid;
};

static PivotCache pivotCache;

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

   // Инициализация кэша
   pivotCache.isValid = false;
   pivotCache.lastUpdate = 0;

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
   }
}

//+------------------------------------------------------------------+
//| Retrieve last ZigZag extremum (MF-pivot) - оптимизированная версия |
//+------------------------------------------------------------------+
double GetLastPivot(string symbol, ENUM_TIMEFRAMES tf)
{
   int bars = iBars(symbol, tf);
   if(bars < InpDepth + 2)
      return 0.0;

   int count = MathMin(bars, 300);
   double close[];
   if(CopyClose(symbol, tf, 0, count, close) <= 0)
      return 0.0;
   ArraySetAsSeries(close, true);

   double deviation = InpDeviation * _Point;
    double last_pivot_price = close[count-1];
    int    last_pivot_index = count-1;     // индекс последнего кандидата в пивот
    int    direction = 0;                   // 0 — не определено, 1 — ищем максимум, -1 — ищем минимум
    const int minDistance = MathMax(1, InpDepth); // минимальная дистанция между пивотами
   
   for(int i = count-2; i >= 0; --i)
   {
      double price = close[i];
       if(direction == 0)
      {
         if(MathAbs(price - last_pivot_price) > deviation)
         {
            direction = (price > last_pivot_price) ? 1 : -1;
            last_pivot_price = price;
            last_pivot_index = i;
         }
      }
      else if(direction == 1)
      {
          if(price > last_pivot_price)
          {
             last_pivot_price = price;
             last_pivot_index = i;
          }
          else if((last_pivot_price - price) > deviation && (last_pivot_index - i) >= minDistance)
          {
             // Подтвержден локальный максимум с учетом глубины
             return last_pivot_price;
          }
      }
      else // direction == -1
      {
          if(price < last_pivot_price)
          {
             last_pivot_price = price;
             last_pivot_index = i;
          }
          else if((price - last_pivot_price) > deviation && (last_pivot_index - i) >= minDistance)
          {
             // Подтвержден локальный минимум с учетом глубины
             return last_pivot_price;
          }
      }
   }
   return last_pivot_price;
}

//+------------------------------------------------------------------+
//| Get cached pivot values / Получение кэшированных значений pivot |
//+------------------------------------------------------------------+
void UpdatePivotCache()
{
   datetime currentTime = TimeCurrent();
   
   // Обновляем кэш только если прошло достаточно времени или он недействителен
   if(!pivotCache.isValid || (currentTime - pivotCache.lastUpdate) > 60)
   {
      pivotCache.h1 = GetLastPivot(_Symbol, PERIOD_H1);
      pivotCache.m15 = GetLastPivot(_Symbol, PERIOD_M15);
      pivotCache.m5 = GetLastPivot(_Symbol, PERIOD_M5);
      pivotCache.h4 = GetLastPivot(_Symbol, PERIOD_H4);
      pivotCache.d1 = GetLastPivot(_Symbol, PERIOD_D1);
      
      pivotCache.lastUpdate = currentTime;
      pivotCache.isValid = true;
   }
}

//+------------------------------------------------------------------+
//| Determine trend / Определение тренда                              |
//+------------------------------------------------------------------+
int GetTrend(double price, double pivot, double tol=0.0001)
{
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
   
   // Изменение размера буферов
   ArrayResize(BuyArrowBuffer,   rates_total);
   ArrayResize(SellArrowBuffer,  rates_total);
   ArrayResize(EarlyBuyBuffer,   rates_total);
   ArrayResize(EarlySellBuffer,  rates_total);
   ArrayResize(ExitBuffer,       rates_total);
   ArrayResize(ReverseBuffer,    rates_total);
   ArrayResize(StrongBuyBuffer,  rates_total);
   ArrayResize(StrongSellBuffer, rates_total);

   // Инициализация буферов
   BuyArrowBuffer[0]   = EMPTY_VALUE;
   SellArrowBuffer[0]  = EMPTY_VALUE;
   EarlyBuyBuffer[0]   = EMPTY_VALUE;
   EarlySellBuffer[0]  = EMPTY_VALUE;
   ExitBuffer[0]       = EMPTY_VALUE;
   ReverseBuffer[0]    = EMPTY_VALUE;
   StrongBuyBuffer[0]  = EMPTY_VALUE;
   StrongSellBuffer[0] = EMPTY_VALUE;

   double price_now = price[0];

   // Статические переменные для отслеживания состояния
   static int    lastSignal   = 0;
   static double lastPivot    = 0.0;
   static int    lastTrendH1  = 0;
   static int    lastTrendM15 = 0;

   // Обновление кэша pivot значений
   UpdatePivotCache();
   
   // Получение значений pivot из кэша
   double pivotH1  = pivotCache.h1;
   double pivotM15 = pivotCache.m15;
   double pivotM5  = pivotCache.m5;
   mfPivotH4 = pivotCache.h4;
   mfPivotD1 = pivotCache.d1;

   // Проверка доступности pivot значений
   if(pivotH1 == 0.0 || pivotM15 == 0.0 || pivotM5 == 0.0)
   {
      if(ShowStatusInfo)
         DrawRowLabel("MFV_STATUS_TREND", UseRussian ? "Ожидание данных..." : "Waiting for data...", 10);
      return(rates_total);
   }

   // Определение трендов
   int trendH1  = GetTrend(price_now, pivotH1);
   int trendM15 = GetTrend(price_now, pivotM15);
   int trendM5  = GetTrend(price_now, pivotM5);
   int trendH4  = GetTrend(price_now, mfPivotH4);
   int trendD1  = GetTrend(price_now, mfPivotD1);

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

   string pivotWord = UseRussian ? "Пивот" : "Pivot";
   string levelM5  = StringFormat("%s M5: %s",  pivotWord, DoubleToString(pivotM5,  _Digits));
   string levelM15 = StringFormat("%s M15: %s", pivotWord, DoubleToString(pivotM15, _Digits));
   string levelH1  = StringFormat("%s H1: %s",  pivotWord, DoubleToString(pivotH1,  _Digits));
   string levelH4  = StringFormat("%s H4: %s",  pivotWord, DoubleToString(mfPivotH4,_Digits));
   string levelD1  = StringFormat("%s D1: %s",  pivotWord, DoubleToString(mfPivotD1,_Digits));

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
   DrawRowLabel("MFV_STATUS_H4",    levelH4,     90);
   DrawRowLabel("MFV_STATUS_D1",    levelD1,     110);
   DrawRowLabel("MFV_STATUS_STRENGTH", strengthText, 130);
   DrawRowLabel("MFV_STATUS_VOLUME", volumeText, 150);
   DrawRowLabel("MFV_STATUS_SESSION", sessionText, 170);

   // Логика сигналов MasterForex-V
   bool firedStrongBuy=false, firedStrongSell=false, firedBuy=false, firedSell=false;
   bool firedEarlyBuy=false, firedEarlySell=false, firedHardExit=false, firedEarlyExit=false, firedReversal=false;
   bool canTrade = analysis.sessionValid && analysis.volumeConfirmed && analysis.strength >= MinTrendStrength;
   bool earlyCanTrade = analysis.sessionValid && analysis.volumeConfirmed && analysis.strength >= MinEarlyTrendStrength;

   // Расчет CLINCH по pivotH1 (не чаще 1 H1-бара). Обеспечиваем историю H1 на любом ТФ
   static ClinchStatus clinchState;
   EnsureH1History(MathMax(ClinchLookbackH1 + 20, 100));
   datetime lastH1Bar = iTime(_Symbol, PERIOD_H1, 0);
   if(UseClinchFilter && (lastClinchCalcOnH1 == 0 || lastH1Bar == 0 || lastH1Bar != lastClinchCalcOnH1))
   {
      clinchState = CalcClinchH1(pivotH1, ClinchLookbackH1, ClinchFlipsMin,
                                 ClinchRangeMaxATR, ClinchAtrK);
      lastClinchCalcOnH1 = (lastH1Bar == 0 ? TimeCurrent() : lastH1Bar);
      // Отрисовываем зону, если отключен фильтр показа или если зона была потрогана ценой
      if(!ShowClinchZoneOnlyIfTouched || clinchState.touched)
         DrawClinchZone("H1_CLINCH_ZONE", clinchState, pivotH1, clinchState.isClinch);
      else
         ObjectDelete(0, "H1_CLINCH_ZONE");
   }

   if(trendH1 == 1 && trendM15 == 1 && trendM5 == 1 && canTrade)
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
            bool okH1  = CheckH1Breakout(pivotH1, dir);
            bool okRet = CheckRetestBounce_M15(pivotH1, dir, iTime(_Symbol, PERIOD_H1, 1));
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
      if(sc == SigStrong)
      {
         StrongBuyBuffer[1] = price[1] - ArrowOffset * _Point;
         firedStrongBuy = true;
      }
      else if(sc == SigNormal)
      {
         BuyArrowBuffer[1] = price[1] - ArrowOffset * _Point;
         firedBuy = true;
      }
      // если понижен до SigEarly — отрисуем ранний вход
      else if(sc == SigEarly)
      {
         EarlyBuyBuffer[1] = price[1] - ArrowOffset * _Point;
         firedEarlyBuy = true;
      }
      lastSignal = 1;
      lastPivot  = pivotH1;
   }
   else if(trendH1 == -1 && trendM15 == -1 && trendM5 == -1 && canTrade)
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
            bool okH1  = CheckH1Breakout(pivotH1, dir);
            bool okRet = CheckRetestBounce_M15(pivotH1, dir, iTime(_Symbol, PERIOD_H1, 1));
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
      if(sc == SigStrong)
      {
         StrongSellBuffer[1] = price[1] + ArrowOffset * _Point;
         firedStrongSell = true;
      }
      else if(sc == SigNormal)
      {
         SellArrowBuffer[1] = price[1] + ArrowOffset * _Point;
         firedSell = true;
      }
      else if(sc == SigEarly)
      {
         EarlySellBuffer[1] = price[1] + ArrowOffset * _Point;
         firedEarlySell = true;
      }
      lastSignal = -1;
      lastPivot  = pivotH1;
   }
   else if(trendH1 == 1 && trendM5 == 1 && trendM15 != 1 && earlyCanTrade)
   {
      EarlyBuyBuffer[1] = price[1] - ArrowOffset * _Point;
      firedEarlyBuy = true;
   }
   else if(trendH1 == -1 && trendM5 == -1 && trendM15 != -1 && earlyCanTrade)
   {
      EarlySellBuffer[1] = price[1] + ArrowOffset * _Point;
      firedEarlySell = true;
   }

   // Логика выхода
   if(lastSignal == 1 && price_now < lastPivot)
   {
      ExitBuffer[1] = price[1];
      lastSignal = 0;
      firedHardExit = true;
   }
   else if(lastSignal == -1 && price_now > lastPivot)
   {
      ExitBuffer[1] = price[1];
      lastSignal = 0;
      firedHardExit = true;
   }

   // Ранний выход по смене тренда M15 против позиции
   if(lastSignal == 1 && trendM15 < 0)
   {
      // Мягкий (soft) выход
      // Для визуализации используем тот же стиль, но другой цвет/буфер
      // EarlyExitBuffer будет отрисован отдельным слоем
      // Координата по цене текущего бара-1
      // Примечание: не сбрасываем lastSignal, это индикатор, не EA
      EarlyExitBuffer[1] = price[1];
      firedEarlyExit = true;
   }
   else if(lastSignal == -1 && trendM15 > 0)
   {
      EarlyExitBuffer[1] = price[1];
      firedEarlyExit = true;
   }

   // Логика разворота
   if(trendH1 == trendM15 && trendH1 != 0 && trendH1 != lastTrendH1 && lastTrendH1 != 0)
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
   else if(firedEarlyBuy)  signalText = (UseRussian ? "Сигнал: Ранний вход (BUY)" : "Signal: Early BUY");
   else if(firedEarlySell) signalText = (UseRussian ? "Сигнал: Ранний вход (SELL)" : "Signal: Early SELL");
   else if(firedEarlyExit) signalText = (UseRussian ? "Сигнал: Ранний выход" : "Signal: Early EXIT");
   else if(firedHardExit)  signalText = (UseRussian ? "Сигнал: Выход (H1 Pivot)" : "Signal: HARD EXIT");
   else if(firedReversal)  signalText = (UseRussian ? "Сигнал: Разворот" : "Signal: Reversal");
   DrawRowLabel("MFV_STATUS_SIGNAL", signalText, 190);

   // Статус CLINCH (H1 pivot)
   double rangeAtr = (clinchState.atr > 0.0 ? (clinchState.range / clinchState.atr) : 0.0);
   string clinchOn = clinchState.isClinch ? (UseRussian ? "✓" : "✓") : (UseRussian ? "✗" : "✗");
   string clinchText = UseRussian ?
      StringFormat("Схватка: %s, flips=%d, range=%.2f ATR, zone=±%.2f ATR", clinchOn, clinchState.flips, rangeAtr, ClinchAtrK) :
      StringFormat("Clinch: %s, flips=%d, range=%.2f ATR, zone=±%.2f ATR", clinchOn, clinchState.flips, rangeAtr, ClinchAtrK);
   DrawRowLabel("MFV_STATUS_CLINCH", clinchText, 210);

   // Отрисовка линий Pivot
   DrawOrUpdateLine("MF_PIVOT_H1",  pivotH1,  PivotH1Color,     2);
   DrawOrUpdateLine("MF_PIVOT_M15", pivotM15, PivotM15Color,    1);
   DrawOrUpdateLine("MF_PIVOT_M5",  pivotM5,  PivotM5Color,     1);
   DrawOrUpdateLine("MF_PIVOT_H4",  mfPivotH4, PivotH4Color,    1, STYLE_DASH);
   DrawOrUpdateLine("MF_PIVOT_D1",  mfPivotD1, PivotD1Color,    1, STYLE_DASH);

   // Отрисовка классических уровней Pivot
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
