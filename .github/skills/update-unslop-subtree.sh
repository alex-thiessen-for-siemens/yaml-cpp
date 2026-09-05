#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
source_repo=${1:-https://github.com/cursor/plugins.git}
source_ref=${2:-main}
source_path=pstack/skills/unslop
target_path=.github/skills/unslop
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

if ! git diff --quiet || ! git diff --cached --quiet; then
  printf '%s\n' "error: subtree updates require a clean worktree" >&2
  exit 2
fi

git clone --depth=1 --filter=blob:none --no-checkout "$source_repo" \
  "$tmp_dir/plugins"
git -C "$tmp_dir/plugins" checkout --detach "$source_ref"
git -C "$tmp_dir/plugins" subtree split --prefix="$source_path" \
  --branch=unslop-subtree "$source_ref"

cd "$repo_root"
git subtree pull --prefix="$target_path" "$tmp_dir/plugins" unslop-subtree \
  --squash
