"""
If /dev/fb1 exists (typical on 3.5" TFT HATs), direct pygame to it.
Otherwise fall back to default display (HDMI/KMS).
"""
import os

def configure_sdl_env():
    if os.path.exists("/dev/fb1"):
        os.environ.setdefault("SDL_VIDEODRIVER", "fbcon")
        os.environ.setdefault("SDL_FBDEV", "/dev/fb1")
        # Touch input paths vary; these hints are harmless if absent.
        os.environ.setdefault("SDL_MOUSEDRV", "TSLIB")
        os.environ.setdefault("SDL_MOUSEDEV", "/dev/input/touchscreen")
