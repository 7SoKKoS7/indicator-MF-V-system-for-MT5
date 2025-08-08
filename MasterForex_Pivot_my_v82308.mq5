//+------------------------------------------------------------------+
//| MasterForex-V MultiTF Indicator v8.2308                          |
//| Индикатор с подтверждёнными MF-pivot и дополнительными сигналами |
//| Улучшенная версия с дополнительными настройками                  |
//| Соответствует стратегии MasterForex-V                             |
//+------------------------------------------------------------------+
#property copyright "MasterForex-V"
#property link      "https://www.masterforex-v.org/"
#property version   "8.23.08"
#property strict

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   8

//--- Input Parameters / Входные параметры
input group "=== Основные настройки ==="
input bool   UseRussian = false;              // Подписи на русском языке
input bool   ShowClassicPivot = true;         // Показывать классические уровни Pivot
input bool   ShowStatusInfo = true;           // Показывать информацию о статусе
input bool   EnableVolumeFilter = true;       // Фильтр по объему
input bool   EnableSessionFilter = true;      // Фильтр торговых сессий

input group "=== Настройки ZigZag ==="
input int    InpDepth = 12;                   // Глубина ZigZag
input double InpDeviation = 5.0;              // Отклонение в пунктах

input group "=== Фильтры MasterForex-V ==="
input double MinVolumeMultiplier = 1.2;       // Минимальный множитель объема
input int    MinTrendStrength = 2;            // Минимальная сила тренда (1-3)
input bool   UseRiskManagement = true;        // Использовать управление рисками
input double MaxRiskPercent = 2.0;            // Максимальный риск в %

input group "=== Цвета стрелок ==="
input color  BuyArrowColor = clrLime;         // Цвет стрелки покупки
input color  SellArrowColor = clrRed;         // Цвет стрелки продажи
input color  EarlyBuyColor = clrLime;         // Цвет ранней покупки
input color  EarlySellColor = clrRed;         // Цвет ранней продажи
input color  ExitColor = clrGray;             // Цвет выхода
input color  ReverseColor = clrAqua;          // Цвет разворота
input color  StrongSignalColor = clrYellow;   // Цвет сильного сигнала

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

//--- Buffers for various signals / Буферы сигналов
double BuyArrowBuffer[];    // сильный сигнал покупки
double SellArrowBuffer[];   // сильный сигнал продажи
double EarlyBuyBuffer[];    // ранний вход покупка
double EarlySellBuffer[];   // ранний вход продажа
double ExitBuffer[];        // крестик выхода
double ReverseBuffer[];     // метка разворота
double StrongBuyBuffer[];   // очень сильный сигнал покупки
double StrongSellBuffer[];  // очень сильный сигнал продажи

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
   
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   int hour = dt.hour;
   
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
VolumeAnalysis AnalyzeVolumeOnMasterForexTimeframes()
{
   VolumeAnalysis analysis;
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
   
   return analysis;
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

   // Настройка цветов
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, BuyArrowColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, SellArrowColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, EarlyBuyColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, EarlySellColor);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, ExitColor);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, ReverseColor);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, StrongSignalColor);
   PlotIndexSetInteger(7, PLOT_LINE_COLOR, StrongSignalColor);

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
   int direction = 0;
   
   for(int i = count-2; i >= 0; --i)
   {
      double price = close[i];
      if(direction == 0)
      {
         if(MathAbs(price - last_pivot_price) > deviation)
         {
            direction = (price > last_pivot_price) ? 1 : -1;
            last_pivot_price = price;
         }
      }
      else if(direction == 1)
      {
         if(price > last_pivot_price)
            last_pivot_price = price;
         else if((last_pivot_price - price) > deviation)
            return last_pivot_price;
      }
      else // direction == -1
      {
         if(price < last_pivot_price)
            last_pivot_price = price;
         else if((price - last_pivot_price) > deviation)
            return last_pivot_price;
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
   VolumeAnalysis volumeAnalysis = AnalyzeVolumeOnMasterForexTimeframes();
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
   bool canTrade = analysis.sessionValid && analysis.volumeConfirmed && analysis.strength >= MinTrendStrength;

   if(trendH1 == 1 && trendM15 == 1 && trendM5 == 1 && canTrade)
   {
      if(analysis.strength >= 3)
         StrongBuyBuffer[1] = price[1] - ArrowOffset * _Point;
      else
         BuyArrowBuffer[1] = price[1] - ArrowOffset * _Point;
      lastSignal = 1;
      lastPivot  = pivotH1;
   }
   else if(trendH1 == -1 && trendM15 == -1 && trendM5 == -1 && canTrade)
   {
      if(analysis.strength >= 3)
         StrongSellBuffer[1] = price[1] + ArrowOffset * _Point;
      else
         SellArrowBuffer[1] = price[1] + ArrowOffset * _Point;
      lastSignal = -1;
      lastPivot  = pivotH1;
   }
   else if(trendH1 == 1 && trendM5 == 1 && trendM15 != 1 && canTrade)
   {
      EarlyBuyBuffer[1] = price[1] - ArrowOffset * _Point;
   }
   else if(trendH1 == -1 && trendM5 == -1 && trendM15 != -1 && canTrade)
   {
      EarlySellBuffer[1] = price[1] + ArrowOffset * _Point;
   }

   // Логика выхода
   if(lastSignal == 1 && price_now < lastPivot)
   {
      ExitBuffer[1] = price[1];
      lastSignal = 0;
   }
   else if(lastSignal == -1 && price_now > lastPivot)
   {
      ExitBuffer[1] = price[1];
      lastSignal = 0;
   }

   // Логика разворота
   if(trendH1 == trendM15 && trendH1 != 0 && trendH1 != lastTrendH1 && lastTrendH1 != 0)
   {
      ReverseBuffer[1] = price[1];
   }
   lastTrendH1  = trendH1;
   lastTrendM15 = trendM15;

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
