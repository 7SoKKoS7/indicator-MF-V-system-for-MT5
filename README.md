# MasterForex-V Indicator for MetaTrader 5

## 📈 Overview

This indicator implements core elements of the MasterForex-V strategy using multi-timeframe ZigZag-based pivot analysis and trend confirmation logic.

It analyzes price action on **M5**, **M15**, and **H1** timeframes to determine MF-pivot points and assess trend direction. Signals are generated when trend directions across all selected timeframes align. Additional pivot levels from **H4** and **D1** are used for context.

---

## ✅ Implemented Features

- MF-pivot levels for M5, M15, H1 (confirmed ZigZag extremums)
- Trend direction display for each timeframe (↑ / ↓)
- Arrow signals when M5 + M15 + H1 trends align
- Early signal (M5 + H1 only)
- Reversal and exit markers
- Persistent historical arrows for backtesting
- Horizontal pivot levels for all TFs: M5–D1
- English-only trend status display

---

## 🛠️ Fixed / Improved

- ✅ Avoids unconfirmed ZigZag pivot (bar 0)
- ✅ Reuses ZigZag handles (performance improved)
- ✅ `OnDeinit()` clears handles and objects
- ✅ Adjustable ZigZag parameters and arrow offset
- ✅ Tolerance relative to `Point` (symbol precision)
- ✅ Auto-removal of classic pivot lines (memory-friendly)
- ✅ Logging added (future visualization of stats)
- ✅ English-only interface (removed Russian text)

---

## 🔁 Versions

- `MasterForex_Pivot_my_v3.mq5` – base logic (legacy)
- `MasterForex_Pivot_my_v4.mq5` – added confirmed pivot
- `MasterForex_Pivot_my_v5.mq5` – added early, exit, reversal, journal
- `MasterForex_Pivot_my_v6.mq5` – interface cleanup (EN only), finalization

---

## 🔬 Backtesting Setup

### EUR/USD Historical CSVs
- `EURUSDM1.csv`
- `EURUSDM5.csv`
- `EURUSDM15.csv`
- `EURUSDH1.csv`
- `EURUSDH4.csv`
- `EURUSDDaily.csv`
- `EURUSDWeekly.csv`
- `EURUSDMonthly.csv`

📷 Screenshot example:
- `пример графика как сейчас работает.png`

📊 Test output (pending): signal stats by version and timeframe

---

## 📚 Documentation

- 📖 [MasterForex-V Book 2 (official site)](https://www.masterforex-v.org/mf_books/book2.html)
- 📖 [MasterForex-V Book 3 (in repo)](https://github.com/7SoKKoS7/indicator-MF-V-system-for-MT5/blob/main/%D0%BA%D0%BD%D0%B8%D0%B3%D0%B0%203.pdf)

---

## 🧪 Strategy Testing via Codex or Python (if MT5 not available)

If environment cannot run `.mq5` directly:
1. Use embedded CSV test data
2. Apply pivot/trend rules from indicator logic (e.g. `GetLastPivot`)
3. Use Python or Codex logic to simulate signals
4. Generate match rate, signal quality, precision stats

---

## 🔧 Roadmap

- [x] Confirmed pivot only
- [x] Historical arrow rendering
- [x] Signal journaling
- [x] Trend panel cleanup
- [ ] Auto signal stats reporting
- [ ] Visual performance dashboard
- [ ] Strategy comparison with EMA/RSI or BB+Candles

---

✅ Last updated: **v6**  
📅 Date: **2025-08-03**

---

## 🧠 Goal

Bring the MasterForex-V methodology into programmable reality for backtesting, signal automation, and cross-strategy validation in real-time or offline.

