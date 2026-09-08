#!/usr/bin/env bash

readonly YAML_CPP_SIGNING_KEY=9F77750E827051B3

require_yaml_cpp_signing_key() {
  if ! command -v gpg >/dev/null 2>&1; then
    printf '%s\n' "error: gpg is required for signed yaml-cpp commits" >&2
    return 1
  fi

  local secret_keys
  if ! secret_keys=$(gpg --batch --list-secret-keys --with-colons \
    "${YAML_CPP_SIGNING_KEY}" 2>/dev/null); then
    printf 'error: signing key is unavailable: %s\n' \
      "${YAML_CPP_SIGNING_KEY}" >&2
    return 1
  fi
  if ! grep -q '^sec:' <<<"${secret_keys}"; then
    printf 'error: signing key is unavailable: %s\n' \
      "${YAML_CPP_SIGNING_KEY}" >&2
    return 1
  fi
}
