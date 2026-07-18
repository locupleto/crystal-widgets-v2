# Crystal Widgets — Übersicht Setup on a Mac

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
crystal-widgets-v2.widget.zip  Self-contained bundle (widgets + prebuilt sampler binary)
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

## What changed since v1?

The widgets themselves — look, layout, refresh behaviour — are unchanged
from [crystal-widgets](https://github.com/locupleto/crystal-widgets) v1.
What changed is everything behind them:

| | v1 (crystal-widgets) | v2 (this repo) |
|---|---|---|
| Metrics producer | [crystal-htop](https://github.com/locupleto/crystal-htop), a patched htop fork | `crystal_sampler`, ~300 lines of C reading Mach/sysctl APIs directly |
| Process lifecycle | started by widget scripts into a hidden `screen` session | `launchd` agent (starts at login, restarts after crashes); widget scripts remain as fallback |
| File writes | direct writes (readers could catch a torn/partial file) | temp-name + atomic `rename()` — readers always see a complete snapshot |
| Consistency | each metric in its own file, written at different moments | plus `metrics.json`: one snapshot with all metrics from the same instant |
| Staleness detection | none — a dead producer meant silently frozen numbers | `metrics.json` carries a `timestamp` heartbeat |
| Dependencies | prebuilt htop binaries per arch, `htoprc`, `screen`, brew `flock` | one universal binary; `flock`/`screen`/`htoprc` all gone |
| Maintenance | rebase the htop patches on every upstream htop release | none — the sampler has no upstream to track |

The legacy `htop_*.txt` file names and formats are still published, so v1
widgets (or any other consumer of those files) keep working unmodified.

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

Create the metrics directory: `mkdir -p ~/tmp`. Bar colors are configured
in the same file.

> **Keep `HTOP_TEMP_DIR` on the boot volume.** If it points at an external
> drive (anything under `/Volumes/...`), macOS shows a
> *"crystal_sampler would like to access files on a removable volume"*
> consent dialog the first time the sampler writes there. Worse, the
> approval is tied to the exact binary: `crystal_sampler` is only ad-hoc
> signed, so every rebuild produces a new code signature and macOS asks
> again. A path on the internal disk (such as the default `$HOME/tmp`)
> never triggers the dialog — the files are tiny, so there is no benefit
> to keeping them on an external drive. If you must use one, click
> **Allow** and expect a re-prompt after each rebuild (the grant lives
> under *System Settings → Privacy & Security → Files & Folders*).

### Week start day (calendar widget)

The calendar widget reads `START_DAY_OF_WEEK` from `crystal_common.sh`.
The shipped config sets it to `MONDAY` (ISO/European convention):

```bash
export START_DAY_OF_WEEK="MONDAY"
```

US users who prefer weeks starting on Sunday should set it to `"SUNDAY"`
— or simply delete the line, since the widget defaults to Sunday when the
variable is unset. Any value other than `SUNDAY` means Monday-first.

## 6. Point Übersicht at the widgets folder

Übersicht stores its "Widgets Folder" preference as a machine-specific
security-scoped bookmark, so it cannot be copied between Macs. Either pick
the folder once in Übersicht → Preferences, or symlink the default
location (no UI interaction needed):

```bash
osascript -e 'tell application "Übersicht" to quit' 2>/dev/null
mkdir -p "$HOME/Library/Application Support/Übersicht"   # absent until first launch
rm -rf "$HOME/Library/Application Support/Übersicht/widgets"
ln -s "$HOME/config/ubersicht" "$HOME/Library/Application Support/Übersicht/widgets"
```

> **If Übersicht ever ran on this machine before**, a previously chosen
> widgets folder is stored in its preferences and overrides the symlink.
> Quit Übersicht first, then clear it:
> `defaults delete tracesOf.Uebersicht widgetDirectory`

Optional, to mirror the reference preferences (interaction off, no bash env):

```bash
defaults write tracesOf.Uebersicht enableInteraction -bool false
defaults write tracesOf.Uebersicht loginShell -bool false
```

## 7. Launch Übersicht at login

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

## 8. Start and verify

```bash
open -a "Übersicht"
sleep 5
pgrep -x crystal_sampler          # the daemon is running
cat ~/tmp/metrics.json            # fresh timestamp, live numbers
ls ~/tmp/htop_*                   # legacy files for the widgets
```

> On the very first launch macOS shows the standard Gatekeeper prompt
> ("downloaded from the Internet") — click **Open**. Until it is confirmed
> the app will not start, which over SSH looks like `open` silently doing
> nothing.

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

## Upgrading from v1

If the machine already runs the original
[crystal-widgets](https://github.com/locupleto/crystal-widgets) (widgets in
`~/config/ubersicht`, crystal-htop in a `screen` session), the upgrade is a
short in-place operation — Übersicht itself keeps running throughout:

```bash
git clone https://github.com/locupleto/crystal-widgets-v2.git
cd crystal-widgets-v2

# 1. Refresh the widgets and support scripts in place
cp -R widgets/. ~/config/ubersicht/

# 2. Build and install the sampler (steps 3-4 of the fresh install)
(cd sampler && make && cp crystal_sampler ~/config/ubersicht/)
sed -e "s/URBAN/$USER/g" launchd/org.ottosson.crystal-sampler.plist \
  > ~/Library/LaunchAgents/org.ottosson.crystal-sampler.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.ottosson.crystal-sampler.plist

# 3. Retire v1: stop crystal-htop and delete its binaries
screen -X -S crystal_htop_session quit
rm -f ~/config/ubersicht/crystal_htop_arm64 ~/config/ubersicht/crystal_htop_x86

# 4. Re-apply your machine settings in ~/config/ubersicht/crystal_common.sh
#    (step 1 overwrote it): HTOP_TEMP_DIR, FASTFETCH_CMD, bar colors,
#    START_DAY_OF_WEEK. v1 defaulted HTOP_TEMP_DIR to /tmp; the v2 default
#    is $HOME/tmp — either works, it just must match the LaunchAgent plist.
```

Notes:

- **Keep the existing widgets-folder preference.** Übersicht already points
  at `~/config/ubersicht`; the symlink from step 6 is only for machines
  where Übersicht was never configured. Do NOT clear `widgetDirectory` on
  an upgrade.
- The widgets are unchanged between v1 and v2, so nothing needs
  repositioning; on the next refresh cycle they read the sampler's files
  instead of crystal-htop's.
- Stale v1 files in the old temp dir (`htop_htoprc`,
  `htop_session_list.txt`, `htop_kernel_tasks.txt`, `htop_uptime_.txt`)
  are no longer used and can be deleted.

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
| Recurring "access files on a removable volume" popup | `HTOP_TEMP_DIR` points at an external drive — move it to the boot volume (see step 5), or click Allow after every sampler rebuild |

## Proven on

This exact guide has been executed end-to-end on every Mac below — spanning
12 years of hardware, both CPU architectures, and five macOS releases from
Monterey to Tahoe. The sampler builds from source on all of them with the
same `make` invocation (universal binary), and the same widgets run
unmodified everywhere:

| Machine | CPU | RAM | macOS | Install type |
|---------|-----|-----|-------|--------------|
| Mac Studio (2022) | Apple M1 Ultra, 20 cores | 64 GB | 26 Tahoe | in-place migration from v1 |
| MacBook Pro | Apple M3 Pro, 12 cores | 36 GB | 26 Tahoe | in-place migration from v1 |
| Mac mini | Apple M4, 10 cores | 32 GB | 26 Tahoe | fresh install (headless, over SSH) |
| MacBook Air (2017) | Intel Core i5, 2 cores | 8 GB | 12 Monterey | fresh install |
| Mac Pro (2013) | Intel Xeon E5-1650 v2, 6 cores | 64 GB | 12 Monterey | upgrade from v1 |

If it runs on a 2013 trashcan Mac Pro and an M4 mini alike, it will most
likely run on yours.
