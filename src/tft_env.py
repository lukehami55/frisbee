"""Helpers for configuring pygame/SDL to talk to TFT framebuffers."""

import os
from typing import Iterable


def _apply_fb_settings(fb_path: str) -> None:
    os.environ.setdefault("SDL_VIDEODRIVER", "fbcon")
    os.environ.setdefault("SDL_FBDEV", fb_path)
    # Touch input paths vary; these hints are harmless if absent.
    os.environ.setdefault("SDL_MOUSEDRV", "TSLIB")
    os.environ.setdefault("SDL_MOUSEDEV", "/dev/input/touchscreen")


def _existing_paths(paths: Iterable[str]) -> list[str]:
    return [p for p in paths if os.path.exists(p)]


def configure_sdl_env() -> None:
    """Try to steer SDL toward whichever framebuffer the TFT exposes.

    On some Raspberry Pi configurations the HAT shows up as ``/dev/fb1`` while
    the primary framebuffer is still ``/dev/fb0``.  Other stacks (notably the
    VC4/KMS default on Pi 4) expose only ``/dev/fb0``.  When pygame falls back
    to the ``kmsdrm`` backend without a proper ``XDG_RUNTIME_DIR`` it aborts
    before we even get a window.  Steering SDL to the classic ``fbcon`` driver
    works reliably in these kiosk-style setups, so we do that whenever we spot
    a usable framebuffer device.
    """

    for fb in _existing_paths(("/dev/fb1", "/dev/fb0")):
        _apply_fb_settings(fb)
        break

    # Some drivers (kmsdrm) insist on XDG_RUNTIME_DIR even when they do not
    # end up being used.  If the service is running without a login session we
    # provide a safe default so SDL does not crash during initialization.
    os.environ.setdefault("XDG_RUNTIME_DIR", "/tmp")
