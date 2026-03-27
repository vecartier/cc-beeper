#!/bin/bash
# Setup Kokoro TTS venv for CC-Beeper
set -e

VENV_DIR="$HOME/.cache/cc-beeper/kokoro-venv"
MARKER="$VENV_DIR/.installed"

if [ -f "$MARKER" ]; then
    echo "Kokoro TTS already installed at $VENV_DIR"
    exit 0
fi

echo "Setting up Kokoro TTS..."

# Find Python 3.10+
PYTHON=""
for p in python3.12 python3.13 python3.11 python3.10; do
    if command -v "$p" &>/dev/null; then
        PYTHON="$p"
        break
    fi
done

# Check Homebrew Python
if [ -z "$PYTHON" ]; then
    for p in /opt/homebrew/opt/python@3.12/bin/python3.12 /opt/homebrew/opt/python@3.11/bin/python3.11; do
        if [ -x "$p" ]; then
            PYTHON="$p"
            break
        fi
    done
fi

if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.10+ required. Install with: brew install python@3.12"
    exit 1
fi

echo "Using $($PYTHON --version)"

# Create venv
mkdir -p "$(dirname "$VENV_DIR")"
$PYTHON -m venv "$VENV_DIR"

# Install dependencies
echo "Installing Kokoro TTS (this may take a few minutes)..."
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install "kokoro>=0.9.2" soundfile -q

# Install spacy model (required by kokoro's text processing)
"$VENV_DIR/bin/pip" install https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl -q

# Pre-download the model
echo "Downloading Kokoro-82M model..."
"$VENV_DIR/bin/python" -c "from kokoro import KPipeline; KPipeline(lang_code='a', repo_id='hexgrad/Kokoro-82M')" 2>/dev/null

touch "$MARKER"
echo "Kokoro TTS ready!"
