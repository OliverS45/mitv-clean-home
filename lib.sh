# shellcheck shell=bash
# Shared setup, sourced by the scripts in this folder (not run on its own).
# Moves to the repo folder, checks ANDROID_SERIAL and defines the helpers below.
cd "$(dirname "$0")" || exit 1
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL

# Connect to the TV over wireless ADB, or exit if it can't be reached.
connect_tv() {
  adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null || true
  [ "$(adb get-state 2>/dev/null)" = device ] || { echo "TV not connected"; exit 1; }
}

# Run adb, or with DRY=1 only print what would run.
run() { if [ "${DRY:-0}" = 1 ]; then echo "would: adb $*"; else adb "$@"; fi; }

# Package names from a list file such as debloat.txt (first word per line; comments and blanks skipped).
list_packages() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }
