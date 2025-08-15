# MFV_Modular — скелет

Модульная версия индикатора MasterForex-V (MT5). Сейчас реализован каркас без бизнес-логики.

## Структура
- `MFV_Modular.mq5` — точка входа, оркестратор.
- `include/` — модули: Config, State, MarketData, PivotEngine, TrendEngine, Breakout, Filters, Signals, Draw, Panel, GMLogger.

## Сборка
1) Папка `MFV_Modular` должна лежать в `MQL5/Indicators/`.
2) Скомпилировать `MFV_Modular.mq5` в MetaEditor.

## Golden Master лог
CSV-лог включён через `GMLogger` и пишется в общую папку терминала MT5: `MQL5/Files/Common/`.
Отключение: установить `#define MFV_GM_LOG 0` в `include/GMLogger.mqh`.

Подробная спецификация и блок-схема: см. каталог `/Docs/`.


