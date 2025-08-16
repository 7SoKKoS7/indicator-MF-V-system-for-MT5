// Include guard for SimpleSwing fallback
#ifndef __MFV_SIMPLESWING_MQH__
#define __MFV_SIMPLESWING_MQH__

struct SwingPivot
  {
   double   High;
   double   Low;
   int      lastSwing;
   datetime ts;

   // Конструктор по умолчанию
   SwingPivot()
     {
      High = 0.0;
      Low = 0.0;
      lastSwing = 0;
      ts = 0;
     }

   // Копирующий конструктор (явный)
   SwingPivot(const SwingPivot &other)
     {
      High = other.High;
      Low = other.Low;
      lastSwing = other.lastSwing;
      ts = other.ts;
     }
  };
class SimpleSwing {
public:
   static SwingPivot Compute(ENUM_TIMEFRAMES tf){ return SwingPivot(); } // позже можно реализовать
};

#endif // __MFV_SIMPLESWING_MQH__


