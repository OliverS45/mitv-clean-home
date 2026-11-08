#!/usr/bin/env bash
# Free space and memory on the TV without touching app data, sign-ins or settings.
#   - clears every app's cache (pm trim-caches: the same as "Clear cache", never "Clear data")
#   - stops background apps (am kill-all: only processes that are safe to kill; nothing is disabled)
#   - with --optimize, also recompiles apps the way Android does overnight (slow: 5-20 minutes),
#     which helps after an OTA update leaves apps sluggish
# Prints free storage and RAM before and after. Safe to run any time; the cache refills as you use apps.
# Usage: ./tune-up.sh [--dry-run] [--optimize]
set -uo pipefail
. "$(dirname "$0")/lib.sh"

DRY=0 OPT=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --optimize) OPT=1 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done

connect_tv

report() {
  local free ram
  free=$(adb shell df -h /data 2>/dev/null | tr -d '\r' | awk 'NR==2 {print $4}')
  ram=$(adb shell cat /proc/meminfo 2>/dev/null | tr -d '\r' | awk '/^MemAvailable:/ {printf "%d MB", $2/1024}')
  echo "$1  storage free: ${free:-?}   RAM available: ${ram:-?}"
}

report "before:"
run shell pm trim-caches 999G
run shell am kill-all
if [ $OPT = 1 ]; then
  echo "optimizing apps (this takes a while; the TV stays usable)..."
  run shell cmd package bg-dexopt-job
fi
[ $DRY = 1 ] && { echo "dry run, nothing changed"; exit 0; }
sleep 2
report "after: "
