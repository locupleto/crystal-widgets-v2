# Crystal Widgets — Übersicht Setup on a New Mac

Complete kit for the custom crystal widget suite (analog clock, calendar,
htop-style CPU/memory/swap/load bars, system profiler, top-CPU/top-mem):
the widgets themselves, the metrics daemon that feeds them, and step-by-step
install instructions.

![Crystal widgets on the Mac Studio desktop](docs/screenshot.png)

## Repository layout

```
widgets/                    The Übersicht widgets folder — copy to ~/config/ubersicht
sampler/                    crystal_sampler: a small C daemon that samples system metrics
launchd/                    LaunchAgent template that keeps the sampler running
widget.json                 Übersicht widget-gallery manifest
crystal-widgets.widget.zip  Self-contained bundle (widgets + prebuilt sampler binary)
screenshot.png              Gallery thumbnail (516x320); full-size in docs/
```

The zip is the quick path: unzip into your Übersicht widgets folder and the
suite works out of the box (a universal `crystal_sampler` binary is
included). The unzipped `widgets/` + `sampler/` sources remain the
reviewable, build-it-yourself path described below.

## Architecture

```
launchd agent ──> crystal_sampler (1 Hz, Mach/sysctl APIs)
                        │ atomic rename() writes
                        ▼
              $HTOP_TEMP_DIR/metrics.json      <- one consistent JSON snapshot
              $HTOP_TEMP_DIR/htop_*.txt        <- legacy per-metric files
                        ▲
                        │ read every refresh cycle
              Übersicht widgets (shell command -> stdout -> render)
```

`crystal_sampler` replaces the earlier
[crystal-htop](https://github.com/locupleto/crystal-htop) fork (a patched
htop logging to files from a `screen` session). The sampler reads the same
metrics directly from `host_processor_info` / `host_statistics64` /
`sysctl`, publishes the same file names and formats, and adds
`metrics.json` — a single atomically-renamed snapshot with a `timestamp`
heartbeat so consumers can distinguish "CPU is flat" from "sampler is dead".
Every file is written via temp-name + `rename()`, so readers never see a
torn write. A lock file enforces one instance per output directory.

## 1. Prerequisites

Install [Homebrew](https://brew.sh) and the Xcode command-line tools
(`xcode-select --install`), then:

```bash
brew install --cask ubersicht   # the Übersicht app
brew install fastfetch          # used by the system-profiler widget
```

> The `ubersicht` cask is marked `auto_updates`; `brew upgrade` skips it
> unless invoked as `brew upgrade --cask --greedy ubersicht`.

## 2. Install the widgets

```bash
mkdir -p ~/config
cp -R widgets ~/config/ubersicht
```

## 3. Build and install the sampler

```bash
cd sampler
make                                # universal arm64 + x86_64 binary
cp crystal_sampler ~/config/ubersicht/
```

## 4. Install the LaunchAgent (recommended)

The agent starts the sampler at login and restarts it after a crash. A
clean exit (another instance already holds the lock) is deliberately not
respawned.

```bash
sed -e "s/URBAN/$USER/g" launchd/org.ottosson.crystal-sampler.plist \
  > ~/Library/LaunchAgents/org.ottosson.crystal-sampler.plist
# Edit HTOP_TEMP_DIR in the installed plist if you change it in
# crystal_common.sh — the two must match.
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.ottosson.crystal-sampler.plist
```

Even without the agent the widgets remain self-healing:
`crystal_htop_runner.sh` (sourced by every htop-style widget) starts the
sampler on demand if none is running. The agent simply makes ownership of
the daemon explicit and crash-recovery immediate — belt and braces.

## 5. Adapt `crystal_common.sh`

`~/config/ubersicht/crystal_common.sh` holds the machine-specific settings:

```bash
export HTOP_TEMP_DIR=$HOME/tmp                        # metrics directory
export FASTFETCH_CMD=/opt/homebrew/bin/fastfetch      # /usr/local/bin on Intel
```

Create the metrics directory: `mkdir -p ~/tmp`. Bar colors and the
calendar's first weekday are configured in the same file.

## 6. Point Übersicht at the widgets folder

Übersicht stores its "Widgets Folder" preference as a machine-specific
security-scoped bookmark, so it cannot be copied between Macs. Either pick
the folder once in Übersicht → Preferences, or symlink the default
location (no UI interaction needed):

```bash
osascript -e 'tell application "Übersicht" to quit' 2>/dev/null
rm -rf "$HOME/Library/Application Support/Übersicht/widgets"
ln -s "$HOME/config/ubersicht" "$HOME/Library/Application Support/Übersicht/widgets"
```

Optional, to mirror the reference preferences (interaction off, no bash env):

```bash
defaults write tracesOf.Uebersicht enableInteraction -bool false
defaults write tracesOf.Uebersicht loginShell -bool false
```

## 7. Hide the stock macOS desktop widgets

They visually clash with Übersicht. This hides rather than deletes them
(revert any time in System Settings → Desktop & Dock):

```bash
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
killall WindowManager
```

## 8. Launch Übersicht at login

Tick "Launch Übersicht when I login" in the app's Preferences, or install
a LaunchAgent:

```bash
cat > ~/Library/LaunchAgents/org.ottosson.ubersicht.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.ottosson.ubersicht</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>Übersicht</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.ottosson.ubersicht.plist
```

## 9. Start and verify

```bash
open -a "Übersicht"
sleep 5
pgrep -x crystal_sampler          # the daemon is running
cat ~/tmp/metrics.json            # fresh timestamp, live numbers
ls ~/tmp/htop_*                   # legacy files for the widgets
```

All widgets should now render. Per-widget visibility is stored in
`~/Library/Application Support/tracesOf.Uebersicht/WidgetSettings.json`.

## metrics.json

```json
{
  "timestamp": 1784291741,
  "time": "2026-07-17T14:35:41+0200",
  "interval": 1.0,
  "load": [4.09, 3.57, 2.75],
  "tasks": 960,
  "threads": 5452,
  "mem": {"total_kib": 67108864, "used_kib": 32787968},
  "swap": {"total_kib": 0, "used_kib": 0},
  "cpu": [50.0, 47.5, 47.1]
}
```

`timestamp` is the staleness heartbeat: if `now - timestamp` exceeds a few
intervals, the sampler is dead and a consumer should say so instead of
rendering frozen numbers. Note: `threads` counts all Mach threads
(kernel included), so it reads higher than htop's process-thread count.

## Retired components (historical)

The original design ran a patched htop
([crystal-htop](https://github.com/locupleto/crystal-htop)) inside a
`screen` session, writing metric files continuously. The sampler replaces
all of it. No longer needed:

- `crystal_htop_arm64` / `crystal_htop_x86` binaries
- the `screen` session and `htop_htoprc`
- the brew `flock` dependency (the old runner serialized widget refreshes;
  the sampler's own lock file covers this now)

`crystal_htop_runner.sh` survives in reduced form as the on-demand
fallback starter described in step 4.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| htop widgets empty | `pgrep -x crystal_sampler`; `launchctl print gui/$(id -u)/org.ottosson.crystal-sampler` |
| Numbers frozen | `metrics.json` timestamp stale → sampler died and nothing restarted it; `launchctl kickstart gui/$(id -u)/org.ottosson.crystal-sampler` |
| System-profiler widget empty | fastfetch installed at the path in `FASTFETCH_CMD`? |
| Widgets not found | `~/Library/Application Support/Übersicht/widgets` resolves to the widgets folder? |
| Sampler exits immediately | Another instance holds `$HTOP_TEMP_DIR/crystal_sampler.lock` — that is by design |
