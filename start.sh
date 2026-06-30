#!/bin/bash
set -e
export DISPLAY=:0
RES="${SCREEN_RES:-1920x1080}"

Xvfb :0 -screen 0 "${RES}x24" &
sleep 1
openbox &
x11vnc -display :0 -nopw -forever -shared -rfbport 5900 -quiet &
websockify --web=/usr/share/novnc 6080 localhost:5900 &

# When PowerTab closes, the container exits — clean start/stop semantics
exec /src/build/bin/powertabeditor "$@"
