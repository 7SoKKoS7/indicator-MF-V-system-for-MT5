#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

#include "ZigZagAdapter.mqh"
#include "FastPivot.mqh"   // быстрый приблизительный расчёт (fallback)
#include "SimpleSwing.mqh"

class MarketData; // forward decl
class MFVConfig;  // forward decl

struct DualPivot
  {
   double   High;
   double   Low;
   int      lastSwing;
   datetime ts;

   DualPivot(){ High=0.0; Low=0.0; lastSwing=0; ts=0; }
   DualPivot(const DualPivot &o){ High=o.High; Low=o.Low; lastSwing=o.lastSwing; ts=o.ts; }
  };

class PivotEngine {
   MarketData *md; MFVConfig *cfg;
   ZigZagAdapter zz;
   DualPivot m_h1, m_m15, m_m5;
   // Последние вычисленные пивоты по каждому ТФ.
   // Используются как мгновенный источник значений при старте/переключении ТФ.
   DualPivot cacheM5, cacheM15, cacheH1, cacheH4, cacheD1;
   // Время последнего обновления кэша по каждому ТФ (для троттлинга/диагностики)
   datetime tsM5, tsM15, tsH1, tsH4, tsD1;
 public:
   void Init(MarketData *m, MFVConfig *c){ md=m; cfg=c; zz.Init(_Symbol, cfg); }
   // Back-compat для существующих вызовов с ссылками
   void Init(MarketData &m, MFVConfig &c){ Init(&m, &c); }
   void UpdateAllTF(){
      zz.EnsureAll();
      m_h1 = computeForTf(PERIOD_H1);
      m_m15 = computeForTf(PERIOD_M15);
      m_m5 = computeForTf(PERIOD_M5);
   }
   DualPivot Get(ENUM_TIMEFRAMES tf) const {
      if(tf==PERIOD_H1) return m_h1;
      if(tf==PERIOD_M5) return m_m5;
      return m_m15;
   }
   // быстрый геттер для произвольного TF без хранения
   DualPivot ComputeNow(ENUM_TIMEFRAMES tf) { return computeForTf(tf); }

   // Отдать закэшированный пивот (может быть пустым, если ещё не считали)
   DualPivot Cached(const ENUM_TIMEFRAMES tf) const
     {
      switch(tf)
        {
         case PERIOD_M5:  return cacheM5;
         case PERIOD_M15: return cacheM15;
         case PERIOD_H1:  return cacheH1;
         case PERIOD_H4:  return cacheH4;
         case PERIOD_D1:  return cacheD1;
        }
      return DualPivot();
     }

   // Вспомогательный ключ для Global Variables: MFV:<SYMBOL>:<TF>:<TAG>
   string key(const string sym, ENUM_TIMEFRAMES tf, const string tag) const
     {
      return "MFV:" + sym + ":" + IntegerToString((int)tf) + ":" + tag;
     }

   // Сохранить кэш в Global Variables, чтобы при следующем запуске отобразить пивоты мгновенно
   void SaveCacheGV(const string sym) const
     {
      const ENUM_TIMEFRAMES tfs[] = {PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i=0;i<ArraySize(tfs);++i)
        {
         DualPivot d = Cached(tfs[i]);
         GlobalVariableSet(key(sym,tfs[i],"H"),  d.High);
         GlobalVariableSet(key(sym,tfs[i],"L"),  d.Low);
         GlobalVariableSet(key(sym,tfs[i],"TS"), (double)d.ts);
        }
     }

   // Загрузить кэш из Global Variables. Значения могут быть пустыми (0), это допустимо.
   void LoadCacheGV(const string sym)
     {
      const ENUM_TIMEFRAMES tfs[] = {PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i=0;i<ArraySize(tfs);++i)
        {
         DualPivot d;
         d.High = (double)GlobalVariableGet(key(sym,tfs[i],"H"));
         d.Low  = (double)GlobalVariableGet(key(sym,tfs[i],"L"));
         d.ts   = (datetime)(long)GlobalVariableGet(key(sym,tfs[i],"TS"));
         switch(tfs[i])
           {
            case PERIOD_M5:  cacheM5  = d; tsM5=d.ts; break;
            case PERIOD_M15: cacheM15 = d; tsM15=d.ts; break;
            case PERIOD_H1:  cacheH1  = d; tsH1=d.ts; break;
            case PERIOD_H4:  cacheH4  = d; tsH4=d.ts; break;
            case PERIOD_D1:  cacheD1  = d; tsD1=d.ts; break;
           }
        }
     }

   // Готов ли индикаторный хендл для данного TF? Полезно, чтобы понимать,
   // можем ли сейчас дергать онлайн-расчёт, или лучше показать кэш.
   bool Ready(const ENUM_TIMEFRAMES tf)
     {
      int h = zz.Handle(tf);
      if(h==INVALID_HANDLE) h = zz.Ensure(tf);
      if(h==INVALID_HANDLE) return false;
      return (BarsCalculated(h) >= 0);
     }

   // Прогреть все TF через адаптер (вызывать из OnInit)
   void PreWarmAll() { zz.PreWarmAll(); }
 private:
   DualPivot computeForTf(ENUM_TIMEFRAMES tf)
   {
      DualPivot dp; // по умолчанию нули

      // 1) Онлайн ZigZag (если хендл готов) → читаем буферы и обновляем кэш
      if(cfg!=NULL && cfg.PivotAlgorithm==Pivot_ZigZag)
      {
         int h = zz.Handle(tf);
         if(h==INVALID_HANDLE) h = zz.Ensure(tf); // попытка создать хендл, если его ещё нет
         int bc = (h==INVALID_HANDLE ? -1 : BarsCalculated(h));
         // избегаем блокировок и долгих расчётов, пока индикатор «тёплый»
         if(h != INVALID_HANDLE && bc >= 10)
         {
            const int N = 300;
            // ZigZag_Fixed: SetIndexBuffer(0=main,1=HighMap,2=LowMap)
            const int BUF_ZZ = 0, BUF_HIGH = 1, BUF_LOW = 2;
            double highBuf[]; double lowBuf[];
            ArraySetAsSeries(highBuf, true); ArraySetAsSeries(lowBuf, true);
            int hc = CopyBuffer(h, BUF_HIGH, 1, N, highBuf);
            int lc = CopyBuffer(h, BUF_LOW,  1, N, lowBuf);
            if(hc>0 || lc>0)
            {
               double pivotH = 0.0, pivotL = 0.0;
               int shiftH = 0, shiftL = 0;
               bool foundH = false, foundL = false;
               // ZigZag кладёт 0.0 при отсутствии точки, поэтому проверяем > 0.0
               for(int i=0; i<hc; ++i){ if(highBuf[i] > 0.0){ pivotH = highBuf[i]; shiftH = 1+i; foundH=true; break; } }
               for(int i=0; i<lc; ++i){ if(lowBuf[i]  > 0.0){ pivotL = lowBuf[i];  shiftL = 1+i; foundL=true; break; } }

               if(foundH || foundL)
               {
                  int ls = 0; // last swing sign
                  if(foundH && foundL){ if(shiftH < shiftL) ls = +1; else if(shiftL < shiftH) ls = -1; else ls = 0; }
                  else if(foundH) ls = +1;
                  else if(foundL) ls = -1;

                  int shiftTs = 0;
                  if(foundH && foundL) shiftTs = (shiftH < shiftL ? shiftH : shiftL);
                  else if(foundH) shiftTs = shiftH;
                  else if(foundL) shiftTs = shiftL;

                  datetime ts = (shiftTs>0 ? iTime(_Symbol, tf, shiftTs) : (datetime)TimeCurrent());

                  // Упаковать результат и положить в кэш для данного TF
                  DualPivot out;
                  out.High      = pivotH;
                  out.Low       = pivotL;
                  out.lastSwing = ls;
                  out.ts        = ts;

                  switch(tf)
                    {
                     case PERIOD_M5:  cacheM5  = out; tsM5 = ts; break;
                     case PERIOD_M15: cacheM15 = out; tsM15= ts; break;
                     case PERIOD_H1:  cacheH1  = out; tsH1 = ts; break;
                     case PERIOD_H4:  cacheH4  = out; tsH4 = ts; break;
                     case PERIOD_D1:  cacheD1  = out; tsD1 = ts; break;
                    }

                  return out;
               }
            }
         }
      }

      // 2) Кэш (если есть значения) → мгновенно отдаём в UI
      {
         DualPivot c = Cached(tf);
         if(c.High>0.0 || c.Low>0.0)
            return c;
      }

      // 3) Быстрый приблизительный расчёт (FastPivot) → тёплый старт
      {
         // FastPivot теперь отдаёт только High/Low/time без знания DualPivot.
         double fh=0.0, fl=0.0; datetime fts=0;
         if(md!=NULL && cfg!=NULL && FastPivot::Compute(tf, *cfg, *md, fh, fl, fts))
         {
            DualPivot fp; fp.High = fh; fp.Low = fl; fp.ts = fts; fp.lastSwing = 0;
            // Заполнить lastSwing эвристикой: какой уровень ближе к текущей цене.
            int inferred = 0;
            if(fp.High>0.0 || fp.Low>0.0)
              {
               const double px = iClose(_Symbol, tf, 1);
               if(fp.High>0.0 && fp.Low>0.0)
                  inferred = (MathAbs(px - fp.High) <= MathAbs(px - fp.Low)) ? +1 : -1;
               else if(fp.High>0.0)
                  inferred = +1;
               else if(fp.Low>0.0)
                  inferred = -1;
              }
            fp.lastSwing = inferred;   // теперь TrendEngine сможет дать направление
            // записать в кэш
            switch(tf){
              case PERIOD_M5:  cacheM5  = fp; break;
              case PERIOD_M15: cacheM15 = fp; break;
              case PERIOD_H1:  cacheH1  = fp; break;
              case PERIOD_H4:  cacheH4  = fp; break;
              case PERIOD_D1:  cacheD1  = fp; break;
            }
            return fp;
         }
      }

      // Нет онлайн-значений и быстрый расчёт не дал результата — отдаём пустой dp
      return dp;
   }
};

#endif // __MFV_PIVOTENGINE_MQH__
