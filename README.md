# Crystal Widgets — Übersicht Setup on a New Mac

Step-by-step guide to get the custom crystal widget suite (analog clock,
calendar, htop CPU/memory/swap/load bars, system profiler, top-CPU/top-mem)
running on a fresh Mac, mirroring the reference setup on the Mac Studio.

The widgets are driven by [crystal-htop](https://github.com/locupleto/crystal-htop),
a fork of htop that exports its metrics to plain-text files in real time.
Pre-compiled binaries (`crystal_htop_arm64` and `crystal_htop_x86`) are shipped
inside the widgets folder itself — no compilation needed on the target machine.

## Overview

```
~/config/ubersicht/                     <- widgets folder (copied from an existing machine)
├── crystal_common.sh                   <- machine-specific settings (EDIT THIS)
├── crystal_htop_runner.sh              <- starts crystal_htop in a screen session
├── crystal_htop_arm64                  <- pre-built binary (Apple Silicon)
├── crystal_htop_x86                    <- pre-built binary (Intel)
├── crystal-analog-clock.widget/
├── crystal-calendar.widget/
├── crystal-htop-cpu-bar.widget/
├── crystal-htop-load.widget/
├── crystal-htop-mem-bar.widget/
├── crystal-htop-swap-bar.widget/
├── crystal-system-profiler.widget/
├── crystal-top-cpu.widget/
└── crystal-top-mem.widget/

$HTOP_TEMP_DIR/                         <- crystal_htop writes metric files here
├── htop_htoprc                         <- htop configuration (copy from existing machine)
├── htop_cpu_001.txt ... htop_cpu_NNN.txt
├── htop_load_avg_*.txt, htop_mem_*.txt, ...
```

## 1. Prerequisites

Install [Homebrew](https://brew.sh) if not present, then:

```bash
brew install --cask ubersicht   # the Übersicht app itself
brew install flock              # single-instance locking used by the runner script
brew install fastfetch          # used by the system-profiler widget
```

`screen` ships with macOS (`/usr/bin/screen`) — nothing to install.

> Note: the `ubersicht` cask is marked `auto_updates`, so `brew upgrade`
> skips it by default. Use `brew upgrade --cask --greedy ubersicht` to force
> an upgrade through brew.

## 2. Copy the widgets folder

From a machine that already has the setup (e.g. the Mac Studio):

```bash
# run ON the source machine
rsync -av --exclude .DS_Store ~/config/ubersicht/ <newmac>:config/ubersicht/
```

This brings the widgets, the runner scripts, and both pre-built
`crystal_htop` binaries in one go.

## 3. Create the metrics directory and copy htoprc

`crystal_htop` needs a writable directory for its metric files. Use a
persistent one (not `/tmp`, which is wiped at reboot and would lose the
htop configuration):

```bash
# on the new machine
mkdir -p ~/tmp

# from the source machine, copy the htop config
scp $HTOP_TEMP_DIR/htop_htoprc <newmac>:tmp/htop_htoprc
# (on the Mac Studio the source path is /Volumes/Work/tmp/htop_htoprc)
```

## 4. Adapt crystal_common.sh

`~/config/ubersicht/crystal_common.sh` is the only file with
machine-specific settings. On the new machine, set:

```bash
# Working directory for htop-related widgets (defaults to /tmp if not set)
export HTOP_TEMP_DIR=/Users/<user>/tmp

# Paths to installation-specific command-line tools
export FLOCK_CMD=/opt/homebrew/bin/flock        # /usr/local/bin on Intel Macs
export FASTFETCH_CMD=/opt/homebrew/bin/fastfetch
```

Bar colors and the calendar's first day of week are also configured here.

## 5. Point Übersicht at the widgets folder

Übersicht stores its "Widgets Folder" preference as a security-scoped
bookmark (a binary blob), which cannot be copied between machines. Two
options:

**Option A — symlink (no UI interaction needed):**

```bash
osascript -e 'tell application "Übersicht" to quit' 2>/dev/null
rm -rf "$HOME/Library/Application Support/Übersicht/widgets"
ln -s "$HOME/config/ubersicht" "$HOME/Library/Application Support/Übersicht/widgets"
```

**Option B — UI:** open Übersicht → Preferences → Widgets Folder → select
`~/config/ubersicht`.

Optional, to mirror the reference preferences (interaction off, no bash env):

```bash
defaults write tracesOf.Uebersicht enableInteraction -bool false
defaults write tracesOf.Uebersicht loginShell -bool false
```

## 6. Hide the Apple desktop widgets

The stock macOS desktop widgets (clock, weather, …) visually clash with
Übersicht. Hide them (this does not delete them — re-enable any time in
System Settings → Desktop & Dock):

```bash
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
killall WindowManager
```

## 7. Launch at login

Either tick "Launch Übersicht when I login" in the app's Preferences, or
install a LaunchAgent:

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

## 8. Start and verify

```bash
open -a "Übersicht"
sleep 8

# crystal_htop should be running in a detached screen session
screen -ls                    # expect: <pid>.crystal_htop_session (Detached)

# metric files should be streaming
ls ~/tmp/htop_*               # htop_cpu_001.txt ... htop_load_avg_1.txt ...
cat ~/tmp/htop_load_avg_1.txt # a live load-average number
```

All widgets should now be visible on the desktop. Übersicht registers them
in `~/Library/Application Support/tracesOf.Uebersicht/WidgetSettings.json`
if per-widget visibility ever needs checking.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| htop widgets empty | Is the screen session running? `screen -ls`. Restart it: `screen -X -S crystal_htop_session quit`, then refresh Übersicht. |
| "Unsupported architecture" | `uname -m` must be `arm64` or `x86_64`; the runner picks the matching binary. |
| System-profiler widget empty | Is fastfetch installed at the path set in `FASTFETCH_CMD`? |
| Widgets not found | Does `~/Library/Application Support/Übersicht/widgets` resolve to the widgets folder (symlink or preference)? |
| Metric files missing after reboot | `HTOP_TEMP_DIR` must exist; recreate `~/tmp` or point to a persistent directory. |

## Related repositories

- [crystal-htop](https://github.com/locupleto/crystal-htop) — the metric-exporting htop fork (build instructions there if binaries need recompiling)
