# pi-endoscope-tft (simple)

Tiny viewer that opens a USB endoscope (UVC) on a Raspberry Pi and displays it
full-screen on an Inland/Waveshare-style 3.5" TFT HAT. If `/dev/fb1` is not
present, it renders to the default display (HDMI).

## Install (on the Pi)

```bash
git clone https://github.com/lukehami55/frisbee.git
cd frisbee
sudo ./scripts/install.sh
```

The installer will:

* create/update a Python virtual environment in the repo (`.venv`)
* install the `endoscope-viewer.service` unit, pointing it at the
  `scripts/run_service.sh` wrapper
* restart the service so the new bits take effect immediately

## Updating an existing install

After pulling new code, re-run the installer so the service picks up any
changes:

```bash
cd /home/pi/frisbee
git pull
sudo ./scripts/install.sh
```

That ensures the systemd unit and virtualenv match the working tree. If you
prefer to update the service manually, copy
`systemd/endoscope-viewer.service` to `/etc/systemd/system/`, replace the
`__USER__`/`__WORKDIR__` placeholders, then run `sudo systemctl daemon-reload`
followed by `sudo systemctl restart endoscope-viewer.service`.

## Troubleshooting

* Check the logs while the service runs:

  ```bash
  sudo journalctl -u endoscope-viewer.service -f
  ```

  The `run_service.sh` wrapper and the viewer now print their configuration
  decisions (which interpreter is used, SDL framebuffer selection, camera
  device, etc.) to make it easier to spot misconfigurations.

* If the service complains about missing Python modules, the virtualenv may not
  have been created. Re-run `sudo ./scripts/install.sh`.

* To experiment interactively without the service, activate the virtualenv and
  run the viewer by hand:

  ```bash
  source .venv/bin/activate
  python -m src.camera_viewer --debug
  ```

  Use `Ctrl+C` or tap the screen twice quickly to exit.
