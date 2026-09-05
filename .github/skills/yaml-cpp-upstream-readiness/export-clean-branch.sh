#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf '%s\n' \
    "Usage: export-clean-branch.sh NEW_BRANCH [BASE_REF]" \
    "Create NEW_BRANCH from BASE_REF and stage only the contribution diff."
}

if (($# < 1 || $# > 2)); then
  usage >&2
  exit 2
fi

new_branch=$1
base_ref=${2:-upstream/master}
repo_root=$(git rev-parse --show-toplevel)
current_branch=$(git branch --show-current)

if [[ -z "$current_branch" ]]; then
  printf '%s\n' "error: export must start from a named implementation branch" >&2
  exit 2
fi
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  printf 'error: base ref is unavailable: %s\n' "$base_ref" >&2
  exit 2
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  printf '%s\n' "error: commit implementation changes before exporting a clean branch" >&2
  exit 2
fi
untracked_files=$(git ls-files --others --exclude-standard)
if [[ -n "$untracked_files" ]]; then
  printf '%s\n' \
    "error: export requires no untracked files; private setup could leak" >&2
  printf '%s\n' "$untracked_files" >&2
  exit 2
fi
if git show-ref --verify --quiet "refs/heads/$new_branch"; then
  printf 'error: branch already exists: %s\n' "$new_branch" >&2
  exit 2
fi

patch_file=$(mktemp)
trap 'rm -f "$patch_file"' EXIT
git diff --binary "$base_ref...HEAD" -- . \
  ':(exclude).github/copilot-instructions.md' \
  ':(exclude).github/instructions/**' \
  ':(exclude).github/agents/**' \
  ':(exclude).github/skills/**' >"$patch_file"

if [[ ! -s "$patch_file" ]]; then
  printf '%s\n' "error: no contribution changes remain after excluding setup files" >&2
  exit 2
fi

git switch -c "$new_branch" "$base_ref"
git apply --index "$patch_file"

if git diff --cached --name-only |
    grep -E '^\.github/(copilot-instructions\.md|instructions/|agents/|skills/)' \
    >/dev/null; then
  printf '%s\n' "error: setup files leaked into the exported branch" >&2
  git reset
  git switch "$current_branch"
  exit 1
fi

printf 'Exported %s from %s. Review and commit the staged contribution.\n' \
  "$new_branch" "$base_ref"
git diff --cached --stat
