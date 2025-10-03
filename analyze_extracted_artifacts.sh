#!/usr/bin/env bash
# analyze_extracted_artifacts.sh
# 사용법: ./analyze_extracted_artifacts.sh
# 필요: sqlite3, file, strings, hexdump

EXDIR="extracted"
OUTDIR="analysis_results"
mkdir -p "$OUTDIR/sqlite" "$OUTDIR/strings" "$OUTDIR/hexdump" "$OUTDIR/summary"

# helper: convert webkit timestamp (microseconds since 1601) -> human readable
# Not all queries need this, but example query included in sqlite processing.

echo "Starting analysis in: $EXDIR"

# Walk through extracted files
find "$EXDIR" -type f | while read -r f; do
  echo "---- Processing: $f"
  base=$(basename "$f")
  safe=$(echo "$f" | sed 's#/#_#g')
  shortname=$(echo "$base" | sed 's/[^A-Za-z0-9._-]/_/g')

  # determine file type
  ftype=$(file -b "$f")

  echo "File type: $ftype" > "$OUTDIR/summary/$(basename "$f").summary.txt"

  # If SQLite DB (heuristic: "SQLite" in file)
  if echo "$ftype" | grep -qi "SQLite"; then
    echo "[SQLite DB] $f"
    echo "Tables and sample queries for $f" > "$OUTDIR/sqlite/${shortname}.txt"
    sqlite3 "$f" ".tables" >> "$OUTDIR/sqlite/${shortname}.txt" 2>>"$OUTDIR/sqlite/${shortname}.txt"

    # Try known queries for History DB
    # If urls & visits exist, run the visit join
    has_urls=$(sqlite3 "$f" "SELECT name FROM sqlite_master WHERE type='table' AND name='urls';" 2>/dev/null)
    has_visits=$(sqlite3 "$f" "SELECT name FROM sqlite_master WHERE type='table' AND name='visits';" 2>/dev/null)
    if [[ -n "$has_urls" && -n "$has_visits" ]]; then
      echo "Running history query..." >> "$OUTDIR/sqlite/${shortname}.txt"
      sqlite3 -header -newline '|' "$f" "SELECT urls.url AS url, urls.title AS title, datetime((visits.visit_time/1000000)-11644473600,'unixepoch','localtime') AS visit_time FROM urls, visits WHERE urls.id = visits.url ORDER BY visits.visit_time DESC LIMIT 200;" >> "$OUTDIR/sqlite/${shortname}.csv" 2>/dev/null || true
      echo "Wrote CSV: $OUTDIR/sqlite/${shortname}.csv"
    fi

    # Cookies table check
    has_cookies=$(sqlite3 "$f" "SELECT name FROM sqlite_master WHERE type='table' AND name='cookies';" 2>/dev/null)
    if [[ -n "$has_cookies" ]]; then
      echo "Running cookies query..." >> "$OUTDIR/sqlite/${shortname}.txt"
      sqlite3 -header -newline '|' "$f" "SELECT host_key, name, value, datetime(creation_utc/1000000-11644473600,'unixepoch','localtime') AS created, datetime(expires_utc/1000000-11644473600,'unixepoch','localtime') AS expires FROM cookies ORDER BY created DESC LIMIT 200;" >> "$OUTDIR/sqlite/${shortname}_cookies.csv" 2>/dev/null || true
      echo "Wrote CSV: $OUTDIR/sqlite/${shortname}_cookies.csv"
    fi

    # Login Data (common name "logins" or "logins" table)
    has_logins=$(sqlite3 "$f" "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('logins','logins2','logins3','login');" 2>/dev/null)
    if [[ -n "$has_logins" ]]; then
      echo "Running logins query..." >> "$OUTDIR/sqlite/${shortname}.txt"
      sqlite3 -header -newline '|' "$f" "SELECT origin_url, username_value FROM logins LIMIT 200;" >> "$OUTDIR/sqlite/${shortname}_logins.csv" 2>/dev/null || true
      echo "Wrote CSV: $OUTDIR/sqlite/${shortname}_logins.csv"
    fi

    # Save schema to text
    sqlite3 "$f" ".schema" >> "$OUTDIR/sqlite/${shortname}.txt" 2>>"$OUTDIR/sqlite/${shortname}.txt"

  else
    # Not SQLite: run strings search for relevant keywords
    echo "[Non-SQLite] running strings grep (openai/chatgpt/conversation) on $f"
    strings "$f" | egrep -i 'openai|chatgpt|conversation|chat\.openai' > "$OUTDIR/strings/${shortname}.txt" || true

    # also save hexdump (first 1024 bytes) for inspection (avoid huge files)
    head -c 1024 "$f" | hexdump -C > "$OUTDIR/hexdump/${shortname}.hexdump.txt" || true
  fi

done

echo "Analysis complete. Results in: $OUTDIR"
