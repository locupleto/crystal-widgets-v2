#!/bin/bash
#
# crystal-weather.widget by locupleto
# https://github.com/locupleto/crystal-widgets-v2
#
# Widget-specific script for crystal-weather.
#
# Fetches OpenWeatherMap current conditions at most once per
# FETCH_INTERVAL into an atomically-published JSON cache, then emits ONE
# JSON line for index.coffee. Emits NOTHING (exit 0) whenever the panel
# should stay invisible (fail-safe: no API key, no location, or no
# successful fetch has ever happened).

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Source the common configuration script
common_script="$(dirname "$0")/../crystal_common.sh"
if [ -f "$common_script" ]; then
    source "$common_script"
fi

export HTOP_TEMP_DIR=${HTOP_TEMP_DIR:-/tmp}
mkdir -p "$HTOP_TEMP_DIR"

WEATHER_UNITS=${WEATHER_UNITS:-metric}
WEATHER_ICON_SET=${WEATHER_ICON_SET:-meteocons-line}

CACHE="$HTOP_TEMP_DIR/weather.json"    # last GOOD response (atomic mv)
STAMP="$HTOP_TEMP_DIR/weather.stamp"   # last fetch ATTEMPT (rate limiter)
LOCK="$HTOP_TEMP_DIR/weather.lock.d"   # mkdir-based fetch mutex
FETCH_INTERVAL=600                     # min seconds between API attempts
STALE_AFTER=1800                       # cache age that triggers stale hint

# ---- FAIL-SAFE: unconfigured -> no output -> panel stays hidden -----------
[ -z "$OPENWEATHERMAP_API_KEY" ] && exit 0
[ -z "$WEATHER_LOCATION" ] && exit 0

# ---- Rate-limited, mutex-guarded fetch ------------------------------------
now=$(date +%s)
stamp_age=$FETCH_INTERVAL
[ -f "$STAMP" ] && stamp_age=$(( now - $(stat -f %m "$STAMP" 2>/dev/null || echo 0) ))

if [ "$stamp_age" -ge "$FETCH_INTERVAL" ]; then
    # Reap a lock orphaned by a killed runner (a fetch takes at most ~10 s)
    [ -d "$LOCK" ] && find "$LOCK" -maxdepth 0 -mmin +2 -exec rmdir {} \; 2>/dev/null

    if mkdir "$LOCK" 2>/dev/null; then       # atomic: exactly one winner
        trap 'rmdir "$LOCK" 2>/dev/null' EXIT
        touch "$STAMP"                       # count the attempt, pass or fail

        tmp="$CACHE.tmp.$$"
        http_code=$(curl -sS -G \
            --connect-timeout 5 --max-time 10 \
            --data-urlencode "q=$WEATHER_LOCATION" \
            --data-urlencode "appid=$OPENWEATHERMAP_API_KEY" \
            --data-urlencode "units=$WEATHER_UNITS" \
            -o "$tmp" -w '%{http_code}' \
            "https://api.openweathermap.org/data/2.5/weather" 2>/dev/null)

        # Validate before publishing so a garbage body never replaces good data
        if [ "$http_code" = "200" ] && python3 -c \
            'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if int(d.get("cod",0))==200 else 1)' \
            "$tmp" 2>/dev/null; then
            mv -f "$tmp" "$CACHE"            # atomic publish, same volume
        else
            rm -f "$tmp"
            echo "crystal-weather: OWM fetch failed (HTTP ${http_code:-none}) for '$WEATHER_LOCATION'" >&2
        fi
    fi
fi

# ---- FAIL-SAFE: never had a successful fetch -> hidden --------------------
[ -f "$CACHE" ] || exit 0

# ---- Emit the one-line JSON payload for index.coffee ----------------------
python3 - "$CACHE" "$(dirname "$0")/icons" "$WEATHER_ICON_SET" "$WEATHER_UNITS" "$STALE_AFTER" <<'PYEOF'
import json, os, sys, time

cache, icons_dir, icon_set, units, stale_after = sys.argv[1:6]

try:
    with open(cache, encoding="utf-8") as f:
        w = json.load(f)
except Exception:
    sys.exit(0)                               # unreadable cache -> hidden

# OWM condition class -> (meteocons day, meteocons night, EF day, EF night).
# meteocons-line and meteocons-fill share filenames, so one table serves
# all three icon sets.
ICON_MAP = {
    "thunder":  ("thunderstorms-day", "thunderstorms-night", "wi-thunderstorm", "wi-thunderstorm"),
    "drizzle":  ("drizzle",           "drizzle",             "wi-sprinkle",     "wi-sprinkle"),
    "rain":     ("rain",              "rain",                "wi-rain",         "wi-rain"),
    "sleet":    ("sleet",             "sleet",               "wi-sleet",        "wi-sleet"),
    "snow":     ("snow",              "snow",                "wi-snow",         "wi-snow"),
    "mist":     ("mist",              "mist",                "wi-day-fog",      "wi-night-fog"),
    "smoke":    ("smoke",             "smoke",               "wi-smoke",        "wi-smoke"),
    "haze":     ("haze-day",          "haze-night",          "wi-day-haze",     "wi-night-fog"),
    "dust":     ("dust-day",          "dust-night",          "wi-dust",         "wi-dust"),
    "fog":      ("fog-day",           "fog-night",           "wi-day-fog",      "wi-night-fog"),
    "wind":     ("wind",              "wind",                "wi-strong-wind",  "wi-strong-wind"),
    "tornado":  ("tornado",           "tornado",             "wi-tornado",      "wi-tornado"),
    "clear":    ("clear-day",         "clear-night",         "wi-day-sunny",    "wi-night-clear"),
    "partly":   ("partly-cloudy-day", "partly-cloudy-night", "wi-day-cloudy",   "wi-night-alt-cloudy"),
    "broken":   ("overcast-day",      "overcast-night",      "wi-cloudy",       "wi-cloudy"),
    "overcast": ("overcast",          "overcast",            "wi-cloudy",       "wi-cloudy"),
}

def classify(cid):
    if 200 <= cid <= 232:            return "thunder"   # 2xx thunderstorm
    if 300 <= cid <= 321:            return "drizzle"   # 3xx drizzle
    if cid == 511:                   return "sleet"     # freezing rain
    if 500 <= cid <= 531:            return "rain"      # 5xx rain / showers
    if 611 <= cid <= 616:            return "sleet"     # sleet / rain+snow mix
    if 600 <= cid <= 622:            return "snow"      # snow / snow showers
    if cid == 701:                   return "mist"
    if cid == 711:                   return "smoke"
    if cid == 721:                   return "haze"
    if cid in (731, 751, 761, 762): return "dust"      # dust whirls/sand/dust/ash
    if cid == 741:                   return "fog"
    if cid == 771:                   return "wind"      # squall
    if cid == 781:                   return "tornado"
    if cid == 800:                   return "clear"
    if cid in (801, 802):           return "partly"    # few / scattered clouds
    if cid == 803:                   return "broken"    # broken clouds
    return "overcast"                                   # 804 + forward-compatible fallback

cid = int(w["weather"][0]["id"])
is_day = not w["weather"][0].get("icon", "01d").endswith("n")
m_day, m_night, wi_day, wi_night = ICON_MAP[classify(cid)]
if icon_set == "weather-icons":
    name, fallback = (wi_day if is_day else wi_night), "wi-cloudy"
else:
    name, fallback = (m_day if is_day else m_night), "cloudy"

svg = ""
for cand in (name, fallback):
    p = os.path.join(icons_dir, icon_set, cand + ".svg")
    if os.path.isfile(p):
        with open(p, encoding="utf-8") as f:
            svg = f.read()
        break

speed_unit = "m/s" if units == "metric" else "mph"
wind_src = w.get("wind", {})
compass = ""
if wind_src.get("deg") is not None:
    pts = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    compass = " " + pts[int((wind_src["deg"] + 22.5) // 45) % 8]

age = int(time.time() - os.path.getmtime(cache))

print(json.dumps({
    "status":    "ok",
    "city":      w.get("name", ""),
    "temp":      "%d°" % round(w["main"]["temp"]),
    "condition": w["weather"][0].get("description", "").capitalize(),
    "feels":     "%d°" % round(w["main"]["feels_like"]),
    "humidity":  "%d%%" % w["main"]["humidity"],
    "wind":      "%.1f %s%s" % (wind_src.get("speed", 0), speed_unit, compass),
    "icon_set":  icon_set,
    "icon_svg":  svg,
    "stale":     age > int(stale_after),
    "age_min":   age // 60,
}))
PYEOF
exit 0
