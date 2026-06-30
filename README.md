# Power Tab Editor — noVNC Container

Runs [Power Tab Editor](https://github.com/powertab/powertabeditor) (a desktop
Qt6 guitar-tablature editor) headlessly in a container and serves its GUI to a
web browser via noVNC. Built for a clean, start/stoppable, throwaway
transcription environment managed through Portainer.

- **Access:** a web browser (e.g. Firefox) — no audio/MIDI, transcription only
- **Persistence:** your tab files live on the host via a bind mount; the
  container itself is disposable

## How it works

The image builds Power Tab Editor from source, then `start.sh` brings up a
headless display chain:

```
Xvfb (virtual screen) → openbox (window manager) → x11vnc (serves the screen)
→ websockify/noVNC (bridges it to a web page) → powertabeditor
```

You open the noVNC page in a browser; the editor window appears there. When the
editor closes, the container exits — giving clean start/stop semantics.

## Files

| File                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| `Dockerfile`         | Builds the image: clones + compiles Power Tab Editor, installs the headless display stack |
| `start.sh`           | Launches Xvfb, openbox, x11vnc, noVNC, and the editor          |
| `docker-compose.yml` | Stack definition: build, port mapping, screen resolution, tab volume |

## Configuration

Edit `docker-compose.yml` before deploying:

- **`ports`** — `"6660:6080"` is `host:container`. Change the **left** number
  (6660) to whatever host port you want; leave the container side (6080) alone.
- **`SCREEN_RES`** — set to the resolution of the screen you'll view it on
  (default `1920x1080`).
- **`volumes`** — `/home/danko/powertab:/tabs` is `host:container`. Change the
  **left** path to where you want your `.ptb` / `.gp` files stored on the
  Docker host. Create that directory first (`mkdir -p <path>`).

## Deploy via Portainer (Git stack)

Portainer clones this repo and builds the image itself, so the only thing it
needs is the repo URL.

1. **Stacks → Add stack → Repository**
2. Fill in:
   - **Name:** `powertab`
   - **Repository URL:** the HTTPS URL of this repo
   - **Reference:** `refs/heads/main`
   - **Compose path:** `docker-compose.yml`
   - **Authentication:** enable if the repo is **private**, and supply your
     GitHub username + a Personal Access Token (PAT) with `repo` scope
3. Click **Deploy the stack**.

The first deploy runs the full build (cloning Power Tab Editor and compiling
C++/Qt6) and takes roughly **10–15 minutes**. Watch progress under
**Stacks → powertab**; the `powertab` container only appears in the
**Containers** list once the build finishes and it starts.

### Open it

In a browser on the viewing screen:

```
http://<docker-host>:6660/vnc.html?autoconnect=1&resize=scale
```

- `<docker-host>` is `localhost` if the browser runs on the Docker host,
  otherwise the host's LAN IP.
- Press **F11** for fullscreen — a dedicated Power Tab "screen."

### Start / stop

Use the **Stacks** (or **Containers**) page in Portainer to stop and start the
container on demand. It's designed to be off when not in use.

### Updating after a code change

When you change a file and push it to GitHub:

1. **Stacks → powertab → Pull and redeploy**
2. **Enable the re-pull / rebuild image option** — otherwise Portainer reuses
   the cached image and your change won't take effect.

> **Important:** edits only reach the build via GitHub. Editing files on your
> workstation does nothing until you `git push`, and Portainer must rebuild to
> pick them up.

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `reference not found` when deploying | Portainer's **Reference** isn't `refs/heads/main`, or a private repo is missing **Authentication** (username + PAT). |
| Build fails at `cmake .. && make` with `CMAKE_MAKE_PROGRAM is not set` | Build tools missing — the Dockerfile installs `build-essential` (gcc/g++/make) to cover this. |
| `no Qt platform plugin could be initialized` / `Server is already active for display 0` on restart | Stale X lock from a previous run. `start.sh` clears `/tmp/.X0-lock` and the X socket dir on every start. If you still see it, you're running an **old image** — rebuild (don't just `docker start` an old container). |
| Change pushed but not reflected | Portainer reused the cached image. Redeploy with the **rebuild image** option enabled. |

## Local build (optional)

To build/test on the Docker host directly instead of through Portainer:

```bash
docker build -t powertab-novnc .
docker run -d --name powertab -p 6660:6080 \
  -e SCREEN_RES=1920x1080 \
  -v /home/danko/powertab:/tabs \
  powertab-novnc
# browser → http://localhost:6660/vnc.html?autoconnect=1&resize=scale
docker rm -f powertab   # tear down
```

## Credits & license

This repository only **packages** Power Tab Editor for containerized use — it
contains the `Dockerfile`, `start.sh`, and `docker-compose.yml`, not the editor
itself. All credit for the application goes to the upstream project:

- **Power Tab Editor** — <https://github.com/powertab/powertabeditor>

Power Tab Editor is distributed under the **GNU General Public License v3.0**
(GPL-3.0). The image builds it from source, so the resulting container includes
GPL-3.0 software; your use of it is subject to that license. See the upstream
[LICENSE](https://github.com/powertab/powertabeditor/blob/master/LICENSE) for
details.

The packaging files in this repository are provided as-is for convenience.

