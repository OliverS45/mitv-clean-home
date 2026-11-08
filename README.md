# Ad-free home screen for a Xiaomi Mi TV

My Xiaomi Mi TV (MiTV-AXSO2, Android TV 11) was slow and full of ads. Over wireless ADB I:

- **Backed up** the package list, system settings and the original home screen before changing anything.
- **Disabled 29 ad, telemetry and bloatware packages**, one at a time, with a crash check after each that rolls the change back if anything breaks. Nothing is uninstalled.
- **Replaced the home screen** with an Apple TV-style launcher: a frosted-glass dock of favourite apps over rotating public-domain nature wallpapers. It asks for **no permissions**: no internet, no location, no tracking.
- **Wrote a one-command restore**, with a dry-run mode, that undoes all of it.

## Results

| | Before | After |
|---|---|---|
| Home screen memory | 125 MB (PatchWall) | ~38 MB |
| Used RAM | 1,131 MB | 1,008 MB |
| Google Assistant, Xiaomi analytics | running | off |
| Sponsored rows / promo banners | yes | none |

Kept on purpose: Xiaomi OTA (security updates), HDMI / Live TV inputs, Chromecast, and Google's Ambient Mode screensaver (Google Photos).

## Setup

On the TV: Settings → Device Preferences → About → press **Build** 7 times, then Developer options → turn on **ADB debugging**.

On a Mac (on Linux, install the same tools with your package manager and set `ANDROID_HOME` to your SDK):

```bash
brew install android-platform-tools openjdk@17 gradle@8
brew install --cask android-commandlinetools
sdkmanager "platforms;android-34" "build-tools;34.0.0"
```

Every script reads the TV's address from `ANDROID_SERIAL`:

```bash
export ANDROID_SERIAL=<tv-ip>:5555
adb connect $ANDROID_SERIAL            # accept the prompt on the TV
```

## Usage

**1. Back up first.** `restore.sh` reads the original home screen from `backup/*/home_launcher.txt`, so record it before running anything else:

```bash
mkdir -p backup/original && cd backup/original
adb shell pm list packages -f > packages_all.txt
for ns in global secure system; do adb shell settings list $ns > settings_$ns.txt; done
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME > home_launcher.txt
cd ../..
```

**2. Debloat, then install the launcher.** Check the dry run's list before running it for real:

```bash
./debloat.sh --dry-run
./debloat.sh
./install-launcher.sh
```

**3. Any time later:**

```bash
./find-bloat.sh      # see what else is still enabled
./tune-up.sh         # when the TV feels slow or storage is low
```

**To undo everything:**

```bash
./restore.sh --dry-run
./restore.sh
```

## Files

| File | What it does |
|---|---|
| `debloat.txt` | The package list, grouped and commented. Edit to taste. |
| `debloat.sh [--dry-run] [list-file]` | Disables each listed package (`pm disable-user`), checks for crashes, rolls back if anything breaks, and logs what it disabled to `state/disabled.log`. |
| `install-launcher.sh [--no-build]` | Builds the launcher and sets it as the default home screen. `--no-build` installs the last build. |
| `find-bloat.sh [list-file]` | Read-only. Lists packages still enabled on the TV that the list doesn't cover, likely ads/tracking first. |
| `tune-up.sh [--dry-run] [--optimize]` | Clears app caches and stops background apps (app data, sign-ins and settings are untouched), and shows free storage and RAM before and after. `--optimize` also recompiles apps (5–20 minutes), which helps after an OTA update. |
| `restore.sh [--dry-run]` | Re-enables everything in `state/disabled.log`, restores the original home screen and uninstalls the custom launcher. |
| `lib.sh` | Shared setup the scripts load: the `ANDROID_SERIAL` check, connecting to the TV and the dry-run helper. |
| `launcher/` | The launcher (Java). |

`backup/` and `state/` hold data specific to your TV and are kept out of git.

## The launcher

Edit `launcher/app/src/main/res/values/config.xml`, then run `./install-launcher.sh`. It sets:

- the dock apps, in order (missing apps are skipped)
- apps hidden from the grid
- the Live TV app shown in the Inputs menu
- the name in the greeting
- tiles per row
- the wallpapers and how often they change

It also includes a clock screensaver: a drifting clock on black, so nothing burns in. Pick it in the TV's screensaver settings, or run:

```bash
adb shell settings put secure screensaver_components com.aryan.home/com.gathin.tvhome.ClockDream
```

The Google TV launcher (`com.google.android.tvlauncher`) has a higher home-screen priority than any app you install, so it has to be disabled for the custom launcher to stay the default. It's in `debloat.txt`, and `restore.sh` re-enables it.

## Credits

- The launcher is adapted from [vishalsingh2972/Claude-TV](https://github.com/vishalsingh2972/Claude-TV) (MIT, see `launcher/LICENSE-claude-tv`). Changes: rotating wallpapers, a frosted-glass dock, all permissions removed and a 5-app dock.
- Wallpapers: public domain / CC0 from Wikimedia Commons, see `launcher/WALLPAPER-CREDITS.txt`.
- Font: Outfit (OFL, `launcher/FONT-LICENSE-OFL.txt`).
- Built with [Claude Code](https://claude.com/claude-code).
