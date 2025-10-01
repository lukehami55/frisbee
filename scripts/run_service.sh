#!/usr/bin/env bash
set -Eeuo pipefail

# --- Resolve repo root (works regardless of how we're called) ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# --- Defaults & args ---
ROTATE="0"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rotate) ROTATE="${2:-0}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# --- Ensure non-interactive headless-friendly env ---
export PYTHONUNBUFFERED=1
export SDL_AUDIODRIVER=dummy
# Avoid SDL complaining under systemd
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

# --- Prefer repo venv if present, else system python3 ---
PY_BIN="${ROOT_DIR}/.venv/bin/python"
if [[ ! -x "${PY_BIN}" ]]; then
  PY_BIN="$(command -v python3)"
fi

# --- Try to steer SDL to TFT if a framebuffer exists ---
if [[ -e /dev/fb1 ]]; then
  export SDL_VIDEODRIVER=fbcon
  export SDL_FBDEV=/dev/fb1
elif [[ -e /dev/fb0 ]]; then
  # If fb0 is the small TFT (width <= 800), still use it
  FB0_INFO="$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "")"
  # FB0_INFO like "480,320"
  if [[ "${FB0_INFO}" =~ ^([0-9]+),([0-9]+)$ ]]; then
    WIDTH="${BASH_REMATCH[1]}"
    if [[ "${WIDTH}" -le 800 ]]; then
      export SDL_VIDEODRIVER=fbcon
      export SDL_FBDEV=/dev/fb0
    fi
  fi
fi

# --- Launch the viewer ---
exec "${PY_BIN}" -m src.camera_viewer --rotate "${ROTATE}" --debug
