"""
chunk_script.py
---------------
Stage 1 of the Google Gemini TTS Content Automation Pipeline.

Splits a long-form script into individual text chunks using a
custom delimiter. Each chunk becomes one audio file in Stage 2.

Usage:
    python3 chunk_script.py

Configuration:
    - Set INPUT_FILE to your script filename
    - Set OUTPUT_DIR to your desired chunks directory
    - Set DELIMITER to your chosen split token (default: ||)
"""

import pathlib
import re
import sys

# ── Configuration ─────────────────────────────────────────────────────────────

INPUT_FILE  = "script.txt"        # Your source script filename
OUTPUT_DIR  = "chunks"            # Output directory for chunk files
DELIMITER   = "||"                # Delimiter used to split script into segments
ENCODING    = "utf-8"

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    src_path = pathlib.Path(INPUT_FILE)

    # Validate input file exists
    if not src_path.exists():
        print(f"❌ Input file not found: {INPUT_FILE}")
        print(f"   Please create '{INPUT_FILE}' and use '{DELIMITER}' to separate segments.")
        sys.exit(1)

    # Read source script
    src = src_path.read_text(encoding=ENCODING)

    if not src.strip():
        print(f"❌ Input file is empty: {INPUT_FILE}")
        sys.exit(1)

    # Split on delimiter
    parts = [
        p.strip()
        for p in re.split(rf"\s*{re.escape(DELIMITER)}\s*", src)
        if p.strip()
    ]

    if not parts:
        print(f"❌ No content found after splitting on delimiter '{DELIMITER}'")
        sys.exit(1)

    # Create output directory
    outdir = pathlib.Path(OUTPUT_DIR)
    outdir.mkdir(exist_ok=True)

    # Write chunk files
    for i, chunk in enumerate(parts, 1):
        out_path = outdir / f"chunk_{i:03d}.txt"
        out_path.write_text(chunk + "\n", encoding=ENCODING)

    print(f"✅ Created {len(parts)} chunks in '{OUTPUT_DIR}/' using delimiter '{DELIMITER}'")
    print(f"   Chunks: chunk_001.txt → chunk_{len(parts):03d}.txt")


if __name__ == "__main__":
    main()
