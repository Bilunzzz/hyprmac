#!/usr/bin/env python3
# Jeda wallpaper video (mpvpaper) saat workspace aktif berisi jendela,
# putar lagi saat workspace kosong. Wallpaper video yang terus bergerak
# memaksa GPU Intel menggambar ulang layar + blur 60x per detik.
#
# Butuh mpvpaper dengan input-ipc-server=$XDG_RUNTIME_DIR/mpvpaper.sock
# (lihat wallpaper.sh). SIGUSR1 = evaluasi ulang (dipakai saat video diganti).

import json
import os
import signal
import socket
import subprocess

runtime = os.environ["XDG_RUNTIME_DIR"]
mpv_sock = f"{runtime}/mpvpaper.sock"
hypr_sock = f"{runtime}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"

# Event Hyprland yang bisa mengubah isi workspace yang terlihat
EVENTS = {
    "workspace", "workspacev2", "focusedmon", "focusedmonv2", "openwindow",
    "closewindow", "movewindow", "movewindowv2", "fullscreen",
    "activespecial", "activespecialv2", "changefloatingmode",
}


def workspace_has_windows() -> bool:
    out = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True)
    try:
        return json.loads(out.stdout).get("windows", 0) > 0
    except json.JSONDecodeError:
        return True


def set_pause(pause: bool) -> None:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(mpv_sock)
            s.sendall(json.dumps({"command": ["set_property", "pause", pause]}).encode() + b"\n")
    except OSError:
        pass  # mpvpaper belum/tidak jalan


def update(*_):
    set_pause(workspace_has_windows())


signal.signal(signal.SIGUSR1, update)
update()

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(hypr_sock)
    buf = b""
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        buf += chunk
        *lines, buf = buf.split(b"\n")
        if any(line.split(b">>", 1)[0].decode() in EVENTS for line in lines):
            update()
