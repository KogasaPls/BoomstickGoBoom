#!/usr/bin/env bash
set -euo pipefail

ADDON="BoomstickGoBoom"
OUT_DIR="dist"

required=(
  "${ADDON}.toc"
  "${ADDON}.lua"
  "tick1.ogg"
  "tick2.ogg"
  "tick3.ogg"
  "tick4.ogg"
  "LICENSE"
  "NOTICE.md"
)

if [[ "$(basename "$PWD")" != "$ADDON" ]]; then
  echo "error: run this from the ${ADDON}/ addon directory" >&2
  exit 1
fi

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "error: missing required file: $file" >&2
    exit 1
  fi
done

version="$(
  awk -F': *' 'tolower($1) == "## version" { print $2; exit }' "${ADDON}.toc"
)"

if [[ -z "${version:-}" ]]; then
  version="dev"
fi

mkdir -p "$OUT_DIR"

zip_name="${ADDON}-${version}.zip"
zip_path="${PWD}/${OUT_DIR}/${zip_name}"

rm -f "$zip_path"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/$ADDON"

cp "${required[@]}" "$tmpdir/$ADDON/"

(
  cd "$tmpdir"
  zip -r "$zip_path" "$ADDON"
)

echo "Created: ${OUT_DIR}/${zip_name}"
