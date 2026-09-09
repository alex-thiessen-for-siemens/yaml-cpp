#!/usr/bin/env bash
#
# Automated ABI comparison runner for yaml-cpp.
# Compares shared library ABI between a baseline ref and a candidate ref/worktree
# using SONAME checks, exported dynamic symbol diffing, libabigail (abidiff),
# and bidirectional header/library skew probes.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-abi-comparison.sh [options]

Options:
  --baseline REF         Baseline git ref to compare against (default: upstream/master).
  --candidate REF|DIR    Candidate git ref or directory (default: current repo/worktree).
  --output-dir DIR       Output directory for build artifacts and reports (default: build/copilot-abi).
  --probe FILE           Path to custom C++ consumer skew probe source (optional).
  --docker               Force execution inside evaluation Docker container.
  --no-docker            Force execution on host without Docker.
  --help|-h              Show this help message.
EOF
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s\n' "error: run this script inside the yaml-cpp repository" >&2
  exit 2
}
cd "$repo_root"

baseline_ref="upstream/master"
candidate_arg=""
output_dir="$repo_root/build/copilot-abi"
probe_file=""
mode_docker="auto"
original_args=("$@")

while (($# > 0)); do
  case "$1" in
    --baseline)
      (($# >= 2)) || { printf '%s\n' "error: --baseline requires a ref" >&2; exit 2; }
      baseline_ref=$2
      shift 2
      ;;
    --candidate)
      (($# >= 2)) || { printf '%s\n' "error: --candidate requires a ref or path" >&2; exit 2; }
      candidate_arg=$2
      shift 2
      ;;
    --output-dir)
      (($# >= 2)) || { printf '%s\n' "error: --output-dir requires a path" >&2; exit 2; }
      output_dir=$2
      shift 2
      ;;
    --probe)
      (($# >= 2)) || { printf '%s\n' "error: --probe requires a file path" >&2; exit 2; }
      probe_file=$2
      shift 2
      ;;
    --docker)
      mode_docker="yes"
      shift
      ;;
    --no-docker)
      mode_docker="no"
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

# If inside container already, do not re-invoke docker
if [[ -f /.dockerenv || -n "${YAML_CPP_INSIDE_CONTAINER:-}" ]]; then
  mode_docker="no"
fi

# Determine if we should dispatch to Docker container
if [[ "$mode_docker" == "yes" ]] || { [[ "$mode_docker" == "auto" ]] && ! command -v abidiff >/dev/null 2>&1; }; then
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker_image=${YAML_CPP_EVAL_IMAGE:-yaml-cpp-copilot-eval:9.2.0}
    printf '%s\n' "Host abidiff missing or --docker specified; running ABI analysis in $docker_image..."

    # Ensure container image is built
    container_dir="$repo_root/.github/skills/yaml-cpp-evaluation-loop/container"
    docker build -q --tag "$docker_image" "$container_dir" >/dev/null

    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null || true)
    if [[ -n "$git_common_dir" && "$git_common_dir" != /* ]]; then
      if ! git_common_dir=$(cd "$repo_root/$git_common_dir" 2>/dev/null && pwd); then
        git_common_dir=""
      fi
    fi

    mounts=(-v "$repo_root:/workspace")
    if [[ -n "$git_common_dir" && -d "$git_common_dir" ]]; then
      case "$git_common_dir" in
        "$repo_root"/*) ;;
        *) mounts+=(-v "$git_common_dir:$git_common_dir:ro") ;;
      esac
    fi

    if [[ -n "$candidate_arg" && -d "$candidate_arg" ]]; then
      candidate_host_dir=$(cd "$candidate_arg" && pwd)
      case "$candidate_host_dir" in
        "$repo_root"|"$repo_root"/*) ;;
        *) mounts+=(-v "$candidate_host_dir:$candidate_host_dir:ro") ;;
      esac
    fi
    if [[ -n "$probe_file" && -f "$probe_file" ]]; then
      probe_host_file=$(cd "$(dirname "$probe_file")" && pwd)/$(basename "$probe_file")
      case "$probe_host_file" in
        "$repo_root"|"$repo_root"/*) ;;
        *) mounts+=(-v "$probe_host_file:$probe_host_file:ro") ;;
      esac
    fi
    if [[ "$output_dir" == /* ]]; then
      mkdir -p "$output_dir"
      case "$output_dir" in
        "$repo_root"|"$repo_root"/*) ;;
        *) mounts+=(-v "$output_dir:$output_dir") ;;
      esac
    fi

    user_name=$(id -un)
    exec docker run --rm \
      --user "$(id -u):$(id -g)" \
      --env HOME=/tmp/copilot-home \
      --env "USER=$user_name" \
      --env GIT_CONFIG_COUNT=1 \
      --env GIT_CONFIG_KEY_0=safe.directory \
      --env "GIT_CONFIG_VALUE_0=*" \
      --env YAML_CPP_INSIDE_CONTAINER=1 \
      --workdir /workspace \
      "${mounts[@]}" \
      "$docker_image" \
      /workspace/.github/skills/yaml-cpp-abi-analysis/run-abi-comparison.sh "${original_args[@]}"
  elif [[ "$mode_docker" == "yes" ]]; then
    printf '%s\n' "error: Docker requested but docker daemon is unavailable" >&2
    exit 3
  else
    printf '%s\n' "WARNING: abidiff is not available on host and Docker is unavailable; continuing with symbol-only comparison" >&2
  fi
fi

# Resolve baseline source
git rev-parse --verify "$baseline_ref^{commit}" >/dev/null 2>&1 || {
  printf 'error: baseline ref is invalid: %s\n' "$baseline_ref" >&2
  exit 2
}
baseline_commit=$(git rev-parse --verify "$baseline_ref^{commit}")

mkdir -p "$output_dir"
baseline_build="$output_dir/build-baseline"
candidate_build="$output_dir/build-candidate"
baseline_dir="$output_dir/src-baseline"

rm -rf "$baseline_dir" "$baseline_build"
mkdir -p "$baseline_dir" "$baseline_build"
git archive "$baseline_commit" | tar -x -C "$baseline_dir"

# Resolve candidate source
candidate_dir=""
if [[ -z "$candidate_arg" ]]; then
  candidate_dir="$repo_root"
elif [[ -d "$candidate_arg" ]]; then
  candidate_dir=$(cd "$candidate_arg" && pwd)
else
  # Treat as git ref
  git rev-parse --verify "$candidate_arg^{commit}" >/dev/null 2>&1 || {
    printf 'error: candidate ref is invalid: %s\n' "$candidate_arg" >&2
    exit 2
  }
  candidate_dir="$output_dir/src-candidate"
  rm -rf "$candidate_dir" "$candidate_build"
  mkdir -p "$candidate_dir" "$candidate_build"
  git archive "$candidate_arg" | tar -x -C "$candidate_dir"
fi

mkdir -p "$candidate_build"

printf '=== yaml-cpp ABI Comparison ===\n'
printf 'Baseline:  %s (%s)\n' "$baseline_ref" "$baseline_commit"
printf 'Candidate: %s\n' "${candidate_arg:-$candidate_dir}"
printf 'Output:    %s\n\n' "$output_dir"

printf '[1/6] Building baseline shared library...\n'
cmake -S "$baseline_dir" -B "$baseline_build" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=ON \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF \
  -DYAML_CPP_FORMAT_SOURCE=OFF \
  -DCMAKE_CXX_STANDARD=11 >/dev/null
cmake --build "$baseline_build" --target yaml-cpp --parallel >/dev/null

printf '[2/6] Building candidate shared library...\n'
cmake -S "$candidate_dir" -B "$candidate_build" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=ON \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF \
  -DYAML_CPP_FORMAT_SOURCE=OFF \
  -DCMAKE_CXX_STANDARD=11 >/dev/null
cmake --build "$candidate_build" --target yaml-cpp --parallel >/dev/null

# Locate built shared libraries
find_so() {
  local dir=$1
  find "$dir" -maxdepth 2 -name "libyaml-cpp.so*" -type f | sort | head -1
}

baseline_so=$(find_so "$baseline_build")
candidate_so=$(find_so "$candidate_build")

if [[ -z "$baseline_so" || ! -f "$baseline_so" ]]; then
  printf 'error: baseline shared library not found in %s\n' "$baseline_build" >&2
  exit 2
fi
if [[ -z "$candidate_so" || ! -f "$candidate_so" ]]; then
  printf 'error: candidate shared library not found in %s\n' "$candidate_build" >&2
  exit 2
fi

printf '[3/6] Inspecting SONAMEs...\n'
extract_soname() {
  local lib=$1
  readelf -d "$lib" 2>/dev/null | grep -E 'SONAME' | awk '{print $NF}' | tr -d '[]' || true
}
baseline_soname=$(extract_soname "$baseline_so")
candidate_soname=$(extract_soname "$candidate_so")

printf '  Baseline SONAME:  %s\n' "$baseline_soname"
printf '  Candidate SONAME: %s\n' "$candidate_soname"

soname_status="MATCH"
if [[ "$baseline_soname" != "$candidate_soname" ]]; then
  soname_status="CHANGED"
  printf '  WARNING: SONAME changed from %s to %s\n' "$baseline_soname" "$candidate_soname"
else
  printf '  SONAME preserved: %s\n' "$baseline_soname"
fi

printf '[4/6] Comparing exported dynamic symbols...\n'
baseline_syms="$output_dir/baseline_symbols.txt"
candidate_syms="$output_dir/candidate_symbols.txt"
nm -D --defined-only "$baseline_so" | awk '{print $3}' | sort -u > "$baseline_syms"
nm -D --defined-only "$candidate_so" | awk '{print $3}' | sort -u > "$candidate_syms"

baseline_syms_demangled="$output_dir/baseline_symbols_demangled.txt"
candidate_syms_demangled="$output_dir/candidate_symbols_demangled.txt"
c++filt <"$baseline_syms" | sort -u >"$baseline_syms_demangled"
c++filt <"$candidate_syms" | sort -u >"$candidate_syms_demangled"

removed_syms=$(comm -23 "$baseline_syms" "$candidate_syms" | wc -l)
added_syms=$(comm -13 "$baseline_syms" "$candidate_syms" | wc -l)
printf '  Exported dynamic symbols: baseline=%d, candidate=%d\n' \
  "$(wc -l < "$baseline_syms")" "$(wc -l < "$candidate_syms")"
printf '  Symbol diff: removed=%d, added=%d\n' "$removed_syms" "$added_syms"

if ((removed_syms > 0)); then
  printf '  WARNING: %d symbols removed in candidate:\n' "$removed_syms"
  comm -23 "$baseline_syms_demangled" "$candidate_syms_demangled" | head -10 | sed 's/^/    - /'
  if ((removed_syms > 10)); then
    printf '    ... and %d more\n' "$((removed_syms - 10))"
  fi
fi

printf '[5/6] Running libabigail (abidiff)...\n'
abidiff_report="$output_dir/abidiff_report.txt"
abidiff_available=false
abidiff_status=0
abidiff_structural_changes=false

if command -v abidiff >/dev/null 2>&1; then
  abidiff_available=true
  printf '  Running abidiff (version %s)...\n' "$(abidiff --version 2>&1 | head -1)"
  set +e
  abidiff --drop-private-types \
    --headers-dir1 "$baseline_dir/include" \
    --headers-dir2 "$candidate_dir/include" \
    "$baseline_so" "$candidate_so" > "$abidiff_report" 2>&1
  abidiff_status=$?
  set -e
  if grep -Eq \
    '^(Functions|Variables) changes summary: ([1-9][0-9]* Removed|[0-9]+ Removed, [1-9][0-9]* Changed|[0-9]+ Removed, [0-9]+ Changed, [1-9][0-9]* Added)' \
    "$abidiff_report"; then
    abidiff_structural_changes=true
  fi
  if [[ $abidiff_status -eq 0 ]]; then
    printf '  abidiff: NO ABI INCOMPATIBILITIES DETECTED (exit 0)\n'
  else
    printf '  abidiff: REPORTED DIFFERENCES (exit code %d)\n' "$abidiff_status"
    printf '  Summary of abidiff report (%s):\n' "$abidiff_report"
    head -25 "$abidiff_report" | sed 's/^/    /'
  fi
else
  printf '  LIMITATION: abidiff is not installed; skipping deep structural ABI diff\n'
fi

printf '[6/6] Executing bidirectional consumer skew probes...\n'
probe_src="$output_dir/consumer_probe.cpp"
if [[ -n "$probe_file" && -f "$probe_file" ]]; then
  cp "$probe_file" "$probe_src"
else
  cat <<'PROBE_EOF' > "$probe_src"
#include "yaml-cpp/yaml.h"
#include <iostream>
#include <cassert>

int main() {
  YAML::Node node = YAML::Load("name: yaml-cpp\nversion: 0.8\nlist: [a, b, c]");
  assert(node["name"].as<std::string>() == "yaml-cpp");
  assert(node["version"].as<double>() > 0.7);
  assert(node["list"].size() == 3);

  YAML::Emitter emitter;
  emitter << YAML::BeginMap;
  emitter << YAML::Key << "abi_probe" << YAML::Value << 42;
  emitter << YAML::EndMap;
  assert(emitter.good());

  YAML::Mark mark = YAML::Mark::null_mark();
  assert(mark.is_null());

  std::cout << "OK" << std::endl;
  return 0;
}
PROBE_EOF
fi

probe_cxx=${CXX:-c++}
skew_1_pass=false
skew_2_pass=false

# Skew 1: Old headers + New library
probe1_bin="$output_dir/probe_oldheaders_newlib"
probe1_err="$output_dir/probe1_compile_err.log"
if "$probe_cxx" -std=c++11 -I "$baseline_dir/include" "$probe_src" \
    -L "$(dirname "$candidate_so")" -lyaml-cpp -o "$probe1_bin" >"$probe1_err" 2>&1; then
  probe1_out=$(LD_LIBRARY_PATH="$(dirname "$candidate_so"):${LD_LIBRARY_PATH:-}" "$probe1_bin" 2>&1 || true)
  if [[ "$probe1_out" =~ OK ]]; then
    skew_1_pass=true
    printf '  Skew 1 (old headers + new library): PASS\n'
  else
    printf '  Skew 1 (old headers + new library): FAIL (run output: %s)\n' "$probe1_out"
  fi
else
  printf '  Skew 1 (old headers + new library): COMPILE_FAIL (see %s)\n' "$probe1_err"
fi

# Skew 2: New headers + Old library
probe2_bin="$output_dir/probe_newheaders_oldlib"
probe2_err="$output_dir/probe2_compile_err.log"
if "$probe_cxx" -std=c++11 -I "$candidate_dir/include" "$probe_src" \
    -L "$(dirname "$baseline_so")" -lyaml-cpp -o "$probe2_bin" >"$probe2_err" 2>&1; then
  probe2_out=$(LD_LIBRARY_PATH="$(dirname "$baseline_so"):${LD_LIBRARY_PATH:-}" "$probe2_bin" 2>&1 || true)
  if [[ "$probe2_out" =~ OK ]]; then
    skew_2_pass=true
    printf '  Skew 2 (new headers + old library): PASS\n'
  else
    printf '  Skew 2 (new headers + old library): FAIL (run output: %s)\n' "$probe2_out"
  fi
else
  printf '  Skew 2 (new headers + old library): COMPILE_FAIL (see %s)\n' "$probe2_err"
fi

printf '\n=== ABI Comparison Summary ===\n'
printf 'SONAME Status:    %s (%s -> %s)\n' "$soname_status" "$baseline_soname" "$candidate_soname"
printf 'Symbol Changes:   -%d / +%d\n' "$removed_syms" "$added_syms"
if $abidiff_available; then
  if [[ $abidiff_status -eq 0 ]]; then
    printf 'abidiff Status:   PASS (0 incompatibilities)\n'
  else
    printf 'abidiff Status:   INCOMPATIBILITIES (exit %d)\n' "$abidiff_status"
  fi
else
  printf 'abidiff Status:   NOT_RUN (tool missing)\n'
fi
printf 'Consumer Skew 1:  %s\n' "$([[ "$skew_1_pass" == true ]] && echo "PASS" || echo "FAIL")"
printf 'Consumer Skew 2:  %s\n' "$([[ "$skew_2_pass" == true ]] && echo "PASS" || echo "FAIL")"

overall_verdict="ABI preserved"
exit_code=0

if [[ "$soname_status" != "MATCH" ]]; then
  overall_verdict="SONAME changed (downstream rebuild required)"
  exit_code=1
fi
if ((removed_syms > 0)); then
  overall_verdict="ABI BREAKAGE: Exported dynamic symbols were removed"
  exit_code=1
fi
if $abidiff_available && [[ $abidiff_status -ne 0 ]]; then
  if [[ "$abidiff_structural_changes" == true ]]; then
    overall_verdict="ABI BREAKAGE: Incompatible structural ABI change detected by abidiff"
    exit_code=1
  elif (( (abidiff_status & 1) != 0 )); then
    overall_verdict="ABI evidence incomplete (abidiff failed)"
    exit_code=1
  else
    overall_verdict="ABI differences require review (symbol-only changes)"
    exit_code=1
  fi
fi
if [[ "$skew_1_pass" != true || "$skew_2_pass" != true ]]; then
  overall_verdict="ABI BREAKAGE: Consumer skew probe failed"
  exit_code=1
fi
if ! $abidiff_available; then
  overall_verdict="ABI evidence incomplete (abidiff was not executed)"
fi

printf 'Conclusion:       %s\n' "$overall_verdict"
exit "$exit_code"
