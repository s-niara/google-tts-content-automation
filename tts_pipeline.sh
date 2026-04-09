#!/usr/bin/env bash
# =============================================================================
# tts_pipeline.sh
# -----------------------------------------------------------------------------
# Stage 2 of the Google Gemini TTS Content Automation Pipeline.
#
# Reads text chunks from the chunks/ directory and sends each one to the
# Google Gemini TTS API. Saves output as .wav audio files.
#
# Usage:
#   export GEMINI_API_KEY=your_api_key_here
#   bash tts_pipeline.sh
#
# Prerequisites:
#   brew install jq ffmpeg
#
# Configuration:
#   Edit the variables below to customise model, voice, style, and chunk range.
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────

MODEL="gemini-2.5-pro-preview-tts"
VOICE="ANY VOICE FROM GOOGLE DOC LISTING"
CHUNKS_DIR="chunks"
OUTPUT_DIR="wav"
SLEEP_SUCCESS=3       # seconds between successful requests
SLEEP_ERROR=10        # seconds after an API error

STYLE="Style instructions: Read aloud in a warm, friendly, gently enthusiastic \
tone — like an engaging documentary narrator. Keep it calm and smooth, but add \
subtle energy on key words. Moderate pace, clear articulation, natural \
rises/falls. Avoid monotone and avoid overacting."

# Chunk range — edit start/end to match your chunk files
CHUNK_START=1
CHUNK_END=10

# ── Validation ────────────────────────────────────────────────────────────────

# Check API key is set
if [ -z "${GEMINI_API_KEY:-}" ]; then
    echo "❌ GEMINI_API_KEY environment variable is not set."
    echo "   Run: export GEMINI_API_KEY=your_api_key_here"
    exit 1
fi

# Check dependencies
for cmd in jq ffmpeg curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Required tool not found: $cmd"
        echo "   Install with: brew install $cmd"
        exit 1
    fi
done

# Check chunks directory exists
if [ ! -d "$CHUNKS_DIR" ]; then
    echo "❌ Chunks directory not found: $CHUNKS_DIR"
    echo "   Run chunk_script.py first to generate chunks."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# ── Pipeline ──────────────────────────────────────────────────────────────────

SUCCESS=0
SKIPPED=0
ERRORS=0

for i in $(seq -w "$CHUNK_START" "$CHUNK_END"); do
    CHUNK_FILE="${CHUNKS_DIR}/chunk_${i}.txt"
    BASE="chunk_${i}"
    JSON_FILE="${OUTPUT_DIR}/${BASE}.json"
    PCM_FILE="${OUTPUT_DIR}/${BASE}.pcm"
    WAV_FILE="${OUTPUT_DIR}/${BASE}.wav"

    # Skip if chunk file doesn't exist
    if [ ! -f "$CHUNK_FILE" ]; then
        echo "⚠️  Missing chunk: $CHUNK_FILE — skipping"
        ((SKIPPED++))
        continue
    fi

    echo "🔊 Generating ${BASE}..."

    # Build prompt — prepend style instructions to chunk text
    TEXT="$(printf "%s\n\n%s" "$STYLE" "$(cat "$CHUNK_FILE")")"

    # Call Gemini TTS API
    curl -sS \
        "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$(jq -n \
            --arg t "$TEXT" \
            --arg v "$VOICE" \
            '{
                contents: [{ parts: [{ text: $t }] }],
                generationConfig: {
                    responseModalities: ["AUDIO"],
                    speechConfig: {
                        voiceConfig: {
                            prebuiltVoiceConfig: {
                                voiceName: $v
                            }
                        }
                    }
                }
            }')" > "$JSON_FILE"

    # Check for API error in response
    API_ERROR="$(jq -r 'if .error then .error.message else "" end' "$JSON_FILE")"
    if [ -n "$API_ERROR" ]; then
        echo "❌ API error on ${BASE}: $API_ERROR"
        echo "   Response saved: $JSON_FILE"
        ((ERRORS++))
        sleep "$SLEEP_ERROR"
        continue
    fi

    # Extract base64 audio data and decode to PCM
    jq -r '.candidates[0].content.parts[]? | select(.inlineData?.data!=null) | .inlineData.data' \
        "$JSON_FILE" | head -n 1 | base64 --decode > "$PCM_FILE"

    # Validate PCM file was created and has content
    if [ ! -s "$PCM_FILE" ]; then
        echo "❌ Empty audio output for ${BASE} — skipping"
        ((ERRORS++))
        sleep "$SLEEP_ERROR"
        continue
    fi

    # Convert PCM to WAV using ffmpeg
    ffmpeg -f s16le -ar 24000 -ac 1 -i "$PCM_FILE" "$WAV_FILE" -y >/dev/null 2>&1

    echo "✅ Saved: $WAV_FILE"
    ((SUCCESS++))
    sleep "$SLEEP_SUCCESS"
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════"
echo "  Pipeline complete"
echo "  ✅ Success:  $SUCCESS"
echo "  ⚠️  Skipped:  $SKIPPED"
echo "  ❌ Errors:   $ERRORS"
echo "═══════════════════════════════════════"
