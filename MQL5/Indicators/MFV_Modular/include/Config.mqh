#pragma once
struct MFVConfig {
   bool   UseRussian;
   bool   EnableVolumeFilter;
   bool   EnableSessionFilter;
   bool   UseClinchFilter;
   bool   UseImpulseFilter;
   int    H1ClosesNeeded;
   int    RetestWindowM15, RetestWindowM5;
   double RetestTolATR_M15, RetestTolATR_M5;
   void LoadInputs(){
      // начальные значения; позже можно читать из input-параметров
      UseRussian          = ::UseRussian;
      EnableVolumeFilter  = ::EnableVolumeFilter;
      EnableSessionFilter = ::EnableSessionFilter;
      UseClinchFilter     = ::UseClinchFilter;
      UseImpulseFilter    = ::UseImpulseFilter;
      H1ClosesNeeded      = ::H1ClosesNeeded;
      RetestWindowM15     = ::RetestWindowM15;
      RetestWindowM5      = ::RetestWindowM5;
      RetestTolATR_M15    = ::RetestTolATR_M15;
      RetestTolATR_M5     = ::RetestTolATR_M5;
   }
};


