#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  echo "[run_service] $*" >&2
}

VENV_PY="${ROOT_DIR}/.venv/bin/python"
if [ -x "${VENV_PY}" ]; then
  PYTHON_BIN="${VENV_PY}"
  log "Using project virtualenv at ${PYTHON_BIN}"
else
  PYTHON_BIN="$(command -v python3 || true)"
  if [ -n "${PYTHON_BIN}" ]; then
    log "Virtualenv missing; falling back to ${PYTHON_BIN}"
  else
    log "ERROR: Could not find a python3 interpreter"
    exit 1
  fi
fi

export PYTHONUNBUFFERED=1
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# Hint SDL toward the TFT framebuffer if one is present.
if [ -z "${SDL_VIDEODRIVER:-}" ]; then
  export SDL_VIDEODRIVER=fbcon

  log "SDL_VIDEODRIVER defaulted to fbcon"
else
  log "SDL_VIDEODRIVER pre-set to ${SDL_VIDEODRIVER}"

fi
if [ -z "${SDL_FBDEV:-}" ]; then
  if [ -e /dev/fb1 ]; then
    export SDL_FBDEV=/dev/fb1
  elif [ -e /dev/fb0 ]; then
    export SDL_FBDEV=/dev/fb0
  fi

  if [ -n "${SDL_FBDEV:-}" ]; then
    log "SDL_FBDEV defaulted to ${SDL_FBDEV}"
  else
    log "No framebuffer override detected"
  fi
else
  log "SDL_FBDEV pre-set to ${SDL_FBDEV}"
fi

log "Launching camera viewer (${PYTHON_BIN} -m src.camera_viewer $*)"

exec "${PYTHON_BIN}" -m src.camera_viewer "$@"
