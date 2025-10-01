# pi-endoscope-tft (simple)

Tiny viewer that opens a USB endoscope (UVC) on a Raspberry Pi and displays it full-screen on an Inland/Waveshare-style 3.5" TFT HAT (fb1).  
If `/dev/fb1` isn’t present, it renders to the default display (HDMI).

## Install (on the Pi)
```bash
git clone https://github.com/<your-username>/pi-endoscope-tft.git
cd pi-endoscope-tft
sudo ./scripts/install.sh
