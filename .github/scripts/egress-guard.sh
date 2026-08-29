#!/usr/bin/env bash
# TeeJ-editor egress guard.
# Fails if any code path that could reach the network, or launch the WinGUP
# updater, reappears in the source or installer. Run in CI on every push/PR,
# most importantly on upstream-merge PRs.
set -u
cd "$(git rev-parse --show-toplevel)"

fail=0
check() { # check <label> <grep-ERE> <paths...>
  local label="$1" pat="$2"; shift 2
  local hits
  hits=$(grep -rnIE --include='*.cpp' --include='*.h' --include='*.rc' --include='*.nsi' --include='*.nsh' --include='*.wxs' --include='*.bat' \
         "$pat" "$@" 2>/dev/null | grep -vE '^[^:]+:[0-9]+:\s*(//|;|rem |REM |<!--)' | grep -vE 'TeeJ-editor:' || true)
  if [ -n "$hits" ]; then
    echo "::error::EGRESS GUARD [$label] — forbidden pattern found:"
    echo "$hits"
    fail=1
  fi
}

SRC=PowerEditor/src
INST=PowerEditor/installer

# 1. The updater helper, by name or by launcher
check "gup.exe reference"        'gup\.exe'                                   "$SRC" "$INST"
check "updater launcher"         'launchUpdater|Process updater|setWingupFullPath|getWingupFullPath|buildGupParams' "$SRC"
check "gup unzip/install args"   '"-unzipTo|"-clean |-moveFolder'             "$SRC"

# 2. Direct network APIs (InternetCrackUrl is URL *parsing*, allowed)
check "WinINet connections"      'InternetOpen(Url)?\(|InternetConnect\(|HttpOpenRequest\(|HttpSendRequest|InternetReadFile\(' "$SRC"
check "WinHTTP"                  'WinHttp[A-Za-z]+\(|#include\s*<winhttp\.h>' "$SRC"
check "URL download"             'URLDownloadToFile|URLOpenBlockingStream'    "$SRC"
check "Winsock"                  'WSAStartup|getaddrinfo\(|#include\s*<winsock' "$SRC"
check "libcurl"                  'curl_easy|#include\s*<curl'                 "$SRC"
check "SENS reachability probe"  'IsDestinationReachable|IsNetworkAlive|#include\s*<sensapi' "$SRC"
check "updater endpoints"        'INFO_URL|FORCED_DOWNLOAD_DOMAIN|getDownloadUrl\.php' "$SRC"

# 3. Product web links (a hard-coded https URL handed to ShellExecute).
#    Opening a URL the *user* clicked is a variable, not a literal, so it does not match.
check "hard-coded web link"      'ShellExecute[A-Za-z]*\([^;]*L"https?://'    "$SRC"

# 4. Online plugin catalog / Plugins Admin network path
check "plugin catalog"           'nppPluginList\.(dll|json)'                  "$SRC"
check "Plugins Admin dialog use" '_pluginsAdminDlg\.(doDialog|updateList)'    "$SRC"

# 5. Installer must not package the updater or catalog
check "installer ships updater"  '^\s*File\b[^;]*(GUP\.exe|gup\.xml|nppPluginList\.dll)' "$INST"

if [ "$fail" -ne 0 ]; then
  echo "::error::Egress guard FAILED — this build could contact the internet or launch the updater."
  exit 1
fi
echo "Egress guard passed: no network or updater code paths found."
