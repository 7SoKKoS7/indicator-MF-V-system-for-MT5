# python strategy_test.py - -file EURUSDH1.csv - -tf

import pandas as pd
import numpy as np
from pathlib import Path
import argparse
from datetime import datetime


def load_data(filepath: str, encoding: str) -> pd.DataFrame:
    df = pd.read_csv(
        filepath,
        names=["time", "open", "high", "low", "close", "tick_volume", "real_volume"],
        parse_dates=["time"],
        encoding=encoding,
    )
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

    # Trend
    df['trend'] = 0
    last_pivot = pivots[0][1]
    last_idx = pivots[0][0]
    for i in range(len(df)):
        if i > last_idx and not np.isnan(df['pivot'].iloc[i - 1]):
            last_idx = i - 1
            last_pivot = df['pivot'].iloc[i - 1]
        price = df['close'].iloc[i]
        if price > last_pivot:
            df.at[i, 'trend'] = 1
        elif price < last_pivot:
            df.at[i, 'trend'] = -1
        else:
            df.at[i, 'trend'] = 0
    return df


def evaluate_signals(df: pd.DataFrame, look_ahead: int = 12, threshold: float = 0.0005) -> tuple[int, float]:
    df['signal'] = np.where(df['trend'] == 1, 'BUY',
                    np.where(df['trend'] == -1, 'SELL', None))

    results = []
    for idx, row in df.dropna(subset=['signal']).iterrows():
        price = row['close']
        future = df['close'].iloc[idx+1: idx+1+look_ahead]
        if len(future) < look_ahead:
            continue
        if row['signal'] == 'BUY':
            success = (future.max() - price) > threshold
        else:
            success = (price - future.min()) > threshold
        results.append(success)

    success_rate = (sum(results) / len(results) * 100) if results else 0.0
    return len(results), success_rate


def run(file_path: str, tf_label: str, encoding: str):
    df = load_data(file_path, encoding)
    df = zigzag(df)
    count, success = evaluate_signals(df)
    msg = (
        f"File: {Path(file_path).name} | TF: {tf_label}\n"
        f"Signals: {count}\nSuccess rate: {success:.2f}%"
    )
    print(msg)
    timestamp = datetime.now().isoformat()
    with open("results.txt", "a", encoding="utf-8") as f:
        f.write(f"{timestamp}\n{msg}\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Single timeframe ZigZag trend strategy test."
    )
    parser.add_argument(
        '--file',
        required=True,
        nargs='+',
        help='Path(s) to CSV file(s) with historical data',
    )
    parser.add_argument(
        '--tf',
        nargs='+',
        help='Label(s) of the timeframe(s) (e.g., M5, M15, H1)',
    )
    parser.add_argument(
        '--encoding',
        default='utf-8',
        help='File encoding for CSV files (default: utf-8)',
    )
    args = parser.parse_args()

    tf_list = args.tf if args.tf else [None] * len(args.file)
    if len(tf_list) != len(args.file):
        raise ValueError('Number of --tf labels must match number of --file paths')

    for fp, tf in zip(args.file, tf_list):
        tf_label = tf if tf else Path(fp).stem
        run(fp, tf_label, args.encoding)
