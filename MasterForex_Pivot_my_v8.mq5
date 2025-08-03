//+------------------------------------------------------------------+
//| MasterForex-V MultiTF Indicator v8.0                             |
//| Индикатор с подтверждёнными MF-pivot и дополнительными сигналами |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

input string ZigZagPath = "Examples\\ZigZag"; // путь к индикатору ZigZag
input bool   UseRussian = false;              // подписи на русском языке

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

//--- Cached ZigZag handles / Кэшированные хэндлы ZigZag
int zzHandleH1  = INVALID_HANDLE;
int zzHandleM15 = INVALID_HANDLE;
int zzHandleM5  = INVALID_HANDLE;
int zzHandleH4  = INVALID_HANDLE;
int zzHandleD1  = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Initialization / Инициализация                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, BuyArrowBuffer,   INDICATOR_DATA);
   SetIndexBuffer(1, SellArrowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(2, EarlyBuyBuffer,   INDICATOR_DATA);
   SetIndexBuffer(3, EarlySellBuffer,  INDICATOR_DATA);
   SetIndexBuffer(4, ExitBuffer,       INDICATOR_DATA);
   SetIndexBuffer(5, ReverseBuffer,    INDICATOR_DATA);

   ArraySetAsSeries(BuyArrowBuffer,   true);
   ArraySetAsSeries(SellArrowBuffer,  true);
   ArraySetAsSeries(EarlyBuyBuffer,   true);
   ArraySetAsSeries(EarlySellBuffer,  true);
   ArraySetAsSeries(ExitBuffer,       true);
   ArraySetAsSeries(ReverseBuffer,    true);

   IndicatorSetString(INDICATOR_SHORTNAME, "MasterForex-V MultiTF v8.0");

   PlotIndexSetInteger(0, PLOT_ARROW, 233); // up arrow
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // down arrow
   PlotIndexSetInteger(2, PLOT_ARROW, 241); // early up
   PlotIndexSetInteger(3, PLOT_ARROW, 242); // early down
   PlotIndexSetInteger(4, PLOT_ARROW, 251); // cross exit
   PlotIndexSetInteger(5, PLOT_ARROW, 221); // reversal mark

   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrLime);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrLime);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrGray);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, clrAqua);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization / Деинициализация                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(zzHandleH1  != INVALID_HANDLE) IndicatorRelease(zzHandleH1);
   if(zzHandleM15 != INVALID_HANDLE) IndicatorRelease(zzHandleM15);
   if(zzHandleM5  != INVALID_HANDLE) IndicatorRelease(zzHandleM5);
   if(zzHandleH4  != INVALID_HANDLE) IndicatorRelease(zzHandleH4);
   if(zzHandleD1  != INVALID_HANDLE) IndicatorRelease(zzHandleD1);
  }

//+------------------------------------------------------------------+
//| Retrieve last ZigZag extremum (MF-pivot)                         |
//+------------------------------------------------------------------+
double GetLastPivot(string symbol, ENUM_TIMEFRAMES tf, int &handle)
  {
   if(handle == INVALID_HANDLE)
     {
      handle = iCustom(symbol, tf, ZigZagPath, 12, 5, 3);
      if(handle == INVALID_HANDLE)
        {
         Print("ZigZag handle error tf=", tf, " err=", GetLastError());
         return 0.0;
        }
     }

   double zzBuffer[];
   if(CopyBuffer(handle, 0, 0, 200, zzBuffer) <= 0)
     {
      Print("CopyBuffer ZigZag failed tf=", tf, " err=", GetLastError());
      return 0.0;
     }

   for(int i=1; i<200; i++)      // skip current bar
      if(zzBuffer[i] != 0.0)
         return zzBuffer[i];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Determine trend                                                  |
//+------------------------------------------------------------------+
int GetTrend(double price, double pivot, double tol=0.0001)
  {
   if(price > pivot + tol) return 1;
   if(price < pivot - tol) return -1;
   return 0;
  }

//+------------------------------------------------------------------+
//| Calculate classic Pivot levels                                   |
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
//| Draw or update horizontal line                                   |
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
//| Draw single status row                                           |
//+------------------------------------------------------------------+
void DrawRowLabel(string name, string text, int y)
  {
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
//| Main calculation                                                 |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   ArraySetAsSeries(price, true);
   ArrayResize(BuyArrowBuffer,   rates_total);
   ArrayResize(SellArrowBuffer,  rates_total);
   ArrayResize(EarlyBuyBuffer,   rates_total);
   ArrayResize(EarlySellBuffer,  rates_total);
   ArrayResize(ExitBuffer,       rates_total);
   ArrayResize(ReverseBuffer,    rates_total);

   BuyArrowBuffer[0]   = EMPTY_VALUE;
   SellArrowBuffer[0]  = EMPTY_VALUE;
   EarlyBuyBuffer[0]   = EMPTY_VALUE;
   EarlySellBuffer[0]  = EMPTY_VALUE;
   ExitBuffer[0]       = EMPTY_VALUE;
   ReverseBuffer[0]    = EMPTY_VALUE;

   double price_now = price[0];

   static int    lastSignal   = 0;
   static double lastPivot    = 0.0;
   static int    lastTrendH1  = 0;
   static int    lastTrendM15 = 0;

   double pivotH1  = GetLastPivot(_Symbol, PERIOD_H1,  zzHandleH1);
   double pivotM15 = GetLastPivot(_Symbol, PERIOD_M15, zzHandleM15);
   double pivotM5  = GetLastPivot(_Symbol, PERIOD_M5,  zzHandleM5);

   mfPivotH4 = GetLastPivot(_Symbol, PERIOD_H4, zzHandleH4);
   mfPivotD1 = GetLastPivot(_Symbol, PERIOD_D1, zzHandleD1);

   if(pivotH1 == 0.0 || pivotM15 == 0.0 || pivotM5 == 0.0)
     {
      Print("Pivots unavailable, skipping signals");
      return(rates_total);
     }

   int trendH1  = GetTrend(price_now, pivotH1);
   int trendM15 = GetTrend(price_now, pivotM15);
   int trendM5  = GetTrend(price_now, pivotM5);

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

   DrawRowLabel("MFV_STATUS_TREND", trendStatus, 10);
   DrawRowLabel("MFV_STATUS_M5",    levelM5,     30);
   DrawRowLabel("MFV_STATUS_M15",   levelM15,    50);
   DrawRowLabel("MFV_STATUS_H1",    levelH1,     70);
   DrawRowLabel("MFV_STATUS_H4",    levelH4,     90);
   DrawRowLabel("MFV_STATUS_D1",    levelD1,     110);

   if(trendH1 == 1 && trendM15 == 1 && trendM5 == 1)
     {
      BuyArrowBuffer[1] = price[1] - 10 * _Point;
      lastSignal = 1;
      lastPivot  = pivotH1;
     }
   else if(trendH1 == -1 && trendM15 == -1 && trendM5 == -1)
     {
      SellArrowBuffer[1] = price[1] + 10 * _Point;
      lastSignal = -1;
      lastPivot  = pivotH1;
     }
   else if(trendH1 == 1 && trendM5 == 1 && trendM15 != 1)
     {
      EarlyBuyBuffer[1] = price[1] - 10 * _Point;
     }
   else if(trendH1 == -1 && trendM5 == -1 && trendM15 != -1)
     {
      EarlySellBuffer[1] = price[1] + 10 * _Point;
     }

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

   if(trendH1 == trendM15 && trendH1 != 0 && trendH1 != lastTrendH1 && lastTrendH1 != 0)
     {
      ReverseBuffer[1] = price[1];
     }
   lastTrendH1  = trendH1;
   lastTrendM15 = trendM15;

   DrawOrUpdateLine("MF_PIVOT_H1",  pivotH1,  clrBlue,     2);
   DrawOrUpdateLine("MF_PIVOT_M15", pivotM15, clrGreen,    1);
   DrawOrUpdateLine("MF_PIVOT_M5",  pivotM5,  clrOrange,   1);
   DrawOrUpdateLine("MF_PIVOT_H4",  mfPivotH4, clrMagenta, 1, STYLE_DASH);
   DrawOrUpdateLine("MF_PIVOT_D1",  mfPivotD1, clrDimGray, 1, STYLE_DASH);

   CalculateClassicPivotLevels(_Symbol, PERIOD_D1);
   DrawOrUpdateLine(objPivot, pivotLevel, clrYellow,     2, STYLE_SOLID);
   DrawOrUpdateLine(objR1,    r1Level,    clrDodgerBlue, 1, STYLE_DOT);
   DrawOrUpdateLine(objR2,    r2Level,    clrDodgerBlue, 1, STYLE_DOT);
   DrawOrUpdateLine(objS1,    s1Level,    clrOrange,     1, STYLE_DOT);
   DrawOrUpdateLine(objS2,    s2Level,    clrOrange,     1, STYLE_DOT);

   return(rates_total);
  }
//+------------------------------------------------------------------+
