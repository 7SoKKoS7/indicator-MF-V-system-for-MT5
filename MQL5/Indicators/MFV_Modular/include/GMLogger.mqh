// MQL5/Indicators/MFV_Modular/include/GMLogger.mqh
#ifndef __MFV_GMLOGGER_MQH__
#define __MFV_GMLOGGER_MQH__

#define MFV_GM_LOG 1   // 0 = отключить лог вообще на этапе сборки

class GMLogger {
   int    h;
   string tag;
public:
   GMLogger():h(INVALID_HANDLE),tag(""){}

   bool Init(const string _tag){
      tag=_tag;
      string fn = StringFormat("mfv_%s_%s.csv", tag, _Symbol);
      h = FileOpen(fn, FILE_WRITE|FILE_READ|FILE_CSV|FILE_COMMON);
      if(h==INVALID_HANDLE) return false;
      if(FileSize(h)==0){
         FileWrite(h,"time","tf","price","pivotH","pivotL","trend","sig","note");
         FileFlush(h);
      } else {
         FileSeek(h, 0, SEEK_END);
      }
      return true;
   }

   void Close(){ if(h!=INVALID_HANDLE){ FileClose(h); h=INVALID_HANDLE; } }

   void LogRaw(ENUM_TIMEFRAMES tf, datetime t, double price,
               double pH, double pL, const string trend,
               const string sig, const string note)
   {
#ifdef MFV_GM_LOG
      if(h==INVALID_HANDLE) return;
      FileWrite(h,
         TimeToString(t, TIME_DATE|TIME_SECONDS),
         EnumToString(tf),
         DoubleToString(price,_Digits),
         DoubleToString(pH,_Digits),
         DoubleToString(pL,_Digits),
         trend, sig, note);
#endif
   }
};

#endif // __MFV_GMLOGGER_MQH__