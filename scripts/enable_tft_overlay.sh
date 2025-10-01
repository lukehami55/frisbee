#!/usr/bin/env bash
set -Eeuo pipefail

# Inland 3.5" TFT HAT (Micro Center SKU 221879) – Waveshare 3.5" (A) compatible
# Panel: ILI9486 (480x320), Touch: ADS7846/XPT2046 compatible
# This enables SPI and adds the fbdev overlay that exposes /dev/fb1.

CONFIG="/boot/firmware/config.txt"   # Bookworm path; use /boot/config.txt on older images
if [[ ! -f "${CONFIG}" ]]; then
  CONFIG="/boot/config.txt"
fi

MARK_START="# >>> frisbee-tft BEGIN >>>"
MARK_END="# <<< frisbee-tft END <<<"

OVERLAY_BLOCK=$(cat <<'EOF'
# Enable SPI (required by most 3.5" GPIO TFT hats)
dtparam=spi=on

# Waveshare 3.5" (A) compatible framebuffer overlay (creates /dev/fb1)
# rotate: 0/90/180/270 as needed; speed/fps are safe defaults
dtoverlay=waveshare35a,rotate=90,speed=64000000,fps=60

# Resistive touch controller (ADS7846/XPT2046) – optional; harmless if absent
dtoverlay=ads7846,cs=1,penirq=25,penirq_pull=2,speed=50000

# Backlight control (some boards expose it; harmless if absent)
dtoverlay=gpio-backlight
EOF
)

if [[ ! -f "${CONFIG}" ]]; then
  echo "Cannot find ${CONFIG}. Aborting." >&2
  exit 1
fi

# Remove any previous managed block, then append the new one
sudo awk -v start="${MARK_START}" -v end="${MARK_END}" '
  $0==start {skip=1}
  skip && $0==end {skip=0; next}
  !skip {print}
' "${CONFIG}" | sudo tee "${CONFIG}.tmp" >/dev/null

{
  echo "${MARK_START}"
  echo "# Enabled by scripts/enable_tft_overlay.sh on $(date -Iseconds)"
  echo "${OVERLAY_BLOCK}"
  echo "${MARK_END}"
} | sudo tee -a "${CONFIG}.tmp" >/dev/null

sudo mv "${CONFIG}.tmp" "${CONFIG}"

# Load modules now (they will auto-load on reboot too)
sudo modprobe spi_bcm2835 || true
sudo modprobe fbtft_device 2>/dev/null || true
sudo modprobe fbtft 2>/dev/null || true
sudo modprobe ads7846 2>/dev/null || true

echo "[tft] Overlay configured in ${CONFIG}."
echo "[tft] Reboot required to create /dev/fb1 consistently."
echo "      Run: sudo reboot"
