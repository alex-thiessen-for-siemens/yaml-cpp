#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-reference-commit-message.sh --commit REF \
  (--reference "NAME VERSION" ... | --not-applicable REASON)

Check that the commit body contains a versioned Reference verification block.
Each --reference value must include the exact reference name and version that
the evidence ledger records.
EOF
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s\n' "error: run this script inside the yaml-cpp repository" >&2
  exit 2
}
cd "${repo_root}" || exit 2

commit=
references=()
not_applicable=

while (($# > 0)); do
  case "$1" in
    --commit)
      (($# >= 2)) || {
        printf '%s\n' "error: --commit needs a ref" >&2
        exit 2
      }
      commit=$2
      shift 2
      ;;
    --reference)
      (($# >= 2)) || {
        printf '%s\n' "error: --reference needs a name and version" >&2
        exit 2
      }
      references+=("$2")
      shift 2
      ;;
    --not-applicable)
      (($# >= 2)) || {
        printf '%s\n' "error: --not-applicable needs a reason" >&2
        exit 2
      }
      not_applicable=$2
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

if [[ -z "$commit" ]]; then
  printf '%s\n' "error: --commit is required" >&2
  usage >&2
  exit 2
fi
if ((${#references[@]} == 0)) && [[ -z "$not_applicable" ]]; then
  printf '%s\n' \
    "error: provide --reference or --not-applicable" >&2
  usage >&2
  exit 2
fi
if ((${#references[@]} > 0)) && [[ -n "$not_applicable" ]]; then
  printf '%s\n' \
    "error: --reference and --not-applicable are mutually exclusive" >&2
  exit 2
fi

resolved_commit=$(git rev-parse --verify "${commit}^{commit}" 2>/dev/null) || {
  printf 'error: invalid commit: %s\n' "$commit" >&2
  exit 2
}
body=$(git log -1 --format=%b "$resolved_commit")

if ! grep -Fqx 'Reference verification:' <<<"$body" &&
  ! grep -Fq 'Reference verification: not applicable' <<<"$body"; then
  printf '%s\n' \
    "error: commit body lacks a Reference verification block" \
    >&2
  exit 1
fi

if [[ -n "$not_applicable" ]]; then
  if ! grep -Fqi 'Reference verification: not applicable' <<<"$body"; then
    printf '%s\n' \
      "error: commit body lacks the not-applicable reference statement" \
      >&2
    exit 1
  fi
  if ! grep -Fq -- "$not_applicable" <<<"$body"; then
    printf '%s\n' \
      "error: commit body lacks the not-applicable reason" >&2
    exit 1
  fi
else
  for reference in "${references[@]}"; do
    if ! grep -Fq -- "$reference" <<<"$body"; then
      printf 'error: commit body lacks reference and version: %s\n' \
        "$reference" >&2
      exit 1
    fi
  done
fi

printf 'PASS reference commit message: %s\n' "$resolved_commit"
