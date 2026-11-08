#!/usr/bin/env bash
# List packages still enabled on the TV that debloat.txt doesn't cover, to help pick what to disable next.
# Read-only: it changes nothing. Core Android/Google and the kept Xiaomi services are left out.
# Usage: ./find-bloat.sh [list-file]   (default list: debloat.txt)
set -uo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL
LIST="${1:-debloat.txt}"

# Never suggested: the OS, Play services, setup, casting, the remote, Ambient Mode, OTA, HDMI/Live TV, this launcher.
KEEP='^(android|com\.android\..*|com\.google\.android\.(gms|gsf|webview|tungsten\..*|tvsetup.*|apps\.mediashell|tv\.remote\.service|backdrop|inputmethod\..*|ext\..*|modulemetadata|networkstack.*|permissioncontroller|packageinstaller)|com\.xiaomi\.mitv\.updateservice|.*tvservice.*|com\.mitv\.service|.*droidlogic.*|com\.aryan\.home)$'
# Names that usually mean ads, tracking or silent installs.
SUSPECT='(^|\.)ads?(\.|$)|adserv|advert|analytic|statistic|telemetry|feedback|tracker|partner|promo|recommend|autoinstall|sponsor|webcontent|channel'

adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null
[ "$(adb get-state 2>/dev/null)" = device ] || { echo "TV not connected"; exit 1; }

listed=$(grep -vE '^\s*(#|$)' "$LIST" | awk '{print $1}')
pkgs=$(adb shell pm list packages -e | tr -d '\r' | sed 's/^package://' | sort \
  | grep -vxF -e "${listed:-.}" | grep -vE "$KEEP")

echo "Likely ads / tracking:"
grep -iE "$SUSPECT" <<<"$pkgs" | sed 's/^/  /' || echo "  (none)"
echo
echo "Everything else still enabled (check each before adding it to $LIST):"
grep -viE "$SUSPECT" <<<"$pkgs" | sed 's/^/  /' || echo "  (none)"
