#!/bin/bash
#
# Rebuild crystal-widgets-v2.widget.zip, the self-contained quick-install
# bundle: everything in widgets/ plus a freshly built universal
# crystal_sampler. Run from the repo root after any change to widgets/ or
# sampler/ so the zip never lags the sources.
set -euo pipefail
cd "$(dirname "$0")"

make -C sampler

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
bundle="$stage/crystal-widgets-v2.widget"

cp -R widgets "$bundle"
cp sampler/crystal_sampler "$bundle/"
find "$bundle" -name .DS_Store -delete

rm -f crystal-widgets-v2.widget.zip
(cd "$stage" && zip -qr -X "$OLDPWD/crystal-widgets-v2.widget.zip" crystal-widgets-v2.widget)
unzip -l crystal-widgets-v2.widget.zip | tail -1
