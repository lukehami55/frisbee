"""
Simple full-screen viewer for a USB UVC endoscope.
- Prefers rendering to /dev/fb1 (TFT HAT) when present.
- Exit: press 'q' or double-tap the touch screen quickly.
"""
from __future__ import annotations
import argparse, time
import cv2, pygame
from .device_match import pick_best_device
from .tft_env import configure_sdl_env

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default=None, help="/dev/videoN (optional)")
    ap.add_argument("--width", type=int, default=1280)
    ap.add_argument("--height", type=int, default=720)
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--rotate", type=int, default=0, help="0|90|180|270")
    ap.add_argument("--mirror", action="store_true")
    ap.add_argument("--debug", action="store_true")
    return ap.parse_args()

def open_cam(dev, w, h, fps):
    cap = cv2.VideoCapture(dev, cv2.CAP_V4L2)
    try:
        cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
    except Exception:
        pass
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, w)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, h)
    cap.set(cv2.CAP_PROP_FPS, fps)
    if not cap.isOpened():
        raise RuntimeError(f"Could not open camera at {dev}")
    return cap

def rotate_and_mirror(frame, deg, mirror):
    if mirror:
        frame = cv2.flip(frame, 1)
    d = deg % 360
    if d == 90:
        return cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
    if d == 180:
        return cv2.rotate(frame, cv2.ROTATE_180)
    if d == 270:
        return cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)
    return frame

def main():
    configure_sdl_env()
    args = parse_args()

    dev = pick_best_device(args.device)
    cap = open_cam(dev, args.width, args.height, args.fps)

    pygame.init()
    screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
    sw, sh = screen.get_size()
    clock = pygame.time.Clock()
    font = pygame.font.Font(None, 28)

    dtap_last = 0.0
    DTAP_WINDOW = 0.4

    frames = 0
    t0 = time.time()
    shown_fps = 0.0

    running = True
    while running:
        for e in pygame.event.get():
            if e.type == pygame.KEYDOWN and e.key == pygame.K_q:
                running = False
            if e.type == pygame.MOUSEBUTTONDOWN:
                now = time.time()
                if now - dtap_last < DTAP_WINDOW:
                    running = False
                dtap_last = now

        ok, frame = cap.read()
        if not ok:
            time.sleep(0.05)
            continue

        frame = rotate_and_mirror(frame, args.rotate, args.mirror)
        # BGR->RGB
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        ih, iw = frame.shape[:2]
        scale = min(sw / iw, sh / ih)
        new_size = (max(1, int(iw * scale)), max(1, int(ih * scale)))

        surf = pygame.image.frombuffer(frame.tobytes(), (iw, ih), "RGB")
        surf = pygame.transform.smoothscale(surf, new_size)
        x = (sw - new_size[0]) // 2
        y = (sh - new_size[1]) // 2

        screen.fill((0, 0, 0))
        screen.blit(surf, (x, y))

        frames += 1
        if frames % 15 == 0:
            dt = time.time() - t0
            shown_fps = frames / dt if dt > 0 else 0.0

        if args.debug:
            overlay = font.render(f"{dev}  {shown_fps:0.1f} FPS", True, (255, 255, 255))
            screen.blit(overlay, (8, 8))

        pygame.display.flip()
        clock.tick(args.fps if args.fps > 0 else 60)

    cap.release()
    pygame.quit()

if __name__ == "__main__":
    main()
