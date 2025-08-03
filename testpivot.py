import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import argparse

DATA_FILES = {
    'M5': 'EURUSDM5.csv',
    'M15': 'EURUSDM15.csv',
    'H1': 'EURUSDH1.csv',
    'H4': 'EURUSDH4.csv',
    'D1': 'EURUSDDaily.csv',
}

def load_data(tf: str) -> pd.DataFrame:
    path = Path(__file__).resolve().parents[1] / DATA_FILES[tf]
    df = pd.read_csv(path, names=["time","open","high","low","close","tick_volume","real_volume"],
                     parse_dates=["time"], encoding='utf-16')
    df.sort_values('time', inplace=True)
    df.reset_index(drop=True, inplace=True)
    return df

def zigzag(df: pd.DataFrame, deviation: float = 0.0005) -> pd.DataFrame:
    pivots = []
    last_pivot_price = df['close'].iloc[0]
    last_pivot_idx = 0
    direction = 0
    for i, price in enumerate(df['close']):
        if direction == 0:
            if abs(price - last_pivot_price) > deviation:
                direction = 1 if price > last_pivot_price else -1
                last_pivot_price = price
                last_pivot_idx = i
                pivots.append((i, price))
        elif direction == 1:
            if price > last_pivot_price:
                last_pivot_price = price
                last_pivot_idx = i
            elif (last_pivot_price - price) > deviation:
                pivots.append((last_pivot_idx, last_pivot_price))
                direction = -1
                last_pivot_price = price
                last_pivot_idx = i
        else:
            if price < last_pivot_price:
                last_pivot_price = price
                last_pivot_idx = i
            elif (price - last_pivot_price) > deviation:
                pivots.append((last_pivot_idx, last_pivot_price))
                direction = 1
                last_pivot_price = price
                last_pivot_idx = i
    pivots.append((last_pivot_idx, last_pivot_price))
    df['pivot'] = np.nan
    for idx, price in pivots:
        df.at[idx, 'pivot'] = price
    return df

def generate_signals(df: pd.DataFrame):
    signals = []
    position = None
    entry_price = 0.0
    profits = []
    last_pivot_idx = None
    for i in range(len(df)):
        if not np.isnan(df['pivot'].iloc[i]):
            if last_pivot_idx is None:
                signals.append(('EARLY', df['time'].iloc[i], df['close'].iloc[i], None))
            else:
                prev = df['pivot'].iloc[last_pivot_idx]
                curr = df['pivot'].iloc[i]
                if curr > prev:
                    signals.append(('STRONG_BUY', df['time'].iloc[i], df['close'].iloc[i], None))
                    if position == 'SHORT':
                        profit = entry_price - df['close'].iloc[i]
                        profits.append(profit)
                        signals.append(('EXIT', df['time'].iloc[i], df['close'].iloc[i], profit))
                        position = None
                    position = 'LONG'
                    entry_price = df['close'].iloc[i]
                elif curr < prev:
                    signals.append(('STRONG_SELL', df['time'].iloc[i], df['close'].iloc[i], None))
                    if position == 'LONG':
                        profit = df['close'].iloc[i] - entry_price
                        profits.append(profit)
                        signals.append(('EXIT', df['time'].iloc[i], df['close'].iloc[i], profit))
                        position = None
                    position = 'SHORT'
                    entry_price = df['close'].iloc[i]
            last_pivot_idx = i
    success = sum(p > 0 for p in profits)
    total = len(profits)
    stats = {
        'signals': len([s for s in signals if s[0].startswith('STRONG')]),
        'successful': success,
        'success_rate': (success / total * 100) if total else 0.0,
        'pl': sum(profits)
    }
    return signals, stats

def plot(df: pd.DataFrame, signals, tf: str, outdir: Path):
    plt.figure(figsize=(10,4))
    plt.plot(df['time'], df['close'], label='Close')
    plt.scatter(df.index[df['pivot'].notna()], df['pivot'].dropna(), color='orange', s=20, label='Pivot')
    for typ, t, p, _ in signals:
        if typ == 'STRONG_BUY':
            plt.scatter(t, p, marker='^', color='green')
        elif typ == 'STRONG_SELL':
            plt.scatter(t, p, marker='v', color='red')
        elif typ == 'EXIT':
            plt.scatter(t, p, marker='x', color='gray')
    plt.title(f'MF-V Emulator {tf}')
    plt.legend()
    outdir.mkdir(parents=True, exist_ok=True)
    plt.savefig(outdir / f'{tf}.png')
    plt.close()

def run(timeframes):
    summaries = []
    outdir = Path('backtest') / 'figures'
    for tf in timeframes:
        df = load_data(tf)
        df = zigzag(df)
        signals, stats = generate_signals(df)
        plot(df, signals, tf, outdir)
        summaries.append((tf, stats))
        print(f"{tf}: signals={stats['signals']} success={stats['success_rate']:.1f}% PL={stats['pl']:.5f}")
    return summaries

def main():
    parser = argparse.ArgumentParser(description='MF-V indicator emulator based on CSV data.')
    parser.add_argument('--timeframes', nargs='+', default=['M5','M15','H1','H4','D1'])
    args = parser.parse_args()
    run(args.timeframes)

if __name__ == '__main__':
    main()