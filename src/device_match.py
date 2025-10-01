"""
Minimal helpers to pick a likely USB endoscope under /dev/video*.
Prefers vendor 0x1BCF (common for UVC endoscopes Luke uses in ExperiENT).
Falls back to /dev/video0.
"""
from __future__ import annotations
import glob, os

PREFERRED_VENDORS = {0x1BCF}  # SunplusIT (often used in endoscopes)

def _read_hex(path: str):
    try:
        with open(path, "r") as f:
            return int(f.read().strip(), 16)
    except Exception:
        return None

def _usb_root(sys_video_path: str):
    try:
        real = os.path.realpath(sys_video_path)
        here = real
        for _ in range(8):
            if os.path.exists(os.path.join(here, "idVendor")):
                return here
            parent = os.path.dirname(here)
            if parent == here:
                break
            here = parent
    except Exception:
        pass
    return None

def pick_best_device(explicit: str | None = None) -> str:
    if explicit and os.path.exists(explicit):
        return explicit

    sys_nodes = sorted(glob.glob("/sys/class/video4linux/video*"))
    best = None
    for node in sys_nodes:
        dev = "/dev/" + os.path.basename(node)
        root = _usb_root(node)
        if not root:
            if best is None:
                best = dev
            continue
        vid = _read_hex(os.path.join(root, "idVendor"))
        if vid in PREFERRED_VENDORS:
            return dev  # prefer this immediately
        if best is None:
            best = dev
    return best or "/dev/video0"
