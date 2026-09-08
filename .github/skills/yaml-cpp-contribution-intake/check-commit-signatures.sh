#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${script_dir}/commit-signing-policy.sh"

usage() {
  printf '%s\n' \
    "Usage: check-commit-signatures.sh COMMIT_RANGE [KEY_ID]" \
    "Require every commit in COMMIT_RANGE to have a good signature from KEY_ID."
}

if (($# < 1 || $# > 2)); then
  usage >&2
  exit 2
fi

commit_range=$1
expected_key=${2:-${YAML_CPP_SIGNING_KEY}}
expected_key=${expected_key^^}
commit_count=$(git rev-list --count "${commit_range}") || {
  printf 'error: invalid commit range: %s\n' "${commit_range}" >&2
  exit 2
}
if ((commit_count == 0)); then
  printf 'error: commit range is empty: %s\n' "${commit_range}" >&2
  exit 2
fi

commits=$(git rev-list "${commit_range}")
while IFS= read -r commit; do
  signature_status=$(git show -s --format='%G?' "${commit}")
  signing_key=$(git show -s --format='%GK' "${commit}")
  signing_key=${signing_key^^}
  if [[ "${signature_status}" != G || "${signing_key}" != "${expected_key}" ]]; then
    printf 'error: commit %s has signature %s from key %s\n' \
      "${commit}" "${signature_status}" "${signing_key:-none}" >&2
    exit 1
  fi
done <<<"${commits}"

printf 'Verified %d signed commit(s) from key %s.\n' \
  "${commit_count}" "${expected_key}"
