#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

UNIT_TEMPLATE="${ROOT_DIR}/systemd/endoscope-viewer.service"
UNIT_DST="/etc/systemd/system/endoscope-viewer.service"

if [[ ! -f "${UNIT_TEMPLATE}" ]]; then
  echo "Missing ${UNIT_TEMPLATE}" >&2
  exit 1
fi

# Inject absolute repo path into the unit file
TMP_UNIT="$(mktemp)"
sed "s|__WORKDIR__|${ROOT_DIR}|g" "${UNIT_TEMPLATE}" > "${TMP_UNIT}"
sudo mv "${TMP_UNIT}" "${UNIT_DST}"
sudo chown root:root "${UNIT_DST}"
sudo chmod 644 "${UNIT_DST}"

# Create/refresh venv (optional but recommended)
if ! [[ -x "${ROOT_DIR}/.venv/bin/python" ]]; then
  echo "[install] Creating venv…"
  python3 -m venv "${ROOT_DIR}/.venv"
fi
source "${ROOT_DIR}/.venv/bin/activate"
pip install --upgrade pip
pip install -r "${ROOT_DIR}/requirements.txt"

# Reload + enable + start
sudo systemctl daemon-reload
sudo systemctl enable endoscope-viewer.service
sudo systemctl restart endoscope-viewer.service

echo
echo "[install] Done. Current unit:"
sudo systemctl cat endoscope-viewer.service
echo
echo "[install] Tail logs with:"
echo "  sudo journalctl -u endoscope-viewer.service -f"
