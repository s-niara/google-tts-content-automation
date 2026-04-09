# 🎙️ Google Gemini TTS Content Automation Pipeline

> A two-stage automated text-to-speech pipeline using Google Gemini's TTS API — designed for long-form content creation at scale.

---

## Overview

This project automates the conversion of long-form written scripts into high-quality, narrated audio files using Google's Gemini 2.5 Pro TTS model. It was built to solve a real content production challenge: converting lengthy documentary-style scripts into polished audio — efficiently, consistently, and at scale.

The pipeline runs in two stages:

```
Long Script (.txt)
      │
      ▼
 Stage 1: Chunking
 (Python — splits script into segments)
      │
      ▼
 Text Chunks (.txt files)
      │
      ▼
 Stage 2: TTS Generation
 (Bash — sends each chunk to Gemini API)
      │
      ▼
 Audio Output (.wav files)
```

---

## Features

- **Automated chunking** — splits long scripts into segments using a custom delimiter
- **Google Gemini TTS integration** — uses `gemini-2.5-pro-preview-tts` model for natural, high-quality narration
- **Custom voice & style control** — configurable voice selection and detailed narration style instructions
- **Robust error handling** — detects missing files, API errors, and malformed responses gracefully
- **Audio format conversion** — converts raw PCM audio to WAV using ffmpeg
- **Rate limiting** — built-in sleep intervals to respect API rate limits
- **Clean pipeline architecture** — two independent, composable scripts

---

## Tech Stack

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=flat&logo=google&logoColor=white)

- **Languages:** Python · Bash
- **APIs:** Google Gemini 2.5 Pro TTS API
- **Tools:** ffmpeg · jq · base64
- **Audio:** PCM → WAV conversion at 24kHz mono

---

## Project Structure

```
google-tts-content-automation/
│
├── chunk_script.py          # Stage 1 — splits long script into chunks
├── tts_pipeline.sh          # Stage 2 — sends chunks to Gemini TTS API
├── .env.example             # Environment variable template
├── .gitignore               # Excludes audio files, API responses, keys
└── README.md
```

---

## Prerequisites

**System tools:**
```bash
brew install jq ffmpeg
```

**Python:** 3.8+

**Google Gemini API key:**
- Get your key at: https://aistudio.google.com/apikey
- Set as environment variable (see Setup below)

---

## Setup

**1. Clone the repository:**
```bash
git clone https://github.com/danielseyedi/google-tts-content-automation
cd google-tts-content-automation
```

**2. Set your API key:**
```bash
export GEMINI_API_KEY=your_api_key_here
```

Or create a `.env` file based on `.env.example`:
```
GEMINI_API_KEY=your_api_key_here
```

**3. Install dependencies:**
```bash
brew install jq ffmpeg
```

---

## Usage

### Stage 1 — Chunk your script

Prepare your script as a `.txt` file. Use `||` as a delimiter between segments:

```
This is the first segment of your script.

||

This is the second segment. Each segment becomes one audio file.

||

This is the third segment.
```

Run the chunking script:
```bash
python3 chunk_script.py
```

This creates a `chunks/` directory containing numbered `.txt` files:
```
chunks/
├── chunk_001.txt
├── chunk_002.txt
├── chunk_003.txt
...
```

---

### Stage 2 — Generate audio

Run the TTS pipeline:
```bash
bash tts_pipeline.sh
```

This sends each chunk to the Gemini TTS API and saves the output as `.wav` files:
```
wav/
├── chunk_001.wav
├── chunk_002.wav
├── chunk_003.wav
...
```

---

## Configuration

Edit the following variables in `tts_pipeline.sh` to customise output:

```bash
# Model selection
MODEL="gemini-2.5-pro-preview-tts"

# Voice selection — see available voices in Gemini docs
VOICE="algieba"

# Narration style instructions
STYLE="Style instructions: Read aloud in a warm, friendly, gently enthusiastic tone..."
```

**Available voice options:** See [Google Gemini TTS documentation](https://ai.google.dev/gemini-api/docs/speech-generation) for the full list of available voices.

---

## Error Handling

The pipeline handles the following gracefully:

| Error | Behaviour |
|-------|-----------|
| Missing input chunk file | Skips with warning message |
| API error response | Logs error, skips chunk, waits 10 seconds |
| Malformed API response | Detected via jq parsing |
| Rate limiting | 3-second sleep between successful requests |

---

## Security

- API keys are **never hardcoded** — always passed via environment variables
- `.env` files are **excluded from version control** via `.gitignore`
- Generated audio files and API JSON responses are **excluded from the repo**

---

## Example Output

This pipeline was used to generate narrated audio for a long-form documentary-style script — producing 51 individual audio segments from a single source script, each narrated in a consistent warm documentary style.

---

## .gitignore

```
# Environment
.env

# API responses
wav/*.json

# Raw audio
wav/*.pcm

# Generated audio
wav/*.wav
distantgalaxies_wav/*.wav

# Chunks (generated — not source)
chunks/
distantgalaxies_chunks/

# macOS
.DS_Store
```

---

## .env.example

```
GEMINI_API_KEY=your_gemini_api_key_here
```

---

## Author

**Seyed Niaragh** — Final-year Bachelor of Data Science, Victoria University
[LinkedIn](https://linkedin.com/in/seyedniaragh) | [GitHub](https://github.com/s-niara)

---

## Licence

MIT — free to use, modify, and distribute with attribution.
