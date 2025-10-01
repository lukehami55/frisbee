#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="endoscope-viewer.service"
SERVICE_SRC="${REPO_DIR}/systemd/${SERVICE_NAME}"
SERVICE_DST="/etc/systemd/system/${SERVICE_NAME}"
TARGET_USER="${SUDO_USER:-${USER}}"

echo "==> Packages..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip v4l-utils \
  libsdl2-dev libsdl2-ttf-2.0-0

echo "==> Python venv..."
python3 -m venv "${REPO_DIR}/.venv"
source "${REPO_DIR}/.venv/bin/activate"
pip install --upgrade pip
pip install -r "${REPO_DIR}/requirements.txt"

echo "==> Add ${TARGET_USER} to 'video' group (access /dev/video*)"
sudo usermod -aG video "${TARGET_USER}" || true

# ---- OPTIONAL: enable a common Waveshare 3.5\" TFT overlay (if your TFT isn't set up) ----
# CONFIG_TXT="/boot/firmware/config.txt"
# [ -f "$CONFIG_TXT" ] || CONFIG_TXT="/boot/config.txt"
# sudo sed -i 's/^\s*#\?\s*dtparam=spi=.*/dtparam=spi=on/' "$CONFIG_TXT" || true
# if ! grep -q "^dtoverlay=waveshare35a" "$CONFIG_TXT"; then
#   sudo tee -a "$CONFIG_TXT" >/dev/null <<'EOF'
# dtoverlay=waveshare35a,rotate=90,speed=64000000,fps=60
# disable_overscan=1
# EOF
#   echo "TFT overlay lines added. Reboot after install if you enabled this."
# fi
# -----------------------------------------------------------------------------------------

echo "==> Install systemd service..."
TMP="$(mktemp)"
sed "s|__WORKDIR__|${REPO_DIR}|g; s|__USER__|${TARGET_USER}|g" "${SERVICE_SRC}" > "${TMP}"
sudo mv "${TMP}" "${SERVICE_DST}"
sudo chmod 644 "${SERVICE_DST}"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "Done. Logs: sudo journalctl -u ${SERVICE_NAME} -f"
