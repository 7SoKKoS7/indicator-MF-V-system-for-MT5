//+------------------------------------------------------------------+
//| MasterForex-V MultiTF Indicator с классическими Pivot Levels     |
//| Version 4.0 - GetLastPivot skips current bar and waits depth confirmation |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   4
#property version   "4.0"

//--- Buy arrow
#property indicator_label1  "BuyArrow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Sell arrow
#property indicator_label2  "SellArrow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

double BuyArrowBuffer[];
double SellArrowBuffer[];

//--- Для MF-pivot (ZigZag)
double mfPivotH1[];
double mfPivotM15[];
double mfPivotM5[];

//--- Для H4 и D1 новых уровней
double mfPivotH4;
double mfPivotD1;

//--- Классические Pivot уровни
double pivotLevel, r1Level, r2Level, s1Level, s2Level;

//--- Объекты для линий классических Pivot
string objPivot = "MF_ClassicPivot";
string objR1 = "MF_ClassicR1";
string objR2 = "MF_ClassicR2";
string objS1 = "MF_ClassicS1";
string objS2 = "MF_ClassicS2";

//+------------------------------------------------------------------+
//| Инициализация                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, BuyArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SellArrowBuffer, INDICATOR_DATA);
   ArraySetAsSeries(BuyArrowBuffer, true);
   ArraySetAsSeries(SellArrowBuffer, true);

   IndicatorSetString(INDICATOR_SHORTNAME, "MasterForex-V MT5 with Classic Pivot");

   PlotIndexSetInteger(0, PLOT_ARROW, 233); // стрелка вверх (Wingdings)
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // стрелка вниз (Wingdings)

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Получение последнего экстремума ZigZag (MF-pivot)                |
//+------------------------------------------------------------------+
double GetLastPivot(string symbol, ENUM_TIMEFRAMES tf)
  {
   int depth = 12;
   int handle = iCustom(symbol, tf, "ZigZag", depth, 5, 3);
   if(handle == INVALID_HANDLE) return 0.0;

   double zzBuffer[];
   int copied = CopyBuffer(handle, 0, 0, 200 + depth, zzBuffer);
   if(copied <= depth)
     {
      IndicatorRelease(handle);
      return 0.0;
     }

   for(int i=1; i<copied - depth; i++)
     {
      if(zzBuffer[i] != 0.0 && zzBuffer[i + depth] != 0.0)
        {
         IndicatorRelease(handle);
         return zzBuffer[i];
        }
     }

   IndicatorRelease(handle);
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Определение тренда: Up/Down/Flat                                 |
//+------------------------------------------------------------------+
int GetTrend(double price, double pivot, double tol=0.0001)
  {
   if(price > pivot + tol) return 1;
   if(price < pivot - tol) return -1;
   return 0;
  }

//+------------------------------------------------------------------+
//| Расчет классических уровней Pivot по предыдущему бару текущего ТФ|
//+------------------------------------------------------------------+
void CalculateClassicPivotLevels(string symbol, ENUM_TIMEFRAMES tf)
  {
   double high = iHigh(symbol, tf, 1);
   double low = iLow(symbol, tf, 1);
   double close = iClose(symbol, tf, 1);

   pivotLevel = (high + low + close) / 3.0;
   r1Level = 2 * pivotLevel - low;
   s1Level = 2 * pivotLevel - high;
   r2Level = pivotLevel + (high - low);
   s2Level = pivotLevel - (high - low);
  }

//+------------------------------------------------------------------+
//| Функция отрисовки линий уровней                                  |
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
//| Функция для отрисовки одной строки статуса в левом верхнем углу  |
//+------------------------------------------------------------------+
void DrawRowLabel(string name, string text, int y)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, 0); // левый верхний угол
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
     }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

//+------------------------------------------------------------------+
//| Основная функция OnCalculate                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   ArraySetAsSeries(price, true);
   ArrayResize(BuyArrowBuffer, rates_total);
   ArrayResize(SellArrowBuffer, rates_total);
   ArrayInitialize(BuyArrowBuffer, EMPTY_VALUE);
   ArrayInitialize(SellArrowBuffer, EMPTY_VALUE);

   double price_now = price[0];

   // Получаем MF-pivot для каждого ТФ
   double pivotH1  = GetLastPivot(_Symbol, PERIOD_H1);
   double pivotM15 = GetLastPivot(_Symbol, PERIOD_M15);
   double pivotM5  = GetLastPivot(_Symbol, PERIOD_M5);

   // Новое: MF-pivot для H4 и D1
   mfPivotH4 = GetLastPivot(_Symbol, PERIOD_H4);
   mfPivotD1 = GetLastPivot(_Symbol, PERIOD_D1);

   // Определяем тренды (сигналы по M5, M15, H1!)
   int trendH1  = GetTrend(price_now, pivotH1);
   int trendM15 = GetTrend(price_now, pivotM15);
   int trendM5  = GetTrend(price_now, pivotM5);

   // Формируем строку трендов (стрелки)
   string strH1  = trendH1 > 0  ? "↑" : (trendH1 < 0  ? "↓" : "-");
   string strM15 = trendM15 > 0 ? "↑" : (trendM15 < 0 ? "↓" : "-");
   string strM5  = trendM5 > 0  ? "↑" : (trendM5 < 0  ? "↓" : "-");
   string trendStatus = "H1: " + strH1 + "   M15: " + strM15 + "   M5: " + strM5;

   // MF-pivot уровни: каждая строка отдельно
   string levelM5  = "M5:   "  + DoubleToString(pivotM5,  _Digits);
   string levelM15 = "M15:  " + DoubleToString(pivotM15, _Digits);
   string levelH1  = "H1:   " + DoubleToString(pivotH1,  _Digits);
   string levelH4  = "H4:   " + DoubleToString(mfPivotH4, _Digits);
   string levelD1  = "D1:   " + DoubleToString(mfPivotD1, _Digits);

   // --- Отрисовываем каждую строку отдельно друг под другом
   DrawRowLabel("MFV_STATUS_TREND", trendStatus,    10);  // Верхняя строка
   DrawRowLabel("MFV_STATUS_M5",    levelM5,        30);  // Следующая ниже
   DrawRowLabel("MFV_STATUS_M15",   levelM15,       50);
   DrawRowLabel("MFV_STATUS_H1",    levelH1,        70);
   DrawRowLabel("MFV_STATUS_H4",    levelH4,        90);
   DrawRowLabel("MFV_STATUS_D1",    levelD1,        110);

   // Рисуем стрелки входа (логика не меняется!)
   if(trendH1 == 1 && trendM15 == 1 && trendM5 == 1)
      BuyArrowBuffer[0] = price_now - 10 * _Point;
   else if(trendH1 == -1 && trendM15 == -1 && trendM5 == -1)
      SellArrowBuffer[0] = price_now + 10 * _Point;

   // Рисуем линии MF-pivot
   DrawOrUpdateLine("MF_PIVOT_H1",  pivotH1,  clrBlue,     2);
   DrawOrUpdateLine("MF_PIVOT_M15", pivotM15, clrGreen,    1);
   DrawOrUpdateLine("MF_PIVOT_M5",  pivotM5,  clrOrange,   1);

   // Новое: линии MF-pivot для H4 и D1
   DrawOrUpdateLine("MF_PIVOT_H4",  mfPivotH4, clrMagenta, 1, STYLE_DASH);
   DrawOrUpdateLine("MF_PIVOT_D1",  mfPivotD1, clrDimGray, 1, STYLE_DASH);

   // Классические Pivot уровни: всегда по D1
   CalculateClassicPivotLevels(_Symbol, PERIOD_D1);
   DrawOrUpdateLine(objPivot, pivotLevel,   clrYellow,     2, STYLE_SOLID);
   DrawOrUpdateLine(objR1,    r1Level,      clrDodgerBlue, 1, STYLE_DOT);
   DrawOrUpdateLine(objR2,    r2Level,      clrDodgerBlue, 1, STYLE_DOT);
   DrawOrUpdateLine(objS1,    s1Level,      clrOrange,     1, STYLE_DOT);
   DrawOrUpdateLine(objS2,    s2Level,      clrOrange,     1, STYLE_DOT);

   return(rates_total);
  }