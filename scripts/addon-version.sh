#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 read <addon.toc> | check-tag <addon.toc> <vX.Y.Z>" >&2
  exit 2
}

read_version() {
  local toc="$1"
  local -a versions=()

  [[ -f "$toc" ]] || {
    echo "error: TOC file not found: $toc" >&2
    return 1
  }

  mapfile -t versions < <(
    awk '
      tolower($0) ~ /^##[[:space:]]+version[[:space:]]*:/ {
        sub(/^##[[:space:]]+[Vv][Ee][Rr][Ss][Ii][Oo][Nn][[:space:]]*:[[:space:]]*/, "")
        sub(/\r$/, "")
        sub(/[[:space:]]+$/, "")
        print
      }
    ' "$toc"
  )

  if (( ${#versions[@]} != 1 )); then
    echo "error: expected exactly one ## Version entry in $toc" >&2
    return 1
  fi

  if [[ ! "${versions[0]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: addon version must use X.Y.Z format: ${versions[0]}" >&2
    return 1
  fi

  printf '%s\n' "${versions[0]}"
}

command="${1:-}"
toc="${2:-}"
[[ -n "$command" && -n "$toc" ]] || usage

case "$command" in
  read)
    (( $# == 2 )) || usage
    read_version "$toc"
    ;;
  check-tag)
    (( $# == 3 )) || usage
    version="$(read_version "$toc")"
    expected_tag="v${version}"

    if [[ "$3" != "$expected_tag" ]]; then
      echo "error: tag '$3' does not match TOC version '$expected_tag'" >&2
      exit 1
    fi

    printf '%s\n' "$version"
    ;;
  *)
    usage
    ;;
esac
