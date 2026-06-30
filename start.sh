#!/bin/bash
set -e
export DISPLAY=:0
RES="${SCREEN_RES:-1920x1080}"

# Fully reset X state left behind when a stopped container is restarted:
# kill any leftover server and wipe the lock + socket directory.
pkill -9 Xvfb   2>/dev/null || true
pkill -9 x11vnc 2>/dev/null || true
rm -rf /tmp/.X0-lock /tmp/.X11-unix
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

Xvfb :0 -screen 0 "${RES}x24" &

# Wait for the X server socket before launching anything that needs the display
for _ in $(seq 1 50); do
    [ -S /tmp/.X11-unix/X0 ] && break
    sleep 0.1
done

openbox &
x11vnc -display :0 -nopw -forever -shared -rfbport 5900 -quiet &
websockify --web=/usr/share/novnc 6080 localhost:5900 &

# When PowerTab closes, the container exits — clean start/stop semantics
exec /src/build/bin/powertabeditor "$@"
