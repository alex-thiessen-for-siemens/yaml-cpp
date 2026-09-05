#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-libyaml-adapter.sh --output FILE
  [--include-dir DIR] [--library-dir DIR] [--cc COMPILER]

Build the private libyaml event adapter. The libyaml development headers and
library must already be installed; this script does not install dependencies.
EOF
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s\n' "error: run this script inside the yaml-cpp repository" >&2
  exit 2
}
skill_dir="${repo_root}/.github/skills/yaml-cpp-reference-check"
source="${skill_dir}/libyaml-event-adapter.c"
output=
cc="${CC:-cc}"
include_dir=
library_dir=

while (($# > 0)); do
  case "$1" in
    --output)
      (($# >= 2)) || {
        printf '%s\n' "error: --output needs a path" >&2
        exit 2
      }
      output=$2
      shift 2
      ;;
    --include-dir)
      (($# >= 2)) || {
        printf '%s\n' "error: --include-dir needs a path" >&2
        exit 2
      }
      include_dir=$2
      shift 2
      ;;
    --library-dir)
      (($# >= 2)) || {
        printf '%s\n' "error: --library-dir needs a path" >&2
        exit 2
      }
      library_dir=$2
      shift 2
      ;;
    --cc)
      (($# >= 2)) || {
        printf '%s\n' "error: --cc needs a compiler" >&2
        exit 2
      }
      cc=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$output" ]]; then
  printf '%s\n' "error: --output is required" >&2
  usage >&2
  exit 2
fi

if [[ ! -r "$source" ]]; then
  printf 'error: adapter source is not readable: %s\n' "$source" >&2
  exit 2
fi

include_flags=()
library_flags=()
if [[ -n "$include_dir" ]]; then
  include_flags+=("-I${include_dir}")
fi
if [[ -n "$library_dir" ]]; then
  library_flags+=("-L${library_dir}")
fi

if [[ -z "$include_dir" && -z "$library_dir" ]] &&
  command -v pkg-config >/dev/null 2>&1 &&
  pkg-config --exists yaml-0.1; then
  read -r -a pkg_cflags <<<"$(pkg-config --cflags yaml-0.1)"
  read -r -a pkg_libs <<<"$(pkg-config --libs yaml-0.1)"
  include_flags+=("${pkg_cflags[@]}")
  library_flags+=("${pkg_libs[@]}")
else
  library_flags+=("-lyaml")
fi

mkdir -p "$(dirname "$output")"
"$cc" \
  -std=c11 \
  -Wall \
  -Wextra \
  -Wpedantic \
  "${include_flags[@]}" \
  "$source" \
  "${library_flags[@]}" \
  -o "$output"
