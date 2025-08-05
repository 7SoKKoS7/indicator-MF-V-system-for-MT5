"""Multi-timeframe ZigZag strategy tester (v8 23:07).

This script evaluates trend signals confirmed across three timeframes.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import argparse
from datetime import datetime
import codecs
from typing import List


def load_data(filepath: str, encoding: str) -> pd.DataFrame:
    """Load CSV data with optional encoding auto-detection."""
    if encoding == 'auto':
        with open(filepath, 'rb') as f:
            start = f.read(4)
        if start.startswith(codecs.BOM_UTF16_LE) or start.startswith(codecs.BOM_UTF16_BE):
            encoding = 'utf-16'
        elif start.startswith(codecs.BOM_UTF8):
            encoding = 'utf-8-sig'
        else:
            encoding = 'utf-8'

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


def evaluate_signals(df: pd.DataFrame, look_ahead: int = 12, threshold: float = 0.0030) -> tuple[int, float]:
    """Evaluate generated BUY/SELL signals using a fixed profit threshold."""
    results = []
    for idx, row in df.dropna(subset=['signal']).iterrows():
        price = row['close']
        future = df['close'].iloc[idx + 1: idx + 1 + look_ahead]
        if len(future) < look_ahead:
            continue
        if row['signal'] == 'BUY':
            success = (future.max() - price) > threshold
        else:
            success = (price - future.min()) > threshold
        results.append(success)

    success_rate = (sum(results) / len(results) * 100) if results else 0.0
    return len(results), success_rate


def run(file_paths: List[str], tf_labels: List[str], encoding: str):
    """Load three timeframes, compare trends, and evaluate confirmed signals."""
    dfs = []
    for fp in file_paths:
        df = load_data(fp, encoding)
        df = zigzag(df)
        dfs.append(df)

    base = dfs[0].copy()
    base['signal'] = None
    for i, time in enumerate(base['time']):
        trends = []
        for df in dfs:
            idx = df['time'].searchsorted(time, side='right') - 1
            trends.append(df['trend'].iloc[idx] if idx >= 0 else 0)
        if all(t == 1 for t in trends):
            base.at[i, 'signal'] = 'BUY'
        elif all(t == -1 for t in trends):
            base.at[i, 'signal'] = 'SELL'

    count, success = evaluate_signals(base)
    msg = (
        f"Files: {', '.join(Path(fp).name for fp in file_paths)} | TF: {', '.join(tf_labels)}\n"
        f"Signals: {count}\nSuccess rate: {success:.2f}%"
    )
    print(msg)
    timestamp = datetime.now().isoformat()
    with open("results.txt", "a", encoding="utf-8") as f:
        f.write(f"{timestamp}\n{msg}\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Three-timeframe ZigZag trend confirmation test."
    )
    parser.add_argument(
        '--file',
        required=True,
        nargs='+',
        help='Paths to CSV files for the timeframes (at least three)',
    )
    parser.add_argument(
        '--tf',
        nargs='+',
        help='Labels of the timeframes (e.g., M5 M15 H1)',
    )
    parser.add_argument(
        '--encoding',
        default='auto',
        help='File encoding for CSV files or "auto" to detect',
    )
    args = parser.parse_args()

    if len(args.file) < 3:
        raise ValueError('Provide at least three CSV files')

    tf_list = args.tf if args.tf else [None] * len(args.file)
    if len(tf_list) != len(args.file):
        raise ValueError('Number of --tf labels must match number of --file paths')

    tf_labels = [tf if tf else Path(fp).stem for fp, tf in zip(args.file, tf_list)]
    run(args.file, tf_labels, args.encoding)

