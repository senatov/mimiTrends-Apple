#!/usr/bin/env python3
"""Export a bounded, consistent minute-bar snapshot for the native app."""

import argparse
import math
import os
from pathlib import Path
import sqlite3
import time
from urllib.parse import quote

MAX_BARS = 360
REQUIRED_COLUMNS = {
    "symbol", "minute_epoch", "open", "high", "low", "close", "volume",
    "volume_status", "source_currency", "currency_status",
}


def source_currency(symbol: str) -> str:
    return "EUR" if symbol.endswith((".DE", ".F", ".PA", ".AS", ".MI", ".HE")) else "USD"


def export(source_path: Path, output_path: Path, symbol: str) -> int:
    symbol = symbol.strip().upper()
    if not symbol or any(character.isspace() for character in symbol):
        raise ValueError("Symbol must be a non-empty market symbol without whitespace.")
    source_path = source_path.expanduser().resolve(strict=True)
    output_path = output_path.expanduser().absolute()
    if output_path.suffix.lower() != ".sqlite":
        raise ValueError("Output file must use the .sqlite extension for the native file picker.")
    source_uri = "file:" + quote(str(source_path)) + "?mode=ro"
    source = sqlite3.connect(source_uri, uri=True)
    try:
        source.execute("BEGIN")
        columns = {row[1] for row in source.execute("PRAGMA table_info(minute_bars)")}
        if not REQUIRED_COLUMNS.issubset(columns):
            raise ValueError("Desktop database has no compatible minute_bars table.")
        rows = source.execute(
            """SELECT symbol, minute_epoch, open, high, low, close, volume,
                      volume_status, source_currency, currency_status
               FROM minute_bars WHERE symbol=? ORDER BY minute_epoch DESC LIMIT ?""",
            (symbol, MAX_BARS),
        ).fetchall()
        if not rows:
            raise ValueError(f"No saved minute bars for {symbol}.")
        expected_currency = source_currency(symbol)
        for row in rows:
            _, minute, opening, high, low, close, volume, status, currency, currency_status = row
            if (minute % 60 != 0 or not all(math.isfinite(value) for value in
                    (opening, high, low, close, volume))
                    or opening <= 0 or close <= 0 or volume < 0
                    or high < max(opening, close, low) or low > min(opening, close, high)
                    or status not in {"REPORTED", "ZERO", "MISSING", "ESTIMATED"}
                    or (status == "REPORTED" and volume <= 0)
                    or currency != expected_currency or currency_status != "INFERRED"):
                raise ValueError("Desktop bars contain unsupported or invalid values.")
        source.execute("COMMIT")
    finally:
        source.close()

    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(output_path, flags, 0o600)
    os.close(descriptor)
    try:
        destination = sqlite3.connect(output_path)
        try:
            destination.execute("PRAGMA journal_mode=DELETE")
            with destination:
                destination.execute(
                    """CREATE TABLE export_metadata(
                           format_version INTEGER NOT NULL, symbol TEXT NOT NULL,
                           exported_at INTEGER NOT NULL)"""
                )
                destination.execute(
                    "INSERT INTO export_metadata VALUES(1, ?, ?)", (symbol, int(time.time())),
                )
                destination.execute(
                    """CREATE TABLE minute_bars(
                           symbol TEXT NOT NULL, minute_epoch INTEGER NOT NULL,
                           open REAL NOT NULL, high REAL NOT NULL, low REAL NOT NULL,
                           close REAL NOT NULL, volume REAL NOT NULL,
                           volume_status TEXT NOT NULL, source_currency TEXT NOT NULL,
                           currency_status TEXT NOT NULL,
                           PRIMARY KEY(symbol, minute_epoch))"""
                )
                destination.executemany(
                    "INSERT INTO minute_bars VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", reversed(rows),
                )
            if destination.execute("PRAGMA quick_check").fetchone()[0] != "ok":
                raise ValueError("Exported snapshot failed SQLite integrity check.")
        finally:
            destination.close()
    except Exception:
        output_path.unlink(missing_ok=True)
        raise
    return len(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("symbol", help="Desktop market symbol, for example AAPL or IFX.DE")
    parser.add_argument("output", type=Path, help="New snapshot file; existing files are never replaced")
    parser.add_argument(
        "--source", type=Path, default=Path("~/.mimi/trends/mimitrends.db"),
        help="Desktop SQLite database; opened read-only",
    )
    args = parser.parse_args()
    count = export(args.source, args.output, args.symbol)
    print(f"Exported {count} completed bars for {args.symbol.strip().upper()} to {args.output}.")


if __name__ == "__main__":
    main()
