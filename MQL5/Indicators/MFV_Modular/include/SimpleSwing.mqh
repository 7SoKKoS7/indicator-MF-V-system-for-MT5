#pragma once
struct SwingPivot { double High; double Low; int lastSwing; datetime ts; SwingPivot():High(0),Low(0),lastSwing(0),ts(0){} };
class SimpleSwing {
public:
   static SwingPivot Compute(ENUM_TIMEFRAMES tf){ return SwingPivot(); } // позже можно реализовать
};


