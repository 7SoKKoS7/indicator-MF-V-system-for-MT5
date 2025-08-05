import pandas as pd
import numpy as np
from pathlib import Path
import argparse
from datetime import datetime
import codecs


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


# Minimum profit threshold in price units (e.g. 0.0030 ≈ 30 pips for EURUSD)
DEFAULT_THRESHOLD = 0.0030


def evaluate_signals(
    df: pd.DataFrame,
    look_ahead: int = 12,
    threshold: float = DEFAULT_THRESHOLD,
) -> tuple[int, float]:
    """Evaluate signals when all three timeframes confirm the trend."""
    cond_buy = (
        (df['trend_tf1'] == 1)
        & (df['trend_tf2'] == 1)
        & (df['trend_tf3'] == 1)
    )
    cond_sell = (
        (df['trend_tf1'] == -1)
        & (df['trend_tf2'] == -1)
        & (df['trend_tf3'] == -1)
    )
    df['signal'] = np.where(cond_buy, 'BUY', np.where(cond_sell, 'SELL', None))

    results = []
    for idx, row in df.dropna(subset=['signal']).iterrows():
        price = row['close']
        future = df['close'].iloc[idx + 1 : idx + 1 + look_ahead]
        if len(future) < look_ahead:
            continue
        if row['signal'] == 'BUY':
            success = (future.max() - price) > threshold
        else:
            success = (price - future.min()) > threshold
        results.append(success)

    success_rate = (sum(results) / len(results) * 100) if results else 0.0
    return len(results), success_rate


def prepare_dataframe(filepath: str, encoding: str) -> pd.DataFrame:
    """Load CSV and compute ZigZag trend."""
    df = load_data(filepath, encoding)
    df = zigzag(df)
    return df[['time', 'close', 'trend']]


def merge_timeframes(dfs: list[pd.DataFrame]) -> pd.DataFrame:
    """Merge three dataframes by time using backward fill for higher TFs."""
    base = dfs[0].rename(columns={'trend': 'trend_tf1', 'close': 'close'})
    for i, df in enumerate(dfs[1:], start=2):
        temp = df.rename(columns={'trend': f'trend_tf{i}'})[['time', f'trend_tf{i}']]
        base = pd.merge_asof(
            base,
            temp.sort_values('time'),
            on='time',
            direction='backward',
        )
    return base


def run(
    file_paths: list[str],
    tf_labels: list[str],
    encoding: str,
    threshold: float = DEFAULT_THRESHOLD,
):
    dfs = [prepare_dataframe(fp, encoding) for fp in file_paths]
    merged = merge_timeframes(dfs)
    count, success = evaluate_signals(merged, threshold=threshold)
    files_str = ', '.join(Path(p).name for p in file_paths)
    tfs_str = '/'.join(tf_labels)
    msg = (
        f"Files: {files_str} | TFs: {tfs_str}\n"
        f"Signals: {count}\nSuccess rate: {success:.2f}% (>{threshold})"
    )
    print(msg)
    timestamp = datetime.now().isoformat()
    with open("results.txt", "a", encoding="utf-8") as f:
        f.write(f"{timestamp}\n{msg}\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Triple timeframe ZigZag trend confirmation test.",
    )
    parser.add_argument(
        '--file',
        required=True,
        nargs=3,
        help='Paths to three CSV files (from lowest to highest timeframe)',
    )
    parser.add_argument(
        '--tf',
        nargs=3,
        help='Labels of the timeframes in the same order as --file',
    )
    parser.add_argument(
        '--encoding',
        default='auto',
        help='File encoding for CSV files or "auto" to detect (default: auto)',
    )
    parser.add_argument(
        '--threshold',
        type=float,
        default=DEFAULT_THRESHOLD,
        help='Minimum profit threshold in price units (default: %(default)s)',
    )
    args = parser.parse_args()

    tf_list = args.tf if args.tf else [Path(fp).stem for fp in args.file]
    if len(tf_list) != 3:
        raise ValueError('Exactly three --tf labels must be provided')

    run(args.file, tf_list, args.encoding, threshold=args.threshold)
