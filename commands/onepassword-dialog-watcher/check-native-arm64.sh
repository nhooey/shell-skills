# The body of the flake's onepassword-dialog-watcher-native-arm64 check.
# Fails when any Mach-O executable under the store paths in `watcher` and
# `terminalNotifier`, derivation attributes that arrive as environment
# variables, has no arm64 slice, so nothing the watcher runs needs Rosetta
# on Apple silicon. Needs `file` and `lipo` on PATH.
# shellcheck shell=bash
# shellcheck disable=SC2154 # watcher, terminalNotifier and out come from the derivation
set -euo pipefail

checked=0
status=0
while IFS= read -r -d '' binary; do
  kind=$(file --brief "$binary")
  [[ $kind == Mach-O* ]] || continue
  checked=$((checked + 1))
  archs=$(lipo -archs "$binary")
  if [[ " $archs " == *" arm64 "* ]]; then
    echo "ok - $binary: $archs"
  else
    echo "not ok - $binary: $archs, no arm64"
    status=1
  fi
done < <(find "$watcher" "$terminalNotifier" -type f -perm -u+x -print0)

if ((checked == 0)); then
  echo "not ok - no Mach-O executable under $watcher $terminalNotifier"
  exit 1
fi
if ((status != 0)); then
  exit "$status"
fi
touch "$out"
