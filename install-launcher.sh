#!/usr/bin/env bash
# Build the launcher and install it on the TV as the default home screen.
# Usage: ./install-launcher.sh [--no-build]
# Undo with ./restore.sh (re-selects the original launcher and uninstalls this one).
set -euo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SERIAL:?set it to your TV address first, e.g. export ANDROID_SERIAL=<tv-ip>:5555}"; export ANDROID_SERIAL
# JDK 17: use JAVA_HOME if set, else Homebrew's openjdk@17 if present, else whatever `java` is on PATH.
[ -z "${JAVA_HOME:-}" ] && [ -d /opt/homebrew/opt/openjdk@17 ] && export JAVA_HOME=/opt/homebrew/opt/openjdk@17
GRADLE="${GRADLE:-gradle}"   # Gradle 8.x (brew install gradle@8)
APK=launcher/app/build/outputs/apk/debug/app-debug.apk
HOME_ACTIVITY=com.aryan.home/com.gathin.tvhome.MainActivity

if [ "${1:-}" != "--no-build" ]; then
  if [ ! -f launcher/local.properties ]; then
    SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    if [ -z "$SDK" ]; then
      for d in /opt/homebrew/share/android-commandlinetools "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
        [ -d "$d" ] && { SDK=$d; break; }
      done
    fi
    [ -n "$SDK" ] || { echo "Android SDK not found: set ANDROID_HOME"; exit 1; }
    echo "sdk.dir=$SDK" > launcher/local.properties
  fi
  (cd launcher && "$GRADLE" assembleDebug -q --console=plain)
fi

adb get-state >/dev/null 2>&1 || adb connect "$ANDROID_SERIAL" >/dev/null || true
[ "$(adb get-state 2>/dev/null)" = device ] || { echo "TV not connected"; exit 1; }
adb install -r "$APK"
adb shell cmd package set-home-activity --user 0 "$HOME_ACTIVITY"
adb shell input keyevent KEYCODE_HOME
echo "Installed. Press Home on the remote to see it."
