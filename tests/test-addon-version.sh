#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version_script="${repo_root}/scripts/addon-version.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

toc="${tmpdir}/TestAddon.toc"

fail() {
  echo "not ok - $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  [[ "$actual" == "$expected" ]] || fail "${description}: expected '${expected}', got '${actual}'"
  echo "ok - ${description}"
}

assert_fails() {
  local description="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    fail "${description}: command unexpectedly succeeded"
  fi
  echo "ok - ${description}"
}

cat >"$toc" <<'EOF'
## Interface: 120007
## Version: 1.2.3
EOF

assert_eq "1.2.3" "$("$version_script" read "$toc")" "reads a three-part addon version"
assert_eq "1.2.3" "$("$version_script" check-tag "$toc" v1.2.3)" "accepts a matching release tag"
assert_fails "rejects a mismatched release tag" "$version_script" check-tag "$toc" v1.2.4

cat >"$toc" <<'EOF'
## Version: 1.2
EOF
assert_fails "rejects a malformed addon version" "$version_script" read "$toc"

cat >"$toc" <<'EOF'
## Version: 1.2.3
## Version: 2.0.0
EOF
assert_fails "rejects duplicate addon versions" "$version_script" read "$toc"
