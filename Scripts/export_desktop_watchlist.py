#!/usr/bin/env python3
"""Export a bounded desktop watchlist without credentials or market history."""

import argparse
import json
import os
from pathlib import Path
import sqlite3
from urllib.parse import quote

MAX_ENTRIES = 500
ALLOWED_SYMBOL = frozenset("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.:-_")


def export(source_path: Path, output_path: Path) -> int:
    source_path = source_path.expanduser().resolve(strict=True)
    output_path = output_path.expanduser().absolute()
    if output_path.suffix.lower() != ".json":
        raise ValueError("Output file must use the .json extension for the native file picker.")

    source_uri = "file:" + quote(str(source_path)) + "?mode=ro"
    source = sqlite3.connect(source_uri, uri=True)
    try:
        source.execute("BEGIN")
        columns = {row[1] for row in source.execute("PRAGMA table_info(user_watchlist)")}
        if not {"symbol", "added_at"}.issubset(columns):
            raise ValueError("Desktop database has no compatible user_watchlist table.")
        rows = source.execute(
            "SELECT symbol, added_at FROM user_watchlist ORDER BY added_at, symbol LIMIT ?",
            (MAX_ENTRIES + 1,),
        ).fetchall()
        if not rows or len(rows) > MAX_ENTRIES:
            raise ValueError("Watchlist must contain 1 to 500 symbols.")
        entries = []
        for symbol, added_at in rows:
            if (not isinstance(symbol, str) or not symbol or len(symbol.encode("utf-8")) > 32
                    or any(character not in ALLOWED_SYMBOL for character in symbol)
                    or not isinstance(added_at, int) or added_at <= 0):
                raise ValueError("Desktop watchlist contains an unsupported entry.")
            entries.append({"symbol": symbol, "added_at": added_at})
        source.execute("COMMIT")
    finally:
        source.close()

    payload = json.dumps(
        {"format": "mimitrends-watchlist", "version": 1, "entries": entries},
        ensure_ascii=True, separators=(",", ":"),
    ).encode("utf-8")
    if len(payload) > 128_000:
        raise ValueError("Watchlist snapshot exceeds the native import size limit.")
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(output_path, flags, 0o600)
    try:
        with os.fdopen(descriptor, "wb") as destination:
            destination.write(payload)
    except Exception:
        output_path.unlink(missing_ok=True)
        raise
    return len(entries)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New JSON snapshot; existing files are never replaced")
    parser.add_argument(
        "--source", type=Path, default=Path("~/.mimi/trends/mimitrends.db"),
        help="Desktop SQLite database; opened read-only",
    )
    args = parser.parse_args()
    count = export(args.source, args.output)
    print(f"Exported {count} watchlist symbols to {args.output}.")


if __name__ == "__main__":
    main()
