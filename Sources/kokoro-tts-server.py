#!/usr/bin/env python3
"""Kokoro TTS sidecar — reads text lines from stdin, writes WAV to temp files."""

import sys
import os
import time
import numpy as np
import soundfile as sf

IPC_DIR = os.path.expanduser("~/.claude/cc-beeper")
OUTPUT_FILE = os.path.join(IPC_DIR, "tts-output.wav")
READY_FILE = os.path.join(IPC_DIR, "tts-ready")

def log(msg):
    """Log to stderr (stdout is reserved for signaling)."""
    print(f"[kokoro-tts] {msg}", file=sys.stderr, flush=True)

def main():
    log("starting...")

    # Load pipeline once
    from kokoro import KPipeline
    log("loading model (first time downloads ~80MB)...")
    t0 = time.time()
    pipeline = KPipeline(lang_code='a', repo_id='hexgrad/Kokoro-82M')
    log(f"model loaded in {time.time()-t0:.1f}s — ready")

    # Signal readiness via file
    with open(READY_FILE, "w") as f:
        f.write("ready")

    voice = "bm_daniel"

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        # Commands
        if line.startswith("VOICE:"):
            voice = line[6:].strip()
            log(f"voice set to: {voice}")
            continue

        # Generate speech
        log(f"generating: {line[:80]}...")
        t1 = time.time()

        all_audio = []
        for _, _, audio in pipeline(line, voice=voice):
            all_audio.append(audio)

        if not all_audio:
            log("no audio generated")
            continue

        full = np.concatenate(all_audio)
        elapsed = time.time() - t1
        duration = len(full) / 24000
        log(f"done: {duration:.1f}s audio in {elapsed:.1f}s (RTF {elapsed/duration:.2f}x)")

        # Write WAV to temp file, then atomically move to output path
        tmp = OUTPUT_FILE + ".tmp.wav"
        sf.write(tmp, full, 24000)
        os.replace(tmp, OUTPUT_FILE)
        log(f"wrote {os.path.getsize(OUTPUT_FILE)} bytes to {OUTPUT_FILE}")

    log("stdin closed, exiting")

if __name__ == "__main__":
    main()
