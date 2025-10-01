#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PY="${ROOT_DIR}/.venv/bin/python"
if [ -x "${VENV_PY}" ]; then
  PYTHON_BIN="${VENV_PY}"
else
  PYTHON_BIN="$(command -v python3)"
fi

export PYTHONUNBUFFERED=1
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# Hint SDL toward the TFT framebuffer if one is present.
if [ -z "${SDL_VIDEODRIVER:-}" ]; then
  export SDL_VIDEODRIVER=fbcon
fi
if [ -z "${SDL_FBDEV:-}" ]; then
  if [ -e /dev/fb1 ]; then
    export SDL_FBDEV=/dev/fb1
  elif [ -e /dev/fb0 ]; then
    export SDL_FBDEV=/dev/fb0
  fi
fi

exec "${PYTHON_BIN}" -m src.camera_viewer "$@"
