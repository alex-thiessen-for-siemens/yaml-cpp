#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-reference-commit-message.sh --commit REF \
  [--upstream] (--reference "NAME VERSION" ... | --not-applicable REASON)

Check that the commit body contains a versioned Reference verification block
and that the complete commit message follows the contribution prose rules.
Each --reference value must include the exact reference name and version that
the evidence ledger records. Require one subject line, exactly one blank line
before the body, contiguous wrapped paragraphs, and message lines at most 72
characters. Tests must not be described as adding a regression. With
--upstream, also reject AI co-author trailers.
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
upstream_mode=0

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
    --upstream)
      upstream_mode=1
      shift
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
message=$(git log -1 --format=%B "$resolved_commit")

message_format_error() {
  printf 'error: commit message format: %s\n' "$1" >&2
  exit 1
}

check_message_format() {
  local -a message_lines=()
  local line paragraph_lines=0 paragraph_structured=0
  local consecutive_single_line=0 last_index

  mapfile -t message_lines < <(printf '%s\n' "$message")
  while ((${#message_lines[@]} > 0)); do
    last_index=$((${#message_lines[@]} - 1))
    [[ -n "${message_lines[last_index]}" ]] && break
    message_lines=("${message_lines[@]:0:last_index}")
  done

  ((${#message_lines[@]} > 0)) ||
    message_format_error "the subject must not be empty"
  [[ -n "${message_lines[0]}" ]] ||
    message_format_error "the subject must not be empty"
  if [[ "${message_lines[0]}" =~ ^[[:space:]] ||
        "${message_lines[0]}" =~ [[:space:]]$ ]]; then
    message_format_error "the subject must not have leading or trailing whitespace"
  fi

  if ((${#message_lines[@]} > 1)); then
    [[ -z "${message_lines[1]}" ]] ||
      message_format_error \
        "the subject must be followed by exactly one blank line"
  fi

  for ((last_index = 2; last_index < ${#message_lines[@]}; ++last_index)); do
    line=${message_lines[last_index]}
    if [[ -z "$line" ]]; then
      ((paragraph_lines > 0)) ||
        message_format_error \
          "body paragraphs must be separated by exactly one blank line"
      if ((paragraph_lines == 1 && paragraph_structured == 0)); then
        consecutive_single_line=$((consecutive_single_line + 1))
      else
        consecutive_single_line=0
      fi
      ((consecutive_single_line < 2)) ||
        message_format_error \
          "wrap prose paragraphs as contiguous lines; do not split each line into a separate paragraph"
      paragraph_lines=0
      paragraph_structured=0
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]+$ ||
          "$line" =~ ^[[:space:]] ||
          "$line" =~ [[:space:]]$ ]]; then
      message_format_error \
        "body lines must not have leading, trailing, or whitespace-only formatting"
    fi
    if ((paragraph_lines == 0)); then
      case "$line" in
        Reference\ verification:*|Co-authored-by:*|Signed-off-by:*|\
        Fixes\ #*|Closes\ #*|-*|\**)
          paragraph_structured=1
          ;;
      esac
    fi
    paragraph_lines=$((paragraph_lines + 1))
  done

  if ((paragraph_lines == 1 && paragraph_structured == 0)); then
    consecutive_single_line=$((consecutive_single_line + 1))
    ((consecutive_single_line < 2)) ||
      message_format_error \
        "wrap prose paragraphs as contiguous lines; do not split each line into a separate paragraph"
  fi
}

check_message_format

line_number=0
while IFS= read -r line; do
  line_number=$((line_number + 1))
  if ((${#line} > 72)); then
    printf 'error: commit message line %d is %d characters; maximum is 72\n' \
      "$line_number" "${#line}" >&2
    exit 1
  fi
done <<<"$message"

if grep -Eiq \
  '(^|[^[:alnum:]])add(s|ed|ing)?[[:space:]]+(a[[:space:]]+)?regression([^[:alnum:]]|$)' \
  <<<"$message"; then
  printf '%s\n' \
    'error: describe a test as covering the bug or preventing regressions,' \
    'not as adding a regression' >&2
  exit 1
fi

if ((upstream_mode)) && grep -Eiq \
  '^Co-authored-by:.*(AI|Copilot|Claude|GPT|Gemini|OpenAI|Anthropic)([^[:alnum:]]|$)' \
  <<<"$message"; then
  printf '%s\n' \
    'error: upstream feature commits must not name AI as a co-author' \
    >&2
  exit 1
fi

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
