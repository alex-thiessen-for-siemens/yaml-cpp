#!/usr/bin/env bash
#
# Compare two local YAML behavior adapters without installing or contacting
# external services. Each adapter receives the fixture path as argv[1] and
# writes a deterministic observable result to stdout.

set -u
set -o pipefail

usage() {
  cat <<-'EOF'
Usage: run-reference-check.sh --fixture FILE --candidate ADAPTER \
  --reference ADAPTER [--ledger FILE]

Both adapters must be executable local files. They receive FILE as argv[1],
write a canonical result to stdout, and return non-zero on evaluation failure.
EOF
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s\n' "error: run this script inside the yaml-cpp repository" >&2
  exit 2
}
cd "${repo_root}" || exit 2

fixture=
candidate=
reference=
ledger=

while (($# > 0)); do
  case "$1" in
    --fixture)
      (($# >= 2)) || {
        printf '%s\n' "error: --fixture needs a path" >&2
        exit 2
      }
      fixture=$2
      shift 2
      ;;
    --candidate)
      (($# >= 2)) || {
        printf '%s\n' "error: --candidate needs an adapter path" >&2
        exit 2
      }
      candidate=$2
      shift 2
      ;;
    --reference)
      (($# >= 2)) || {
        printf '%s\n' "error: --reference needs an adapter path" >&2
        exit 2
      }
      reference=$2
      shift 2
      ;;
    --ledger)
      (($# >= 2)) || {
        printf '%s\n' "error: --ledger needs a path" >&2
        exit 2
      }
      ledger=$2
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

if [[ -z "${fixture}" || -z "${candidate}" || -z "${reference}" ]]; then
  printf '%s\n' "error: fixture, candidate, and reference are required" >&2
  usage >&2
  exit 2
fi

if [[ ! -r "${fixture}" ]]; then
  printf 'error: fixture is not readable: %s\n' "${fixture}" >&2
  exit 2
fi
for adapter in "${candidate}" "${reference}"; do
  if [[ ! -x "${adapter}" ]]; then
    printf 'error: adapter is not executable: %s\n' "${adapter}" >&2
    exit 2
  fi
done

record() {
  local line=$1
  printf '%s\n' "${line}"
  if [[ -n "${ledger}" ]]; then
    printf '%s\n' "${line}" >>"${ledger}"
  fi
}

if [[ -n "${ledger}" ]]; then
  mkdir -p "$(dirname "${ledger}")"
  record "## reference evaluator $(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/yaml-cpp-reference.XXXXXX") || exit 2
trap 'rm -rf -- "${work_dir}"' EXIT

run_adapter() {
  local name=$1
  local adapter=$2
  local output=$3
  local errors=$4
  local status

  record "RUN local reference ${name}: ${adapter} ${fixture}"
  if env \
    -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
    -u http_proxy -u https_proxy -u all_proxy \
    LC_ALL=C YAML_CPP_REFERENCE_LOCAL_ONLY=1 \
    "${adapter}" "${fixture}" >"${output}" 2>"${errors}"; then
    record "PASS local reference ${name}"
    return 0
  else
    status=$?
  fi
  record "FAIL local reference ${name} (exit ${status})"
  cat "${errors}" >&2
  return "${status}"
}

candidate_output="${work_dir}/candidate.out"
candidate_errors="${work_dir}/candidate.err"
reference_output="${work_dir}/reference.out"
reference_errors="${work_dir}/reference.err"

record "REFERENCE local-only: fixture=${fixture}"
if ! run_adapter candidate "${candidate}" "${candidate_output}" \
  "${candidate_errors}"; then
  exit 1
fi
if ! run_adapter reference "${reference}" "${reference_output}" \
  "${reference_errors}"; then
  exit 1
fi

if cmp --silent "${candidate_output}" "${reference_output}"; then
  record "PASS local reference comparison"
  exit 0
fi

record "FAIL local reference comparison: canonical results differ"
diff -u "${reference_output}" "${candidate_output}" >&2 || true
exit 1
