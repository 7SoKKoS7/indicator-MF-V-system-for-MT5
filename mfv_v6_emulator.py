import pandas as pd
import numpy as np
from pathlib import Path
import argparse

DATA_FILES = {
    'M5': 'EURUSDM5.csv',
    'M15': 'EURUSDM15.csv',
    'H1': 'EURUSDH1.csv'
}

def load_data(tf: str) -> pd.DataFrame:
    path = Path(__file__).resolve().parent / DATA_FILES[tf]
    df = pd.read_csv(path,
                     names=["time","open","high","low","close","tick_volume","real_volume"],
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
    # trend based on last confirmed pivot
    df['trend'] = 0
    last_pivot = pivots[0][1]
    last_idx = pivots[0][0]
    for i in range(len(df)):
        if i > last_idx and not np.isnan(df['pivot'].iloc[i-1]):
            last_idx = i-1
            last_pivot = df['pivot'].iloc[i-1]
        price = df['close'].iloc[i]
        if price > last_pivot:
            df.at[i, 'trend'] = 1
        elif price < last_pivot:
            df.at[i, 'trend'] = -1
        else:
            df.at[i, 'trend'] = 0
    return df


def merge_trends(dfs: dict) -> pd.DataFrame:
    base = dfs['M5'][['time', 'close', 'trend']].rename(columns={'trend': 'trend_M5'})
    for tf in ['M15', 'H1']:
        tmp = dfs[tf][['time', 'trend']].rename(columns={'trend': f'trend_{tf}'})
        base = pd.merge_asof(base, tmp, on='time', direction='backward')
    base['signal'] = np.where((base['trend_M5'] == 1) & (base['trend_M15'] == 1) & (base['trend_H1'] == 1), 'BUY',
                     np.where((base['trend_M5'] == -1) & (base['trend_M15'] == -1) & (base['trend_H1'] == -1), 'SELL', None))
    return base


def evaluate_signals(df: pd.DataFrame, look_ahead: int = 12, threshold: float = 0.0005):
    results = []
    for idx, row in df.dropna(subset=['signal']).iterrows():
        price = row['close']
        future = df['close'].iloc[idx+1: idx+1+look_ahead]
        if row['signal'] == 'BUY':
            success = (future.max() - price) > threshold
        else:
            success = (price - future.min()) > threshold
        results.append(success)
    success_rate = (sum(results) / len(results) * 100) if results else 0.0
    return len(results), success_rate


def run():
    dfs = {tf: zigzag(load_data(tf)) for tf in DATA_FILES}
    merged = merge_trends(dfs)
    count, success = evaluate_signals(merged)
    print(f"Signals: {count}  Success rate: {success:.1f}%")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='MF-V v6.0.2 strategy checker.')
    parser.add_argument('--run', action='store_true')
    args = parser.parse_args()
    if args.run:
        run()
