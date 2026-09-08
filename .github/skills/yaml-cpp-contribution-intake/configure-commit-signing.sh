#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${script_dir}/commit-signing-policy.sh"

if (($# != 0)); then
  printf '%s\n' \
    "Usage: configure-commit-signing.sh" \
    "Configure the repository to sign commits with the yaml-cpp key." \
    >&2
  exit 2
fi

require_yaml_cpp_signing_key
git config --local user.signingkey "${YAML_CPP_SIGNING_KEY}"
git config --local commit.gpgsign true
git config --local gpg.format openpgp

printf 'Configured signed commits with key %s.\n' "${YAML_CPP_SIGNING_KEY}"
