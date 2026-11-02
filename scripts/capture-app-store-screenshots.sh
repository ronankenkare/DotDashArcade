#!/bin/bash
# Captures the App Store screenshot set on one or more iOS simulators.
#
#   scripts/capture-app-store-screenshots.sh [-v VERSION] [-r ORIENTATION] [-o OUT_DIR] [DEVICE ...]
#
#   -v VERSION      App_Store_Info version folder, e.g. 2026.11.02 or v2026.11.02
#                   (default: today). Created if it doesn't exist.
#   -r ORIENTATION  portrait, landscape or both (default: portrait). The app is
#                   portrait-only on iPhone, so iPhones skip landscape.
#   -o OUT_DIR      Write here instead of App_Store_Info/vVERSION/screenshots.
#
# DEVICE is a simulator name ("iPhone 18 Pro Max") or UDID. A name resolves to
# the newest available runtime. Defaults to the App Store's required sizes:
# "iPhone 18 Pro Max" (6.9") and "iPad Pro 13-inch (M5)" (13").
#
# Output: App_Store_Info/vVERSION/screenshots/<device>/<orientation>/, e.g.
# iphone-18-pro-max/portrait/01-gameplay-hit.png.
#
# The game states are staged by a Debug-only hook
# (scripts/app-store-screenshots/) that is added to the source for the build
# and removed again before capture starts, so the app source is left as it was.
#
# Env: SHOT_DELAY seconds to wait after each launch (default 6).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="$ROOT/scripts/app-store-screenshots"
BUNDLE_ID="ronankenkare.dot-dash"
SHOT_DELAY="${SHOT_DELAY:-6}"
VERSION="$(date +%Y.%m.%d)"
ORIENTATION="portrait"
OUT_DIR=""

usage() { sed -n '2,/^# Env/p' "$0" | sed 's/^# \{0,1\}//'; }
while getopts "v:r:o:h" opt; do
  case $opt in
    v) VERSION="${OPTARG#v}" ;;
    r) ORIENTATION="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
case "$ORIENTATION" in
  portrait|landscape) ORIENTATIONS="$ORIENTATION" ;;
  both) ORIENTATIONS="portrait landscape" ;;
  *) echo "-r must be portrait, landscape or both (got '$ORIENTATION')." >&2; exit 2 ;;
esac
if [ -z "$VERSION" ] || ! echo "$VERSION" | grep -Eq '^[0-9A-Za-z._-]+$'; then
  echo "-v must be a version folder name like 2026.11.02 (got '$VERSION')." >&2; exit 2
fi
[ -n "$OUT_DIR" ] || OUT_DIR="$ROOT/App_Store_Info/v$VERSION/screenshots"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
if [ $# -eq 0 ]; then
  set -- "iPhone 18 Pro Max" "iPad Pro 13-inch (M5)"
fi

# file name|scene (empty = Home screen)|appearance
SHOTS="01-gameplay-hit|hit|dark
02-theme-40|theme40|dark
03-advanced|advanced|dark
04-home||dark
05-how-to-play|help|dark
06-game-over|gameover|dark
07-light-gameplay|hit|light"

# --- Build with the staging hook, then restore the source -------------------

BUILD_DIR="$(mktemp -d -t dotdash-shots)"
staged=0
unstage() {
  if [ $staged -eq 1 ]; then
    rm -f "$ROOT/dot-dash/ScreenshotStaging.swift" "$ROOT/dot-dashUITests/ScreenshotOrientationUITests.swift"
    git -C "$ROOT" apply -R "$STAGING/staging.patch"
    staged=0
  fi
}
cleanup() { unstage; rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

echo "==> Building Debug app with screenshot staging"
git -C "$ROOT" apply --check "$STAGING/staging.patch" || {
  echo "staging.patch no longer applies to GameView.swift/ContentView.swift; regenerate it." >&2
  exit 1
}
cp "$STAGING/ScreenshotStaging.swift" "$ROOT/dot-dash/ScreenshotStaging.swift"
cp "$STAGING/ScreenshotOrientationUITests.swift" "$ROOT/dot-dashUITests/ScreenshotOrientationUITests.swift"
git -C "$ROOT" apply "$STAGING/staging.patch"
staged=1
xcodebuild -project "$ROOT/dot-dash.xcodeproj" -scheme dot-dash -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$BUILD_DIR" \
  build-for-testing -quiet
unstage
APP="$BUILD_DIR/Build/Products/Debug-iphonesimulator/dot-dash.app"
XCTESTRUN="$(ls "$BUILD_DIR"/Build/Products/*.xctestrun | head -1)"

# --- Helpers ----------------------------------------------------------------

# Prints "UDID|Name|State" for a device name or UDID, preferring the newest runtime.
resolve_device() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys, re
want = sys.argv[1]
def ver(rt):
    m = re.search(r"iOS-(\d+)-(\d+)", rt)
    return tuple(map(int, m.groups())) if m else (0, 0)
hits = []
for rt, devs in json.load(sys.stdin)["devices"].items():
    for d in devs:
        if want in (d["udid"], d["name"]):
            hits.append((ver(rt), d))
if not hits:
    sys.exit(1)
d = max(hits, key=lambda h: h[0])[1]
print("%s|%s|%s" % (d["udid"], d["name"], d["state"]))
' "$1"
}

slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9.]+/-/g; s/^-|-$//g'; }

# iPads default to Windowed Apps, which adds the app name to the status bar
# and a resize grip to the corner. Switch to Full Screen Apps.
ensure_full_screen_ipad() {
  local udid=$1
  local medusa
  medusa="$(xcrun simctl spawn "$udid" defaults read com.apple.springboard SBMedusaMultitaskingEnabled 2>/dev/null || echo unset)"
  local chamois
  chamois="$(xcrun simctl spawn "$udid" defaults read com.apple.springboard SBChamoisWindowingEnabled 2>/dev/null || echo unset)"
  if [ "$medusa" != "0" ] || [ "$chamois" != "0" ]; then
    echo "    switching to Full Screen Apps (reboots the simulator)"
    xcrun simctl spawn "$udid" defaults write com.apple.springboard SBMedusaMultitaskingEnabled -bool false
    xcrun simctl spawn "$udid" defaults write com.apple.springboard SBChamoisWindowingEnabled -bool false
    xcrun simctl shutdown "$udid"
    xcrun simctl boot "$udid"
    xcrun simctl bootstatus "$udid" >/dev/null
  fi
}

# Rotates the simulated device (iPad only; the app is portrait-only on iPhone).
set_orientation() {
  local udid=$1 orientation=$2 test=testSetPortrait
  [ "$orientation" = landscape ] && test=testSetLandscape
  xcodebuild test-without-building -xctestrun "$XCTESTRUN" -destination "id=$udid" \
    -parallel-testing-enabled NO -only-testing:"dot-dashUITests/ScreenshotOrientationUITests/$test" -quiet >/dev/null 2>&1 || {
    echo "    could not rotate the simulator to $orientation" >&2; return 1; }
}

# --- Capture ----------------------------------------------------------------

# Takes the seven shots for one orientation into $2.
capture_set() {
  local udid=$1 dest=$2 orientation=$3
  mkdir -p "$dest"
  echo "$SHOTS" | while IFS='|' read -r shot scene look; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
    args=(-dotdash_best_classic_v1 47 -dotdash_best_advanced_v1 21 -dotdash_appearance_v1 "$look")
    [ -n "$scene" ] && args+=(-screenshotScene "$scene")
    xcrun simctl launch "$udid" "$BUNDLE_ID" "${args[@]}" >/dev/null
    sleep "$SHOT_DELAY"
    xcrun simctl io "$udid" screenshot --type=png "$dest/$shot.png" >/dev/null 2>&1
    local w h
    w="$(sips -g pixelWidth "$dest/$shot.png" | awk '/pixelWidth/{print $2}')"
    h="$(sips -g pixelHeight "$dest/$shot.png" | awk '/pixelHeight/{print $2}')"
    if { [ "$orientation" = landscape ] && [ "$w" -lt "$h" ]; } ||
       { [ "$orientation" = portrait ] && [ "$w" -gt "$h" ]; }; then
      echo "    $shot.png came out ${w}x${h}, not $orientation; the simulator didn't rotate." >&2
      exit 1
    fi
    echo "    $orientation/$shot.png (${w}x${h})"
  done
}

for want in "$@"; do
  info="$(resolve_device "$want")" || { echo "No available simulator named '$want'." >&2; exit 1; }
  udid="${info%%|*}"; rest="${info#*|}"; name="${rest%|*}"; state="${rest##*|}"
  device_dir="$OUT_DIR/$(slug "$name")"
  echo "==> $name ($udid) -> ${device_dir#$ROOT/}"

  booted_here=0
  if [ "$state" != "Booted" ]; then
    xcrun simctl boot "$udid"
    booted_here=1
  fi
  xcrun simctl bootstatus "$udid" >/dev/null
  case "$name" in iPad*) ensure_full_screen_ipad "$udid" ;; esac
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

  xcrun simctl install "$udid" "$APP"
  # The first launch after install is slow; warm it up so shot 01 isn't blank.
  xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null; sleep "$SHOT_DELAY"

  for orientation in $ORIENTATIONS; do
    case "$name" in
      iPhone*) if [ "$orientation" = landscape ]; then
                 echo "    skipping landscape: the app is portrait-only on iPhone"
                 continue
               fi ;;
    esac
    case "$name" in iPad*) set_orientation "$udid" "$orientation" ;; esac
    capture_set "$udid" "$device_dir/$orientation" "$orientation"
  done
  case "$name $ORIENTATIONS" in iPad*landscape*) set_orientation "$udid" portrait ;; esac

  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall "$udid" "$BUNDLE_ID"
  xcrun simctl status_bar "$udid" clear
  if [ $booted_here -eq 1 ]; then xcrun simctl shutdown "$udid"; fi
done

echo "==> Done. Screenshots are in ${OUT_DIR#$ROOT/}"
