#!/usr/bin/env bash
#
# Run the local yaml-cpp contribution evidence gates. This script is
# intentionally explicit about missing tools and never installs software.

set -u
set -o pipefail

usage() {
  cat <<'EOF'
Usage: run-evaluation.sh [options]

Options:
  --inventory              Print tool availability and versions, then exit.
  --base REF               Compare changed files with REF (default: upstream/master).
  --build-root DIR         Build directory root (default: build/copilot-eval).
  --ledger FILE            Append results to a private evidence ledger.
  --waive TOOL             Explicitly waive TOOL (repeatable).
  --help                   Show this help.

Useful waiver names are: clang-format, clang-tidy, cppcheck, valgrind, bazel,
bzlmod, sanitizer, cmake, ctest, and compiler. This repository needs Bazel 7
or newer for its MODULE.bazel-only workspace. The caller must obtain the
user's decision before passing --waive.
EOF
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s\n' "error: run this script inside the yaml-cpp repository" >&2
  exit 2
}
cd "$repo_root" || exit 2

inventory_only=false
base_ref=${BASE_REF:-upstream/master}
build_root=${BUILD_ROOT:-"$repo_root/build/copilot-eval"}
ledger=${EVIDENCE_LEDGER:-}
declare -a waivers=()

while (($# > 0)); do
  case "$1" in
    --inventory)
      inventory_only=true
      shift
      ;;
    --base)
      (($# >= 2)) || { printf '%s\n' "error: --base needs a ref" >&2; exit 2; }
      base_ref=$2
      shift 2
      ;;
    --build-root)
      (($# >= 2)) || { printf '%s\n' "error: --build-root needs a path" >&2; exit 2; }
      build_root=$2
      shift 2
      ;;
    --ledger)
      (($# >= 2)) || { printf '%s\n' "error: --ledger needs a path" >&2; exit 2; }
      ledger=$2
      shift 2
      ;;
    --waive)
      (($# >= 2)) || { printf '%s\n' "error: --waive needs a tool" >&2; exit 2; }
      waivers+=("$2")
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

has_waiver() {
  local item
  for item in "${waivers[@]}"; do
    [[ "$item" == "$1" ]] && return 0
  done
  return 1
}

version_for() {
  case "$1" in
    c++|compiler)
      "${CXX:-c++}" --version 2>&1 | head -1
      ;;
    bzlmod)
      "$(tool_command)" --version 2>&1 | head -1
      ;;
    *)
      "$1" --version 2>&1 | head -1
      ;;
  esac
}

tool_available() {
  case "$1" in
    bazel|bzlmod)
      bazel_supported
      ;;
    sanitizer)
      command -v "${CXX:-c++}" >/dev/null 2>&1
      ;;
    compiler)
      command -v "${CXX:-c++}" >/dev/null 2>&1
      ;;
    *)
      command -v "$1" >/dev/null 2>&1
      ;;
  esac
}

tool_command() {
  if bazel_command_supported bazel; then
    printf '%s\n' bazel
  elif bazel_command_supported bazelisk; then
    printf '%s\n' bazelisk
  elif command -v bazel >/dev/null 2>&1; then
    printf '%s\n' bazel
  else
    printf '%s\n' bazelisk
  fi
}

bazel_version_major() {
  local command=$1
  "$command" --version 2>/dev/null |
    sed -n 's/.* \([0-9][0-9]*\)\..*/\1/p' | head -1
}

bazel_command_supported() {
  local command=$1
  local major
  if ! command -v "$command" >/dev/null 2>&1; then
    return 1
  fi
  major=$(bazel_version_major "$command")
  [[ "$major" =~ ^[0-9]+$ ]] && ((major >= 7))
}

bazel_supported() {
  local command
  command=$(tool_command)
  bazel_command_supported "$command"
}

tool_state() {
  local tool=$1
  if [[ "$tool" == bazel || "$tool" == bzlmod ]]; then
    if ! command -v bazel >/dev/null 2>&1 &&
      ! command -v bazelisk >/dev/null 2>&1; then
      printf 'missing\t%s\t-\n' "$tool"
    elif bazel_supported; then
      printf 'available\t%s\t%s\n' "$tool" "$(version_for "$tool")"
    else
      printf 'incompatible\t%s\t%s (Bazel 7+ required)\n' "$tool" \
        "$(version_for "$tool")"
    fi
    return
  fi
  if tool_available "$tool"; then
    printf 'available\t%s\t%s\n' "$tool" "$(version_for "$tool")"
  else
    printf 'missing\t%s\t-\n' "$tool"
  fi
}

tools=(cmake ctest clang-format clang-tidy cppcheck valgrind bazel bzlmod compiler)
printf '%s\n' "yaml-cpp local evaluator tool inventory"
printf '%s\n' "repository: $repo_root"
for tool in "${tools[@]}"; do
  tool_state "$tool"
done

if $inventory_only; then
  exit 0
fi

missing=0
failures=0
waived=0
record() {
  local line=$1
  printf '%s\n' "$line"
  if [[ -n "$ledger" ]]; then
    printf '%s\n' "$line" >>"$ledger"
  fi
}

require_tool() {
  local tool=$1
  if tool_available "$tool"; then
    return 0
  fi
  if has_waiver "$tool"; then
    record "WAIVED $tool: user waiver supplied"
    waived=$((waived + 1))
    return 10
  fi
  record "MISSING $tool: ask the user to install it or waive this check"
  missing=$((missing + 1))
  return 1
}

run_step() {
  local name=$1
  shift
  record "RUN $name: $*"
  if "$@"; then
    record "PASS $name"
  else
    record "FAIL $name (exit $?)"
    failures=$((failures + 1))
  fi
}

if [[ -n "$ledger" ]]; then
  mkdir -p "$(dirname "$ledger")"
  record "## evaluator $(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

for required_tool in cmake ctest compiler; do
  if ! tool_available "$required_tool"; then
    if has_waiver "$required_tool"; then
      record "INVALID WAIVER $required_tool: this required tool must be installed"
    else
      record "MISSING $required_tool: ask the user to install it before evaluation"
    fi
    missing=$((missing + 1))
  fi
done

if ((missing > 0)); then
  record "STOP missing required tools: obtain user install/waive decisions before evaluation"
  exit 3
fi

changed_files=()
if git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  diff_base="$base_ref"
else
  record "NOTE base ref '$base_ref' is unavailable; using HEAD^ for changed-file checks"
  diff_base=HEAD^
fi
while IFS= read -r file; do
  [[ -n "$file" ]] && changed_files+=("$file")
done < <(git diff --name-only "$diff_base")
while IFS= read -r file; do
  [[ -n "$file" ]] && changed_files+=("$file")
done < <(git ls-files --others --exclude-standard)
if ((${#changed_files[@]} > 0)); then
  mapfile -t changed_files < <(printf '%s\n' "${changed_files[@]}" | sort -u)
fi

cpp_files=()
source_files=()
for file in "${changed_files[@]}"; do
  case "$file" in
    *.h|*.hpp|*.cc|*.cpp|*.cxx)
      cpp_files+=("$file")
      ;;
  esac
  case "$file" in
    *.cc|*.cpp|*.cxx)
      source_files+=("$file")
      ;;
  esac
done

mkdir -p "$build_root"
debug_build="$build_root/cmake-cxx11-debug"
run_step "cmake configure C++11 debug" cmake -S "$repo_root" -B "$debug_build" \
  -DCMAKE_CXX_STANDARD=11 -DCMAKE_CXX_STANDARD_REQUIRED=ON \
  -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DYAML_CPP_BUILD_TESTS=ON -DYAML_CPP_BUILD_TOOLS=OFF \
  -DYAML_CPP_FORMAT_SOURCE=OFF -DYAML_USE_SYSTEM_GTEST=OFF \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC"
run_step "cmake build C++11 debug" cmake --build "$debug_build" --parallel
run_step "ctest C++11 debug" ctest --test-dir "$debug_build" --output-on-failure

if ((${#cpp_files[@]} == 0)); then
  record "SKIP formatting: no changed C++ files"
else
  if require_tool clang-format; then
    run_step "clang-format changed C++ files" clang-format --dry-run --Werror \
      --style=file "${cpp_files[@]}"
  fi
fi

if ((${#source_files[@]} == 0)); then
  record "SKIP clang-tidy: no changed C++ implementation files"
else
  if require_tool clang-tidy; then
    run_step "clang-tidy changed C++ files" clang-tidy -p="$debug_build" \
      --warnings-as-errors='*' "${source_files[@]}"
  fi
fi

if ((${#cpp_files[@]} == 0)); then
  record "SKIP cppcheck: no changed C++ files"
elif require_tool cppcheck; then
  run_step "cppcheck changed C++ files" cppcheck --enable=warning,style,performance,portability \
    --error-exitcode=1 --std=c++11 -I include -I src "${cpp_files[@]}"
fi

sanitizer_build="$build_root/cmake-sanitizers"
if require_tool sanitizer; then
  compiler=${CXX:-c++}
  sanitizer_probe=$(mktemp -d)
  trap 'rm -f "$sanitizer_probe/probe"; rmdir "$sanitizer_probe"' EXIT
  if printf '%s\n' 'int main() { return 0; }' |
      "$compiler" -x c++ -std=c++11 -fsanitize=address,undefined \
        -fno-omit-frame-pointer -o "$sanitizer_probe/probe" -; then
    run_step "cmake configure sanitizers" cmake -S "$repo_root" -B "$sanitizer_build" \
      -DCMAKE_CXX_STANDARD=11 -DCMAKE_CXX_STANDARD_REQUIRED=ON \
      -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DYAML_CPP_BUILD_TESTS=ON -DYAML_CPP_BUILD_TOOLS=OFF \
      -DYAML_CPP_FORMAT_SOURCE=OFF -DYAML_USE_SYSTEM_GTEST=OFF \
      -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g" \
      -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined"
    run_step "cmake build sanitizers" cmake --build "$sanitizer_build" --parallel
    asan_runtime=$("$compiler" -print-file-name=libasan.so 2>/dev/null || true)
    if [[ -f "$asan_runtime" ]]; then
      run_step "ctest sanitizers" env LD_PRELOAD="$asan_runtime" ctest \
        --test-dir "$sanitizer_build" --output-on-failure
    else
      run_step "ctest sanitizers" ctest --test-dir "$sanitizer_build" \
        --output-on-failure
    fi
  else
    record "UNAVAILABLE sanitizer: compiler rejected address/undefined sanitizer flags"
    if has_waiver sanitizer; then
      record "WAIVED sanitizer: user waiver supplied after compiler rejection"
      waived=$((waived + 1))
    else
      missing=$((missing + 1))
    fi
  fi
fi

if require_tool valgrind; then
  test_binary="$debug_build/test/yaml-cpp-tests"
  run_step "valgrind yaml-cpp tests" valgrind --leak-check=full \
    --error-exitcode=1 "$test_binary"
fi

if require_tool bazel; then
  bazel_command=$(tool_command)
  run_step "bazel test" "$bazel_command" test --lockfile_mode=off test
fi

if require_tool bzlmod; then
  bazel_command=$(tool_command)
  run_step "bazel bzlmod test" "$bazel_command" test --enable_bzlmod \
    --lockfile_mode=off test
fi

if ((missing > 0 || failures > 0)); then
  record "RESULT incomplete: waived=$waived missing=$missing failures=$failures"
  exit 1
fi
if ((waived > 0)); then
  record "RESULT incomplete: waived=$waived missing=0 failures=0"
  exit 4
fi
record "RESULT pass: all non-waived local checks completed; waived=$waived"
