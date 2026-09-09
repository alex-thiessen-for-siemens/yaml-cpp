#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${script_dir}/../yaml-cpp-contribution-intake/commit-signing-policy.sh"

usage() {
  printf '%s\n' \
    "Usage: export-clean-branch.sh [-f|--force] NEW_BRANCH [BASE_REF]" \
    "       [EXPORT_WORKTREE]" \
    "Create NEW_BRANCH and stage only the contribution diff in a separate" \
    "worktree, leaving the setup-backed implementation worktree unchanged." \
    "Options:" \
    "  -f, --force    Overwrite existing export branch and worktree directory."
}

force=false
positional=()

while (($# > 0)); do
  case "$1" in
    -f|--force)
      force=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while (($# > 0)); do
        positional+=("$1")
        shift
      done
      break
      ;;
    -*)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if ((${#positional[@]} < 1 || ${#positional[@]} > 3)); then
  usage >&2
  exit 2
fi

new_branch=${positional[0]}
base_ref=${positional[1]:-upstream/master}
repo_root=$(git rev-parse --show-toplevel)
current_branch=$(git branch --show-current)
if ((${#positional[@]} == 3)); then
  export_worktree=${positional[2]}
else
  export_worktree="${repo_root}.worktrees/${new_branch//\//-}"
fi

if [[ -z "${current_branch}" ]]; then
  printf '%s\n' "error: export must start from a named implementation branch" >&2
  exit 2
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  printf '%s\n' \
    "error: commit implementation changes before exporting a clean branch" \
    >&2
  exit 2
fi
if ! git cat-file -e "HEAD:.github/copilot-instructions.md" ||
  ! git cat-file -e "HEAD:.github/skills/unslop/SKILL.md" ||
  ! git cat-file -e "HEAD:.github/agents/yaml-cpp-contributor.agent.md"; then
  printf '%s\n' \
    "error: active branch does not contain the private Copilot setup" >&2
  exit 2
fi
if ! git rev-parse --verify "${base_ref}^{commit}" >/dev/null 2>&1; then
  printf 'error: base ref is unavailable: %s\n' "${base_ref}" >&2
  exit 2
fi
require_yaml_cpp_signing_key
"${script_dir}/../yaml-cpp-contribution-intake/check-commit-signatures.sh" \
  "${base_ref}..HEAD"
if [[ -e "${export_worktree}" || -L "${export_worktree}" ]]; then
  if [[ "${force}" == true ]]; then
    printf 'Removing existing worktree at %s due to --force...\n' \
      "${export_worktree}"
    if ! git worktree remove --force "${export_worktree}"; then
      printf '%s\n' \
        "error: existing path is not a removable Git worktree; remove it manually" \
        >&2
      exit 2
    fi
    git worktree prune
  else
    printf 'error: export worktree path already exists: %s\n' \
      "${export_worktree}" >&2
    exit 2
  fi
fi
if git show-ref --verify --quiet "refs/heads/${new_branch}"; then
  if [[ "${force}" == true ]]; then
    printf 'Removing existing branch %s due to --force...\n' "${new_branch}"
    git branch -D "${new_branch}"
  else
    printf 'error: branch already exists: %s\n' "${new_branch}" >&2
    exit 2
  fi
fi

patch_file=$(mktemp)
branch_created=false
worktree_created=false
cleanup_export() {
  local status=$?
  trap - EXIT
  if ((status != 0)); then
    if [[ "${worktree_created}" == true ]]; then
      if ! git worktree remove --force "${export_worktree}"; then
        printf '%s\n' \
          "warning: failed to remove incomplete export worktree" >&2
      fi
    fi
    if [[ "${branch_created}" == true ]] &&
      git show-ref --verify --quiet "refs/heads/${new_branch}"; then
      if ! git branch -D "${new_branch}"; then
        printf 'warning: failed to remove incomplete branch: %s\n' \
          "${new_branch}" >&2
      fi
    fi
  fi
  rm -f -- "${patch_file}"
  exit "${status}"
}
trap cleanup_export EXIT

git diff --binary "${base_ref}...HEAD" -- . \
  ':(exclude).github/**' \
  ':(exclude)abi-and-issues.asciidoc' \
  ':(exclude)gaps.asciidoc' >"${patch_file}"

if [[ ! -s "${patch_file}" ]]; then
  printf '%s\n' \
    "error: no contribution changes remain after excluding setup files" >&2
  exit 2
fi

parent_path=$(dirname -- "${export_worktree}")
mkdir -p -- "${parent_path}"
git worktree add -b "${new_branch}" "${export_worktree}" "${base_ref}"
branch_created=true
worktree_created=true

git -C "${export_worktree}" apply --check --index "${patch_file}"
git -C "${export_worktree}" apply --index "${patch_file}"

if git -C "${export_worktree}" diff --cached --name-only |
  grep -E '^\.github/' >/dev/null; then
  printf '%s\n' "error: setup files leaked into the exported branch" >&2
  exit 1
fi

printf 'Exported %s from %s into %s.\n' \
  "${new_branch}" "${base_ref}" "${export_worktree}"
printf '%s\n' \
  "Review and commit the staged contribution there. The implementation" \
  "worktree remains on ${current_branch} with its skills and agents."
git -C "${export_worktree}" diff --cached --stat
