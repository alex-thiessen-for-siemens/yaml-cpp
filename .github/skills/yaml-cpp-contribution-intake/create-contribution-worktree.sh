#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${script_dir}/commit-signing-policy.sh"

usage() {
  printf '%s\n' \
    "Usage: create-contribution-worktree.sh WORKTREE_PATH BRANCH" \
    "       [SETUP_REF] [BASE_REF]" \
    "Create a skill-bearing implementation worktree from BASE_REF."
}

if (($# < 2 || $# > 4)); then
  usage >&2
  exit 2
fi

worktree_path=$1
implementation_branch=$2
setup_ref=${3:-HEAD}
base_ref=${4:-upstream/master}
current_branch=$(git branch --show-current)

if [[ -z "${current_branch}" ]]; then
  printf '%s\n' "error: run this helper from a named setup branch" >&2
  exit 2
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  printf '%s\n' \
    "error: setup worktree has tracked changes; commit or stash them first" \
    >&2
  exit 2
fi
if ! git rev-parse --verify "${setup_ref}^{commit}" >/dev/null 2>&1; then
  printf 'error: setup ref is unavailable: %s\n' "${setup_ref}" >&2
  exit 2
fi
if ! git rev-parse --verify "${base_ref}^{commit}" >/dev/null 2>&1; then
  printf 'error: base ref is unavailable: %s\n' "${base_ref}" >&2
  exit 2
fi
require_yaml_cpp_signing_key
setup_commit=$(git rev-parse --verify "${setup_ref}^{commit}")
base_commit=$(git rev-parse --verify "${base_ref}^{commit}")
if ! git cat-file -e "${setup_commit}:.github/copilot-instructions.md" ||
  ! git cat-file -e "${setup_commit}:.github/skills/unslop/SKILL.md" ||
  ! git cat-file -e "${setup_commit}:.github/agents/yaml-cpp-contributor.agent.md" ||
  ! git cat-file -e \
  "${setup_commit}:.github/skills/yaml-cpp-contribution-intake/commit-signing-policy.sh" ||
  ! git cat-file -e \
  "${setup_commit}:.github/skills/yaml-cpp-contribution-intake/check-commit-signatures.sh"; then
  printf '%s\n' \
    "error: setup ref does not contain the repository Copilot setup" >&2
  exit 2
fi
if git show-ref --verify --quiet "refs/heads/${implementation_branch}"; then
  printf 'error: branch already exists: %s\n' "${implementation_branch}" >&2
  exit 2
fi
if [[ -e "${worktree_path}" || -L "${worktree_path}" ]]; then
  printf 'error: worktree path already exists: %s\n' "${worktree_path}" >&2
  exit 2
fi

parent_path=$(dirname -- "${worktree_path}")
mkdir -p -- "${parent_path}"
branch_created=false
worktree_created=false
cleanup_worktree() {
  local status=$?
  trap - EXIT
  if ((status != 0)); then
    if [[ "${worktree_created}" == true ]]; then
      if ! git worktree remove --force "${worktree_path}"; then
        printf '%s\n' \
          "warning: failed to remove incomplete implementation worktree" \
          >&2
      fi
    fi
    if [[ "${branch_created}" == true ]] &&
      git show-ref --verify --quiet "refs/heads/${implementation_branch}"; then
      if ! git branch -D "${implementation_branch}"; then
        printf 'warning: failed to remove incomplete branch: %s\n' \
          "${implementation_branch}" >&2
      fi
    fi
  fi
  exit "${status}"
}
trap cleanup_worktree EXIT

git worktree add -b "${implementation_branch}" \
  "${worktree_path}" "${base_commit}"
branch_created=true
worktree_created=true

git -C "${worktree_path}" checkout "${setup_commit}" -- .github
git -C "${worktree_path}" add -- .github
git -C "${worktree_path}" config --local user.signingkey \
  "${YAML_CPP_SIGNING_KEY}"
git -C "${worktree_path}" config --local commit.gpgsign true
git -C "${worktree_path}" config --local gpg.format openpgp
git -C "${worktree_path}" commit -S"${YAML_CPP_SIGNING_KEY}" \
  -m "Apply private Copilot setup" \
  -m "Keep repository-local skills and agents available during contribution work.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

printf 'Created implementation worktree: %s\n' "${worktree_path}"
printf 'Implementation branch: %s\n' "${implementation_branch}"
printf 'Setup source: %s\n' "${setup_ref}"
printf 'Contribution base: %s\n' "${base_ref}"
printf '%s\n' \
  "Run the contribution workflow from this worktree. Keep it on this branch" \
  "until export-clean-branch.sh creates the separate upstream-ready worktree."
