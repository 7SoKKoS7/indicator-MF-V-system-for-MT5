# MasterForex-V MultiTF Indicator for MetaTrader 5

## Описание

Индикатор MasterForex-V MultiTF - это профессиональный инструмент для анализа рынка, основанный на стратегии MasterForex-V. Индикатор использует мультитаймфреймовый анализ и систему MF-pivot для генерации торговых сигналов.

## Особенности

### Основные функции:
- **Мультитаймфреймовый анализ** (M5, M15, H1, H4, D1)
- **Система MF-pivot** с оптимизированным алгоритмом ZigZag
- **Анализ объема на 3 таймфреймах** (M5, M15, H1)
- **Фильтр торговых сессий** (Лондон, Нью-Йорк, Токио)
- **Система силы тренда** (1-3 балла)
- **Информационная панель** с детальной статистикой
  - [Новый v9] Постоянный кэш MF‑pivot между переключениями ТФ (глобальные переменные терминала)
  - [Новое] RETEST‑движок (M15/M5) с буферами по ATR/NOISE, метками OK/FAIL и TTL
  - [Новое] Устойчивое определение тренда M15/M5 по закрытым барам (dual‑pivot + ATR‑толеранс + fallback)
  - Дополнительно доступен советник (EA) на основе индикатора для автоторговли

### Типы сигналов:
- **🟡 Сильные сигналы** (сила тренда 3/3) - желтые стрелки
- **🟢 Обычные сигналы покупки** (сила тренда 1-2/3) - зеленые стрелки
- **🔴 Обычные сигналы продажи** (сила тренда 1-2/3) - красные стрелки
- **🔵 Ранние сигналы** (частичное совпадение) - голубые стрелки
- **❌ Сигналы выхода** (пересечение pivot) - серые крестики
- **🔄 Сигналы разворота** (изменение тренда) - аква стрелки

## Алгоритм работы

### Система силы тренда:
- **3/3** - очень сильный тренд (желтые стрелки)
- **2/3** - сильный тренд (зеленые/красные стрелки)
- **1/3** - слабый тренд (ранние сигналы)

### Анализ объема на 3 таймфреймах:
- **M5** - анализ объема на 5-минутном таймфрейме
- **M15** - анализ объема на 15-минутном таймфрейме
- **H1** - анализ объема на часовом таймфрейме
- **Требование:** минимум 2 из 3 таймфреймов должны подтвердить объем
- **Используются завершенные бары** для точности анализа

### Фильтры качества:
- **Объем подтвержден** (минимум 2/3 таймфреймов)
- **Валидная торговая сессия** (Лондон, Нью-Йорк, Токио)
- **Минимальная сила тренда** (настраивается)

## Настройки

### Основные настройки:
```mql5
input bool   UseRussian = false;              // Подписи на русском языке
input bool   ShowClassicPivot = true;         // Показывать классические уровни Pivot
input bool   ShowStatusInfo = true;           // Показывать информацию о статусе
input bool   EnableVolumeFilter = true;       // Фильтр по объему
input bool   EnableSessionFilter = true;      // Фильтр торговых сессий
```

### Пивоты High/Low и ТФ:
```mql5
input bool   ShowPivotHighLow = true;         // Рисовать Pivot High/Low на всех ТФ
input bool   UseTF_H4 = true;                 // Использовать H4 dual‑pivot (по умолчанию включено)
input bool   UseTF_D1 = true;                 // Использовать D1 dual‑pivot (по умолчанию включено)
```

### Настройки ZigZag:
```mql5
input int    InpDepth = 12;                   // Глубина ZigZag
input double InpDeviation = 5.0;              // Отклонение в пунктах
input double AtrDeviationK = 0.0;             // Коэф. ATR для адаптивного порога (0=выкл)
```
Дополнительно доступны отдельные параметры на каждый ТФ для устойчивости свингов на старших ТФ:
```mql5
input int    Depth_M5  = 12,  Depth_M15 = 12,  Depth_H1 = 12,  Depth_H4 = 12,  Depth_D1 = 12;
input double Dev_M5    = 5.0, Dev_M15   = 7.0, Dev_H1   = 12.0, Dev_H4   = 20.0, Dev_D1   = 30.0;
```

### RETEST (буферы и визуализация)
```mql5
// === Retest Settings ===
input int    ATR_Period         = 14;
input double NoisePips_Override = 0.0;  // 0 — AUTO NOISE
input double BreakBuf_ATR_Frac  = 0.25;
input double RetestTol_ATR_Frac = 0.20;
input double BreakBuf_NoiseMul  = 1.0;
input double RetestTol_NoiseMul = 0.8;
input int    Retest_MaxBars     = 3;
input int    Label_TTL_Bars     = 6;
input bool   NewsMode           = false;
input double NewsMode_Mul       = 2.5;
```
Логика: пробой фиксируется на закрытом баре TF (`Close[1]`), ретест ищется в окне `k<=Retest_MaxBars`, метки `RETEST OK/FAIL`, линия pivot окрашивается (WAIT/OK/FAIL), новости масштабируют буферы (NEWS xK в заголовке панели).

### Размеры/цвета и отображение стрелок:
```mql5
// Цвета стрелок
input color  BuyArrowColor = clrLime;
input color  SellArrowColor = clrRed;
input color  EarlyBuyColor = clrDodgerBlue;
input color  EarlySellColor = clrDeepSkyBlue;
input color  ExitColor = clrGray;
input color  ReverseColor = clrAqua;
input color  StrongSignalColor = clrYellow;
input color  EarlyExitColor = clrSandyBrown;

// Размеры
input int    ArrowWidth = 2;                  // Толщина стрелок
input int    ArrowOffset = 10;                // Смещение стрелок в пунктах

// Отображение (визуальные фильтры)
input bool   ShowStrongSignals  = true;       // Показывать сильные (жёлтые) входы
input bool   ShowNormalSignals  = true;       // Показывать обычные входы
input bool   ShowEarlySignals   = true;       // Показывать ранние входы
input bool   ShowExitSignals    = true;       // Показывать выходы/ранние выходы
input bool   ShowReversalSignals= true;       // Показывать развороты
 input bool   ShowHistorySignals = true;       // Отображать сохранённые реальные стрелки в истории
 input int    SignalsLookbackBars= 500;        // Ограничение глубины отображаемой истории
input int    MinBarsBetweenArrows = 6;        // Минимум баров между одинаковыми стрелками
```

### Цвета Pivot High/Low:
```mql5
input color  PivotHighColor = clrRed;         // Цвет Pivot High (сопротивление)
input color  PivotLowColor  = clrLime;        // Цвет Pivot Low  (поддержка)
```

### Dual‑pivot MF‑pivots (High/Low)
- Для каждого ТФ (H1, M15, M5; опционально H4, D1) рассчитываются два подтверждённых уровня: `PivotHigh_TF` и `PivotLow_TF` из стандартного ZigZag.
- Подтверждение только на закрытых барах: текущий бар исключён. Никакого репейнта.
- Порог ZigZag адаптируется: `max(Dev_TF*_Point, AtrDeviationK*ATR(tf,14))` при `AtrDeviationK>0`. Используются отдельные `Depth_*`/`Dev_*` по ТФ.
- Кэш накапливает последнее подтверждённое High/Low, противоположная сторона не затирается нулями.

#### Тренд от dual‑pivot
- Up: если `Close_TF[1] > PivotLow_TF` и последний swing = Up.
- Down: если `Close_TF[1] < PivotHigh_TF` и последний swing = Down.
- Иначе — Flat (между H/L или ближе, чем толеранс `max(2*_Point, 0.1*ATR(H1))`).

### Настройки сессий:
```mql5
input int    SessionGMTOffset = 2;            // Смещение серверного времени относительно GMT (пример: 2 для GMT+2)
```
- Опция `UseDST = true` — авто‑поправка на летнее время (Европа: с последнего воскресенья марта по последнее воскресенье октября).
- Окна сессий заданы в GMT: Лондон 8–16, Нью‑Йорк 13–21, Токио 0–8.
- Время берётся с сервера брокера (`TimeTradeServer()`), переводится в GMT как `hourGMT = hourServer - (SessionGMTOffset + (UseDST?1:0) в летний период)`.
- Автокоррекции под DST нет — `SessionGMTOffset` переключается пользователем вручную (часто 2 зимой, 3 летом).
- Пример: Market Watch 22:40, локально Нидерланды 21:40 (UTC+2) → сервер ~UTC+3 → `SessionGMTOffset = 3`.

### Фильтры MasterForex-V:
```mql5
input double MinVolumeMultiplier = 1.2;       // Минимальный множитель объема
input int    MinTrendStrength = 2;            // Минимальная сила тренда (1-3)
input int    MinEarlyTrendStrength = 1;       // Минимальная сила тренда для ранних входов (1-3)
// Зарезервировано под будущее EA (не влияет на индикатор):
input bool   UseRiskManagement = true;
input double MaxRiskPercent = 2.0;
```

### Clinch (схватка) вокруг dual‑pivot H1
```mql5
input bool   UseClinchFilter   = true;        // Включить фильтр «схватки»
input double ClinchAtrK        = 0.50;        // Полуширина зоны: k * ATR(H1)
input int    ClinchLookbackH1  = 24;          // Сколько H1-баров анализировать
input int    ClinchFlipsMin    = 3;           // Минимум перебросов через pivotH1
input double ClinchRangeMaxATR = 1.20;        // Макс. диапазон за Lookback в ATR(H1)
input bool   ShowClinchZoneOnlyIfTouched = true; // Показывать зону только если цена заходила в неё за Lookback
```
- Зона clinch — коридор между `PivotLow_H1` и `PivotHigh_H1` (визуально прямоугольник). Для статистики перебросов используется средняя линия коридора.
- Дополнительно доступен режим `Clinch_ATR_Midline`: `mid=(H+L)/2`, `zone=mid±ClinchAtrK*ATR(H1)`.
- Признак clinch: частые перебросы цены внутри коридора (по Close H1) и сжатый диапазон: `max(high)−min(low)` за `ClinchLookbackH1` ≤ `ClinchRangeMaxATR * ATR(H1)`.
- В clinch понижается класс сигналов: сильные → обычные, обычные → ранние, ранние → блок.
- В панели отображается строка: `Clinch: ✓/✗, flips=X, range=Y ATR, band=H/L` или `zone=±K ATR` в зависимости от режима.
> Примечание по Risk Management: параметры `UseRiskManagement` и `MaxRiskPercent` зарезервированы для будущего советника (EA). В текущем индикаторе они не задействованы и не влияют на расчёт сигналов.

### Строгая политика «no repaint» и устойчивость
- Все решения принимаются на закрытых барах; в логике используется цена `Close[1]` текущего ТФ.
- Тренд‑толеранс независим от ZigZag: `tol = max(2*_Point, TrendTolAtrK*ATR(H1))`.
- Подтверждение пробоя H1: для покупок — относительно `PivotHigh_H1`, для продаж — относительно `PivotLow_H1`; ретест ищется строго ПОСЛЕ закрытия часа (`fromTime = iTime(H1,1) + PeriodSeconds(H1)`).
- Clinch рассчитывается по закрытым H1‑барам; визуальная зона строится с тем же ATR, что применялся при детекции (заморозка ATR).
- Выходы (включая Soft/Hard) сравнивают только закрытую цену бара; никаких проверок по `Close[0]`.
- В режиме `Exit_Nearest` «ближайший» pivot определяется относительно цены на баре входа, а не текущей.

### Подтверждение пробоя Pivot (H1)
```mql5
enum ConfirmMode { Confirm_Off, Confirm_StrongOnly, Confirm_StrongAndNormal, Confirm_All };
input ConfirmMode BreakoutConfirm = Confirm_StrongOnly; // Режим подтверждения

input int    H1ClosesNeeded       = 2;     // сколько H1‑закрытий за pivot
input int    RetestWindowM15      = 12;    // окно ретеста в M15‑барах (до 3 ч)
input double RetestTolATR_M15     = 0.25;  // допуск касания: ±0.25*ATR(M15)
input double WickRejectMin        = 0.60;  // доля тени в диапазоне бара (отскок)
input bool   UseRetestVolume      = true;  // учитывать объём на ретесте
input double RetestVolMult        = 1.20;  // объём ретеста > 1.2× среднего
input bool   RetestAllowM5        = true;  // ретест может быть и на M5
input int    RetestWindowM5       = 36;    // окно ретеста в M5‑барах (~3 ч)
input double RetestTolATR_M5      = 0.35;  // допуск касания для M5
```
- Strong по умолчанию требует: 2 закрытия H1 за pivot в сторону входа И ретест уровня на M15 (по желанию также M5) с отскоком (тень) и (опционально) объёмом.
- Normal: достаточно 1 закрытия H1 за pivot; если подтверждения нет — сигнал будет понижен до Early.
- Early: остаётся без подтверждений.
- Режим задаётся `BreakoutConfirm`: можно применить правило только к Strong (по умолчанию), к Strong+Normal, ко всем или выключить.
- При активной «схватке» (clinch) дополнительное подтверждение не требуется — класс уже понижается фильтром clinch.

## Информационная панель

Индикатор отображает детальную информацию:

 - **Тренд H1: ↑ M15: ↑ M5: ↑** - направления трендов
 - **Pivot H1: H=1.23456 | L=1.22345**
 - **Pivot M15: H=... | L=...**
 - **Pivot M5: H=... | L=...**
- **Сила тренда: 3/3** - оценка силы тренда (1-3 балла)
- **Объем M5:✓ M15:✓ H1:✓ (3/3)** - подтверждение объема на 3 таймфреймах
- **Сессия: ✓** - валидность торговой сессии
- **RT: OK|WAIT|FAIL | buf=XX pips | tol=YY pips** — статус ретеста и активные буферы

Дополнительно (если включено в настройках):
 - **Clinch:** `✓/✗, flips=X, range=Y ATR, band=H/L` — статус «схватки» в коридоре `PivotLow_H1..PivotHigh_H1` (по закрытым барам H1).
- **Фаза:** `Trend/Flat` — детектор рыночной фазы по качелям на M15; во флете сигналы даунгрейдятся до Early.
- **Consensus:** `2/3 ✓ | EMA:↑|↓|– | RSI: ✓|✗` — голосование MF‑ядро/EMA/RSI. Режим управляется `Consensus` (PanelOnly/Gate*/BlockAll).
- **Сигнал:** `Strong BUY/Strong SELL/BUY/SELL/Early BUY/Early SELL/Early EXIT/HARD EXIT/Reversal` — текущий статус сигнала.

## Логика сигналов

### Сильные сигналы (желтые стрелки):
- ✅ **Все 3 таймфрейма совпадают** (H1, M15, M5)
- ✅ **Сила тренда = 3/3** (максимальная)
- ✅ **Объем подтвержден** (минимум 2/3 таймфреймов)
- ✅ **Валидная торговая сессия**
 - ✅ (если включено `BreakoutConfirm`) **Пробой с закреплением**: `H1ClosesNeeded` закрытий за pivot + **ретест** pivot на M15/M5 с отскоком (тенью) и, при `UseRetestVolume=true`, объёмом ≥ `RetestVolMult`×среднего.

### Обычные сигналы (зеленые/красные стрелки):
- ✅ **Все 3 таймфрейма совпадают** (H1, M15, M5)
- ⚠️ **Сила тренда = 1-2/3** (средняя)
- ✅ **Объем подтвержден** (минимум 2/3 таймфреймов)
- ✅ **Валидная торговая сессия**
 - ⚠️ (если включено применение к Normal) без подтверждения пробоя по H1 — сигнал автоматически понижается до Early.

### Ранние сигналы (голубые стрелки):
- ⚠️ **Частичное совпадение** (H1 и M5, но НЕ M15)
- ⚠️ **Слабая сила тренда** — порог задаётся `MinEarlyTrendStrength` (по умолчанию 1/3)
- ✅ **Объем подтвержден** (минимум 2/3 таймфреймов)
- ✅ **Валидная торговая сессия**

### Импульс‑откат (MF A‑B‑C) для повышения/понижения класса
- На M15, в направлении тренда H1, распознаётся структура A‑B‑C:
  - Импульс «здоровый», если отношение `|B−A| / |C−B| ≥ ImpulseMinRatio` (по умолчанию 1.5).
  - Глубина отката оценивается как доля `|C−B| / |B−A|` и сравнивается с `PullbackMaxFib` (по умолчанию 0.618).
- Правила ап/даун‑грейда:
  - Если импульс «здоровый» — ранний сигнал (Early) апгрейдится до обычного (Normal).
  - Если откат слишком глубокий — обычный сигнал (Normal) понижается до раннего (Early) или игнорируется (по желанию, сейчас понижение).

Настройки:
```mql5
input bool   UseImpulseFilter     = true;   // Включить фильтр импульса/отката
input double ImpulseMinRatio      = 1.5;    // |B−A| / |C−B| минимум
input double PullbackMaxFib       = 0.618;  // макс. глубина отката (доля импульса)
input int    ImpulseBackWindowM15 = 48;     // поиск A перед B (M15‑баров)
input int    PullbackWindowM15    = 12;     // поиск C после B (M15‑баров)
```

### Фильтр «рыночной фазы» (Flat/Trend)
Индикатор даунгрейдит сигналы до Early во флете, чтобы соответствовать канону MF‑V (работать в тренде).
- Детекция: по трём последним качелям на M15. Вычисляем длины трёх колен, считаем отношения и берём медиану.
- Если медиана < `FlatMedianThreshold` (дефолт 1.20) — флет: разрешены только ранние входы. Панель показывает строку `Phase: Flat/Trend`.
```mql5
input bool   UseMarketPhaseFilter = true;   // Включить фильтр флет/тренд
input double FlatMedianThreshold  = 1.20;   // Порог медианы соотношений качелей (ниже — флет)
```

### Сигналы выхода (серые крестики):
- ❌ **Жёсткий выход (hard):** по умолчанию — для Long закрытие ниже `PivotLow_H1`, для Short — выше `PivotHigh_H1`.
- ℹ️ Индикатор также показывает метку разворота (аква), когда меняется направление тренда на H1 и M15.

### Режимы выхода (ExitMode)
```mql5
enum ExitMode { Exit_H1, Exit_EntryTF, Exit_Nearest, Exit_SoftHard };
input ExitMode ExitLogic = Exit_H1;           // дефолт: H1
input double   ExitNearestAtrK = 0.25;        // фильтр близости (в ATR M15) для Nearest
```
- **Exit_H1 (дефолт)**: Long — по `PivotLow_H1`, Short — по `PivotHigh_H1`.
- **Exit_EntryTF**: Long — по `PivotLow_M5`, Short — по `PivotHigh_M5`.
- **Exit_Nearest**: ближайший из `Pivot*_M5/M15/H1` от цены входа с фильтром `ExitNearestAtrK * ATR(M15)`.
- **Exit_SoftHard**: Soft — Long по `PivotLow_M15`, Short по `PivotHigh_M15`; Hard — Long по `PivotLow_H1`, Short по `PivotHigh_H1`.

### Консенсус‑фильтр (опционально)
Идея: у вас три «голоса» — MF‑ядро, EMA‑направление M15, RSI(14) M15. Консенсус «2 из 3» может:
- только показываться на панели,
- даунгрейдить Strong (или Strong/Normal),
- полностью блокировать входы без 2/3.

Настройки:
```mql5
enum ConsensusMode { Cons_Off, Cons_PanelOnly, Cons_GateStrong, Cons_GateStrongNormal, Cons_BlockAll };
input ConsensusMode  Consensus   = Cons_PanelOnly;
input int   EmaFast = 50, EmaSlow = 200;
input double EmaSlopeMin = 0.0;   // минимальный наклон EMA50
input int   RsiPeriod = 14;
input int   RsiOB = 70, RsiOS = 30;
input int   RsiHyst = 5;          // гистерезис
```
- EMA‑голос: `EMA50 > EMA200` (и |наклон| EMA50 ≥ `EmaSlopeMin * ATR(M15)`; при `EmaSlopeMin=0` наклон не проверяется) → buy; `<` → sell; иначе — нейтрально.
- RSI‑голос: buy разрешён, если `RSI ≤ (OB-Hyst)`; sell — если `RSI ≥ (OS+Hyst)`.
- Режимы:
  - Off — ничего не делает.
  - PanelOnly — рисует строку `Consensus: 2/3 ✓ | EMA:↑ | RSI:✓`.
  - GateStrong — без 2/3 Strong → Normal.
  - GateStrongNormal — без 2/3: Strong → Normal, Normal → Early.
  - BlockAll — без 2/3 входы не рисуются.

Порядок применения: Clinch понижает класс → Consensus (если включён) дорабатывает. Early можно оставить как есть, чтобы сохранить «ранний» характер сигналов.

 Панель:
 - Добавлены строки `Phase: Flat/Trend` и единая строка Consensus:
   `Consensus: {votes}/3 {✓|✗} | [H1: {↑|↓|–} {✓|–} | EMA(M15): {↑|↓|–} {✓|✗|–} | RSI(M15): {✓|✗|–}]`
   Наклон EMA трактуется как «пункты цены/бар»: `slopeThresh = EmaSlopeMin * _Point`.
### Сигналы разворота (аква стрелки):
- 🔄 **Изменение направления тренда** на H1 и M15
- 🔄 **Потенциальный разворот** тренда

#### О стратегии выхода
- По умолчанию индикатор следует среднесрочной логике MF‑V: направление задаёт H1, входы — на M5/M15, выход — по pivotH1. Это уменьшает шум и удерживает трендовые хваты.
- Практичные альтернативы (могут быть добавлены как опции в будущем):
  - «По ТФ входа» (чаще M5): более короткий стоп и более быстрые фиксации.
  - «Ближайший pivot (M5/M15/H1)» с фильтром по ATR, чтобы не брать слишком тесные уровни.
  - «Два уровня: мягкий/жёсткий»: soft — по M15 (частичная фиксация/BE), hard — по H1 (полный выход).

## Установка

1. Скопируйте файл `MasterForex_V.mq5` в папку `MQL5/Indicators/`
2. Перезапустите MetaTrader 5
3. Найдите индикатор в списке как "MasterForex-V MultiTF v9.0"
4. Настройте параметры под свои предпочтения

### Советник (EA) для автоторговли

Добавлен файл `MasterForex_V_EA_v82308.mq5` — советник, использующий сигналы индикатора:
- Подключает `MasterForex_Pivot_my_v82308.ex5` через `iCustom` и читает буферы стрелок (Early/Normal/Strong) и выходов.
- Правила лота: ранние входы — половинный лот, обычные — 0.75×, сильные — полный лот (коэффициенты настраиваются).
- При появлении сигнала выхода (крестик) закрывает позицию.
- Работает по закрытым барам текущего таймфрейма.

#### Авто‑SL/TP по методике MasterForex‑V
- Включается опцией `UseAutoSLTP` (по умолчанию включено).
- SL рассчитывается относительно ближайшего подтверждённого pivot: по умолчанию H1, а для ранних входов можно переключить на M15 (`UseM15PivotForEarly`).
- Формула SL: SL = pivot ± (SL_AtrK_H1 × ATR(H1) + SL_ExtraPoints×_Point), в сторону, противоположную сделке.
- Режимы TP (`TakeProfitMode`):
  - `TP_RiskReward` — фиксированное отношение риск/прибыль `TP_RR` (по умолчанию 1:2).
  - `TP_PivotHigher` — цель = ближайший pivot старшего ТФ (H4 приоритетно, затем H1) по направлению сделки.
- Сопровождение: опция `TrailByM15Pivot` подтягивает SL за pivot M15 по мере движения цены.

Параметры EA:
```mql5
input bool     UseAutoSLTP        = true;
input bool     UseM15PivotForEarly= false;
input double   SL_AtrK_H1         = 0.10;   // добавка к SL: k*ATR(H1)
input int      SL_ExtraPoints     = 3;      // запас к SL (пункты 4-знак)
enum TPMode { TP_None, TP_RiskReward, TP_PivotHigher };
input TPMode   TakeProfitMode     = TP_RiskReward;
input double   TP_RR              = 2.0;
input bool     TrailByM15Pivot    = true;
```

Замечание: EA повторяет логику индикатора и использует только закрытые бары; SL/TP динамически подстраиваются под волатильность (ATR) и структуру рынка (pivot).

Установка:
1. Скопируйте `MasterForex_V_EA_v82308.mq5` в `MQL5/Experts/` и скомпилируйте.
2. Убедитесь, что индикатор `MasterForex_Pivot_my_v82308.ex5` лежит в `MQL5/Indicators/`.
3. Накиньте советник на график базового символа (рекомендовано M5). Параметры лота и флаги включения входов/выходов — в настройках EA.

Важное замечание: логика сигналов и фильтров задаётся индикатором. Советник не добавляет собственных фильтров и следует классам сигналов (Early/Normal/Strong).

## Технические особенности

### Оптимизация производительности:
- **Система кэширования** pivot значений
- **Обновление кэша** только при необходимости (раз в минуту). Базовая тройка (H1/M15/M5) должна быть готова; после этого кэш троттлится.
- **Оптимизированные расчеты** ZigZag
- **Использование завершенных баров** для анализа объема
 - **MF‑pivot подтверждается** только при выполнении двух условий: цена прошла `InpDeviation` и прошло минимум `InpDepth` баров с момента последнего кандидата на экстремум.
  - **Глобальный расчёт пивотов**: кэш H1/M15/M5/H4/D1 обновляется на любом открытом таймфрейме, поэтому уровни стабильны при переключениях ТФ.
  - **Warm‑up серий**: при нехватке данных индикатор подкачивает серии (H1/M15/M5). Расчёты не блокируются; недоступные фильтры временно пропускаются. Индикатор рисует только реальные сигналы (историческая дорисовка отключена).
  - **Нормализация входа**: при инициализации подгружается история M5/M15 (до 500 баров) для корректной работы тренда/RETEST по закрытым барам.
  - **Сессии в GMT**: время берётся `TimeTradeServer()` и нормализуется через `SessionGMTOffset`.

### Быстрый старт пивотов (Pivot warm‑up & cache)
- При запуске/смене ТФ индикатор прогревает ZigZag‑хендлы (M5/M15/H1/H4/D1), чтобы сократить задержку.
- Последние вычисленные значения пивотов кешируются в памяти и сохраняются в Global Variables терминала: ключи вида `MFV:<SYMBOL>:<TF>:H|L|TS`.
- При старте/переключении UI сначала показывает кэш, а затем обновляет значения онлайн, когда ZigZag готов.
 - FastPivot отдаёт только High/Low/time и не зависит от PivotEngine, чтобы избежать циклических include. Преобразование в DualPivot выполняется в PivotEngine.
 - Fallback направления: если lastSwing недоступен (быстрый расчёт), направление тренда определяется по положению цены относительно середины между H и L. Как только ZigZag отдаёт полноценные пивоты, направление уточняется.
 - Стрелки выводятся Unicode-символами через `CharToString(0x2191/0x2193)`; для лейблов используется шрифт `Segoe UI Symbol`.
 - Онлайн-расчёт ZigZag запускается только когда `BarsCalculated(h) ≥ 10`; до этого UI использует кэш/fast-fallback.
 - Таймер: `M5/M15/H1 — 1 сек`, `H4 — 2 сек`, `D1 — 5 сек`.

Новые/важные параметры:
- `PanelFontSize`, `PanelYOffset`
- `PanelUseArrows`, `PanelShowStrength` (по умолчанию true)
- `ShowPivotH4`, `ShowPivotD1`
- `PivotColorH`, `PivotColorL`, `PivotLineStyle`, `PivotLineWidth`

Имена графических объектов:
- Линии пивотов: `MFV_Pivot_<TF>_<H|L>` (TF ∈ {M5,M15,H1,H4,D1})
- Панель: `MFV_Panel_Status_<idx>`

Troubleshooting:
- Линии не появились сразу: откройте Ctrl+B и проверьте наличие `MFV_Pivot_*`. Если нет — проверьте путь к `ZigZag_Fixed` и логи терминала.
- Пивоты нули: убедитесь, что ZigZag буферы читаются как `>0.0`, а не `!= EMPTY_VALUE`.

## Соответствие стратегии MasterForex-V:
- **Мультитаймфреймовый анализ** согласно методике
- **Система MF-pivot** с авторским алгоритмом
- **Профессиональные фильтры** качества сигналов
- **Информационная панель** с детальной статистикой
- **Анализ объема на ключевых таймфреймах** (M5, M15, H1)

## Иерархия надежности сигналов

| Тип сигнала | Цвет | Надежность | Рекомендация |
|-------------|------|------------|--------------|
| **Сильный** | 🟡 Желтый | Очень высокая | ✅ Лучший сигнал |
| **Обычный** | 🟢 Зеленый/🔴 Красный | Высокая | ✅ Хороший сигнал |
| **Ранний** | 🔵 Голубой | Средняя | ⚠️ Осторожно |
| **Выход** | ⚫ Серый крестик | Высокая | ❌ Закрыть позицию |
| **Разворот** | 🔵 Аква | Средняя | 🔄 Внимание |

## ATR и единицы

- True Range (TR): `TR_t = max(High_t − Low_t, |High_t − Close_{t−1}|, |Low_t − Close_{t−1}|)`
- ATR Уайлдера за период `N`: `ATR_t = (ATR_{t−1}·(N−1) + TR_t)/N`
- Пипсы: для 5‑знака EURUSD 1 pip = 0.00010; пример: 0.00045 = 4.5 пипса.
- Где используется: фильтр пробоя (требование по ATR), «шумовой» буфер `NOISE = max(Noise_M15×ATR(M15), Noise_H1×ATR(H1))`, стоп‑запасы/толерансы (`TrendTolAtrK`).

На графике показывается один ярлык: `NOISE: 0.00200 (20.0 pips)`; при `ShowDetails=true` ниже выводятся текущие `ATR(M15)`, `ATR(H1)` и используемые множители. Точность управляется `NoiseDecimals`.

## MF‑pivot подтверждение

- Вариант A (фрактал): `left/right` баров вокруг кандидата экстремума.
- Вариант B (ZigZag‑ATR): шаг подтверждения = `ZigZagATR_K × ATR(H1)` между кандидатом и предыдущим противоположным свингом.
- Для H1 подтверждение обязательно; на младших ТФ допускаются ранние (неподтверждённые) метки, но в сигналы они не попадают, пока не будут подтверждены.

## Пробой vs «прокол»

- «Прокол»: касание уровня с закрытием слишком близко к нему (меньше «шума»), такой бар не считается пробоем.
- «Пробой»: закрытие за уровнем на величину ≥ `Breakout_ATR_Mult × ATR(M15)` — причём по `minCloseBars` последовательных закрытиям в сторону пробоя.
- Ретест уровня обязателен: касание уровня (в допуске по ATR) и закрытие «от» уровня на M15 (или M5, если разрешено) с отбрасывающей тенью и, опционально, объёмом ≥ `RetestVolMult`×средний.

## Таблица инпут‑параметров (дефолты и рекомендуемые диапазоны)

| Параметр | Дефолт | Рекомендуемо | Назначение |
|---|---:|---:|---|
| SessionGMTOffset | 2 | 1–4 | Смещение сервера к GMT; с `UseDST=true` +1 летом (Европа) |
| UseDST | true | — | Автопоправка DST (Европа) |
| ATR_Period_M15 / ATR_Period_H1 | 14 / 14 | 10–21 | Периоды ATR для фильтров/шумов |
| Noise_Mult_M15 / Noise_Mult_H1 | 1.2 / 0.6 | 0.6–1.8 | Множители для `NOISE = max(...)` |
| NoiseDecimals | 5 | 4–6 | Округление `NOISE` в цене |
| InpDepth / InpDeviation | 12 / 5.0 | 8–24 / 3–15 | Базовые настройки ZigZag |
| AtrDeviationK | 0.0 | 0.0–0.5 | ATR‑адаптация порога ZigZag |
| Depth_*, Dev_* | 12 / 5–30 | см. ТФ | Параметры ZigZag по ТФ |
| TrendTolAtrK | 0.10 | 0.05–0.20 | Толеранс сравнения Close с pivot |
| UseFractalConfirm, PivotLeftBars, PivotRightBars | true, 2, 2 | 2–3 | Подтверждение фракталом |
| UseZigZagATR, ZigZagATR_K | true, 1.2 | 1.0–2.0 | Альт. подтверждение свинга по ATR |
| Breakout_ATR_Mult, MinCloseBars | 1.0, 1 | 0.5–1.5, 1–2 | Требование к пробою уровня |
| H1ClosesNeeded | 2 | 1–2 | Закрытия H1 за pivot для Strong |
| RetestWindowM15/M5 | 12 / 36 | 8–24 / 24–48 | Окна поиска ретеста |
| RetestTolATR_M15/M5 | 0.25 / 0.35 | 0.2–0.5 | Допуск касания уровня (в ATR) |
| WickRejectMin | 0.60 | 0.5–0.8 | Доля тени от диапазона бара на ретесте |
| UseRetestVolume, RetestVolMult | true, 1.20 | 1.1–1.5 | Проверка объёма на ретесте |
| MinVolumeMultiplier | 1.2 | 1.1–1.6 | Порог подтверждения объёма (2 из 3 ТФ) |
| MinTrendStrength / MinEarlyTrendStrength | 2 / 1 | 1–3 | Порог силы тренда для входов |
| UseImpulseFilter, ImpulseMinRatio, PullbackMaxFib | true, 1.5, 0.618 | 1.2–2.0 / 0.38–0.78 | Фильтр импульс‑откат |
| UseMarketPhaseFilter, FlatMedianThreshold | true, 1.20 | 1.1–1.4 | Даунгрейд сигналов во флете |
| UseClinchFilter, ClinchAtrK, ClinchLookbackH1, ClinchFlipsMin, ClinchRangeMaxATR | true, 0.5, 24, 3, 1.20 | — | Фильтр «схватки» H1 |
| BreakoutConfirm | StrongOnly | Off/StrongOnly/StrongAndNormal/All | Где применять подтверждение пробоя |
| ExitLogic | H1 | EntryTF/Nearest/SoftHard | Режим выхода |

## Мини‑чеклист тестирования

- NOISE‑лейбл показывает число и пипсы; при `ShowDetails=true` — ATR(M15/H1) и множители.
- Сигналы рисуются только на закрытых барах и без дорисовки истории при первом запуске.
- Пробой M5‑pivot требует подтверждения/ретеста согласно настройкам и не срабатывает при «проколе».
- Для H1 подтверждение MF‑pivot обязательно; ранние метки на M15/M5 не превращаются в сигналы без подтверждения.
- В клинче (H1) класс сигналов понижается.

## Ссылки

- [Официальный сайт MasterForex-V](https://www.masterforex-v.org/)
- [GitHub репозиторий](https://github.com/7SoKKoS7/indicator-MF-V-system-for-MT5)

## Лицензия

Индикатор основан на стратегии MasterForex-V и предназначен для образовательных целей.

## Поддержка

Если у вас есть вопросы или предложения по улучшению индикатора, создайте Issue в репозитории.

---

**Версия:** 9  
**Совместимость:** MetaTrader 5  
**Автор:** Основан на стратегии MasterForex-V

## Структура репозитория (модульная ветка)

MQL5/
  Indicators/
    MasterForex_V_legacy.mq5
    MFV_Modular/
      MFV_Modular.mq5
      README.md
      include/
        Config.mqh
        State.mqh
        MarketData.mqh
        PivotEngine.mqh
        TrendEngine.mqh
        Breakout.mqh
        Filters.mqh
        Signals.mqh
        Draw.mqh
        Panel.mqh
        GMLogger.mqh
Docs/
  MFV_Modular_SPEC.md
  MFV_Modular_SPEC.pdf
  MFV_Modular_flow.png
.vscode/
  settings.json
data/
  EURUSDM1.csv
  EURUSDM5.csv
  EURUSDM15.csv
  EURUSDM30.csv
  EURUSDH1.csv
  EURUSDH4.csv
  EURUSDDaily.csv
  EURUSDWeekly.csv
  EURUSDMonthly.csv
.cursorrules
.cursorignore
.gitignore
README.md


### Документация
Все PDF/MD-спеки и схемы лежат в каталоге `/Docs/`.

### Исторические CSV
Все ряды формата `EURUSD*.csv` и подобные храним в `/data/`. Эти файлы игнорируются Cursor согласно `.cursorignore`.