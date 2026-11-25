#!/usr/bin/env bash
# Installs PhoneBox on this Mac with the same screen layout as at home. Copy this one file and run, in Terminal:
#
#   bash install-mac.sh                 (add --dry-run to see what would happen, changing nothing)
#
# It downloads setup.sh and custom/layout.json from charus99/phonebox at a fixed commit, runs them only if their
# SHA-256 matches, then puts the layout's pages, shortcuts, display, night and weather settings on the agent. The
# shortcuts get Mac commands (open -a ...) in place of the Windows ones. A Mac that already had PhoneBox settings is
# asked first, and config.json is backed up. Calendar addresses are not in the layout: add them in Settings > General.
#
# Options: --layout-only (PhoneBox is installed: only the layout), --dry-run, and setup.sh's own options
# (--no-phone, --serial <id>, --no-autostart, --no-start, --no-extras, --version <x.y.z>, --yes).
# After a new layout (custom/export-layout.ps1): commit it, then change COMMIT and LAYOUT_SHA256 here.
set -euo pipefail

COMMIT=394b5ce572e8d364db32a102446a5c073a655e5b
SETUP_SHA256=21a2df56857d2d459af4aa0d6ef4f382f3164eefc2b1426dd8974cd467ce704f
LAYOUT_SHA256=1b3a4e587e5c11c6236634ed398cccd9c1ef8e8bece70f1d0d513438ce0411ef
RAW="https://raw.githubusercontent.com/charus99/phonebox/$COMMIT"

port=8765
config="$HOME/Library/Application Support/PhoneBox/config.json"
layout_only=0; dry=0; yes=0; no_start=0
setup_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --layout-only) layout_only=1 ;;
    --port) port="$2"; shift ;;        # for testing against a second agent
    --config) config="$2"; shift ;;    # for testing: that agent's config.json
    --dry-run) dry=1; setup_args+=("$1") ;;
    --yes|-y) yes=1; setup_args+=("$1") ;;
    --no-start) no_start=1; setup_args+=("$1") ;;
    --serial|--version) setup_args+=("$1" "$2"); shift ;;
    *) setup_args+=("$1") ;;
  esac
  shift
done
base="http://127.0.0.1:$port"

say() { printf '    %s\n' "$1"; }
die() { printf '\nStopped: %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || [ "${PHONEBOX_TEST_NOT_MAC:-}" = 1 ] || die "this file is for macOS; on Windows use install-pc.cmd."

tmp="$(mktemp -d "${TMPDIR:-/tmp}/phonebox-install.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fetch() { # fetch path sha256 -> the checked file's path
  local file="$tmp/$(basename "$1")" actual
  curl -fsSL --retry 3 --proto '=https' -o "$file" "$RAW/$1" || die "could not download $1."
  actual="$(shasum -a 256 "$file" | cut -d' ' -f1)"
  [ "$actual" = "$2" ] || die "$1 at $COMMIT does not match its expected SHA-256; nothing was changed by this step."
  printf '%s' "$file"
}

# The JSON work runs in JavaScript for Automation, which every Mac has (no Python or jq needed).
# same <current> <layout>          -> prints "same" or "different"
# merge <current> <layout> <out>   -> writes the current settings with the layout's sections put in
cat > "$tmp/layout.js" <<'JS'
ObjC.import('Foundation');
const SECTIONS = ['pages', 'shortcuts', 'display', 'night', 'weather'];
// the layout's Windows shortcuts, as on PhoneBox's own macOS defaults (config.default.macos.json); others stay as they are
const MAC = {
  terminal: { cmd: 'open', args: '-a Terminal' },
  explorer: { cmd: 'open', args: '~' },
  vscode: { cmd: 'open', args: '-a "Visual Studio Code"' },
  spotify: { cmd: 'open', args: '-a Spotify' },
  calc: { cmd: 'open', args: '-a Calculator' },
  settings: { cmd: 'open', args: '-a "System Settings"' },
  snip: { cmd: 'open', args: '-a Screenshot' },
  taskmgr: { cmd: 'open', args: '-a "Activity Monitor"' },
};
function readText(path) {
  const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
  if (text.isNil()) throw new Error('cannot read ' + path);
  return text.js;
}
function macLayout(layout) {
  layout.shortcuts = layout.shortcuts.map((s) => (MAC[s.id] ? Object.assign({}, s, MAC[s.id]) : s));
  return layout;
}
// the agent may order fields differently or leave empty ones out
function canon(v) {
  if (Array.isArray(v)) return v.map(canon);
  if (v && typeof v === 'object') {
    const o = {};
    Object.keys(v).sort().forEach((k) => { if (v[k] !== null) o[k] = canon(v[k]); });
    return o;
  }
  return v;
}
function run(argv) {
  const current = JSON.parse(readText(argv[1]));
  const layout = macLayout(JSON.parse(readText(argv[2])));
  if (argv[0] === 'same') return SECTIONS.every((s) => JSON.stringify(canon(current[s])) === JSON.stringify(canon(layout[s]))) ? 'same' : 'different';
  SECTIONS.forEach((s) => { current[s] = layout[s]; });
  if (!$(JSON.stringify(current)).writeToFileAtomicallyEncodingError(argv[3], true, $.NSUTF8StringEncoding, null)) throw new Error('cannot write ' + argv[3]);
  return 'written';
}
JS
js() { # PHONEBOX_TEST_JS: a stand-in for osascript when this script is tested on another system
  if [ -n "${PHONEBOX_TEST_JS:-}" ]; then "$PHONEBOX_TEST_JS" "$tmp/layout.js" "$@"; else osascript -l JavaScript "$tmp/layout.js" "$@"; fi
}

get_settings() { # get_settings file -> the config version on stdout
  curl -fsS -D "$tmp/headers" -o "$1" "$base/api/settings" || die "could not read PhoneBox's settings at $base."
  tr -d '\r' <"$tmp/headers" | awk 'tolower($1) == "x-config-version:" { print $2 }'
}

had_config=0; [ -f "$config" ] && had_config=1
# downloaded before setup runs, so a bad download stops everything before anything is installed
layout="$(fetch custom/layout.json "$LAYOUT_SHA256")"

if [ "$layout_only" = 0 ]; then
  setup="$(fetch setup.sh "$SETUP_SHA256")"
  bash "$setup" ${setup_args[@]+"${setup_args[@]}"}
  if [ "$dry" = 1 ]; then printf '\nDry run: the layout was not put on.\n'; exit 0; fi
  if [ "$no_start" = 1 ]; then printf '\nPhoneBox was not started (--no-start). Start it, then run: bash install-mac.sh --layout-only\n'; exit 0; fi
fi

printf '\n==> Screen layout\n'
up=0
for _ in $(seq 1 40); do
  if curl -fsS --max-time 2 "$base/api/info" >/dev/null 2>&1; then up=1; break; fi
  sleep 0.75
done
[ "$up" = 1 ] || die "PhoneBox is not running at $base, so the layout was not put on. Start PhoneBox, then run: bash install-mac.sh --layout-only"

version="$(get_settings "$tmp/current.json")"
if [ "$(js same "$tmp/current.json" "$layout")" = same ]; then say 'OK  This Mac already has the layout.'; exit 0; fi

if [ "$had_config" = 1 ]; then
  say 'This Mac already had PhoneBox settings. The layout replaces its pages, shortcuts, display, night and'
  say 'weather settings (a backup of config.json is kept).'
  answer=n
  if [ "$yes" = 0 ] && (: </dev/tty) 2>/dev/null; then
    printf '    Replace them? [y/N] ' >/dev/tty
    IFS= read -r answer </dev/tty || answer=n
  fi
  case "$answer" in [Yy]|[Yy][Ee][Ss]) ;; *) say "Kept this Mac's own layout."; exit 0 ;; esac
  backup="$config.before-layout-$(date +%Y%m%d-%H%M%S)"
  cp -p "$config" "$backup"
  say "Backup: $backup"
fi

js merge "$tmp/current.json" "$layout" "$tmp/merged.json" >/dev/null
code="$(curl -sS -o "$tmp/answer" -w '%{http_code}' -X PUT -H 'Content-Type: application/json; charset=utf-8' \
  -H "X-Config-Version: $version" --data-binary @"$tmp/merged.json" "$base/api/settings")" || code=000
[ "$code" = 200 ] || die "PhoneBox refused the layout (HTTP $code), nothing was changed: $(cat "$tmp/answer" 2>/dev/null)"

get_settings "$tmp/after.json" >/dev/null
[ "$(js same "$tmp/after.json" "$layout")" = same ] || die "the agent accepted the layout but does not show it; check ~/Library/Application Support/PhoneBox/agent.log."
say 'OK  Layout put on, with Mac commands for the shortcuts. The phone picks it up by itself.'
say 'Calendars are not part of the layout: add your calendar address in PhoneBox settings > General.'
