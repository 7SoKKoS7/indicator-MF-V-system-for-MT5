#ifndef __MFV_CONFIG_MQH__
#define __MFV_CONFIG_MQH__

enum PivotAlgo { Pivot_ZigZag=0, Pivot_Swing=1 };

class MFVConfig {
public:
   bool   UseRussian;
   bool   EnableVolumeFilter;
   bool   EnableSessionFilter;
   bool   UseClinchFilter;
   bool   UseImpulseFilter;
   int    H1ClosesNeeded;
   int    RetestWindowM15, RetestWindowM5;
   double RetestTolATR_M15, RetestTolATR_M5;
   int    PanelFontSize;
   int    PanelYOffset;
   color  PivotColorH;
   color  PivotColorL;
   ENUM_LINE_STYLE PivotLineStyle;
   int    PivotLineWidth;
   // ZigZag / Pivot settings
   int    ZZ_Depth;
   int    ZZ_Deviation;
   int    ZZ_Backstep;
   PivotAlgo PivotAlgorithm;
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
      PanelFontSize       = ::PanelFontSize;
      PanelYOffset        = ::PanelYOffset;
      PivotColorH         = ::PivotColorH;
      PivotColorL         = ::PivotColorL;
      PivotLineStyle      = ::PivotLineStyle;
      PivotLineWidth      = ::PivotLineWidth;
      // значения по умолчанию для ZigZag/пивотов
      ZZ_Depth            = 12;
      ZZ_Deviation        = 5;
      ZZ_Backstep         = 3;
      PivotAlgorithm      = Pivot_ZigZag;
   }
};

#endif // __MFV_CONFIG_MQH__
