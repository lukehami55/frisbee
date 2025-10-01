#!/usr/bin/env bash
set -Eeuo pipefail

# ====== CHOOSE YOUR PANEL MODEL ======
# Common small SPI TFT HATs:
#   - 'ili9341'  (many 2.4"/2.8"/3.2" hats)
#   - 'st7789'   (many 2.0"/2.4" round/rect hats)
MODEL="ili9341"
# =====================================

CONFIG="/boot/firmware/config.txt"   # Bookworm path; older images may use /boot/config.txt
MARK_START="# >>> frisbee-tft BEGIN >>>"
MARK_END="# <<< frisbee-tft END <<<"

# Reasonable defaults (SPI0, standard pins). Adjust if your HAT requires non-default pins.
case "${MODEL}" in
  ili9341)
    # Uses fbtft driver via overlay
    OVERLAY_BLOCK=$(cat <<'EOF'
dtoverlay=spi1-1cs
dtoverlay=fb_ili9341,spi=1,speed=64000000,rotate=90,fps=60
# Backlight (if your HAT exposes one; harmless if not present)
dtoverlay=gpio-backlight
EOF
)
    ;;
  st7789)
    OVERLAY_BLOCK=$(cat <<'EOF'
dtoverlay=spi1-1cs
dtoverlay=vc4-kms-dpi-panel
# Many ST7789 hats expose KMS panel drivers differently; fbdev may map to fb0.
# If your vendor provides a specific overlay like fb_st7789v, prefer that:
# dtoverlay=fb_st7789v,spi=1,speed=64000000,rotate=90
EOF
)
    ;;
  *)
    echo "Unknown MODEL='${MODEL}'. Use 'ili9341' or 'st7789'." >&2
    exit 2
    ;;
esac

if [[ ! -f "${CONFIG}" ]]; then
  echo "Cannot find ${CONFIG}. Adjust the path for your OS version." >&2
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
  echo "# MODEL=${MODEL}"
  echo "${OVERLAY_BLOCK}"
  echo "${MARK_END}"
} | sudo tee -a "${CONFIG}.tmp" >/dev/null

sudo mv "${CONFIG}.tmp" "${CONFIG}"

echo "[tft] Updated ${CONFIG} with ${MODEL} overlays."
echo "[tft] Enabling kernel modules…"
# These will autoload on reboot; modprobe now for this session if available
sudo modprobe spi_bcm2835 || true
sudo modprobe fbtft || true 2>/dev/null || true

echo "[tft] Reboot required to create /dev/fb1 consistently."
echo "      Run: sudo reboot"
