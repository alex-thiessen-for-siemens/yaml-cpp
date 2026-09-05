#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
container_dir="$repo_root/.github/skills/yaml-cpp-evaluation-loop/container"
docker_image=${YAML_CPP_EVAL_IMAGE:-yaml-cpp-copilot-eval:9.2.0}
target_arch=${YAML_CPP_EVAL_ARCH:-}
ledger_path=

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' \
    "missing Docker: ask the user to install a Docker runtime or waive container evaluation" \
    >&2
  exit 3
fi
if ! docker info >/dev/null 2>&1; then
  printf '%s\n' \
    "Docker daemon is unavailable: ask the user to start it or waive container evaluation" \
    >&2
  exit 3
fi

if [[ -z "$target_arch" ]]; then
  case "$(uname -m)" in
    x86_64) target_arch=amd64 ;;
    aarch64|arm64) target_arch=arm64 ;;
    *)
      printf 'unsupported native architecture: %s\n' "$(uname -m)" >&2
      exit 3
      ;;
  esac
fi

case "$target_arch" in
  amd64|arm64)
    ;;
  *)
    printf 'unsupported Docker target architecture: %s\n' "$target_arch" >&2
    exit 3
    ;;
esac

native_arch=
case "$(uname -m)" in
  x86_64) native_arch=amd64 ;;
  aarch64|arm64) native_arch=arm64 ;;
esac
if [[ "$target_arch" != "$native_arch" ]]; then
  available_platforms=$(docker buildx inspect --bootstrap 2>/dev/null) || {
    printf '%s\n' \
      "Docker Buildx platform inspection failed; install binfmt/QEMU or waive that architecture" \
      >&2
    exit 3
  }
  if ! grep -q "linux/$target_arch" <<<"$available_platforms"; then
    printf '%s\n' \
      "Docker does not expose linux/$target_arch; install binfmt/QEMU or waive that architecture" \
      >&2
    exit 3
  fi
fi

if (($# > 0)); then
  args=("$@")
else
  args=()
fi

has_build_root=false
for ((index = 0; index < ${#args[@]}; index++)); do
  case "${args[index]}" in
    --build-root)
      has_build_root=true
      ;;
    --ledger)
      if ((index + 1 < ${#args[@]})); then
        ledger_path=${args[index + 1]}
        if [[ "$ledger_path" != /* ]]; then
          ledger_path="$repo_root/$ledger_path"
          args[index + 1]=$ledger_path
        fi
      fi
      ;;
  esac
done
if [[ "$has_build_root" == false ]]; then
  args+=(--build-root /tmp/yaml-cpp-copilot-eval)
fi

user_name=$(id -un)

docker build \
  --build-arg "TARGETARCH=$target_arch" \
  --platform "linux/$target_arch" \
  --tag "$docker_image" \
  --file "$container_dir/Dockerfile" \
  "$container_dir"

mounts=(-v "$repo_root:/workspace")
if [[ -n "$ledger_path" ]]; then
  ledger_dir=$(dirname "$ledger_path")
  mkdir -p "$ledger_dir"
  mounts+=(-v "$ledger_dir:$ledger_dir")
fi

printf 'Running yaml-cpp evaluator in %s (%s)\n' "$docker_image" "$target_arch"
docker_args=(
  docker run --rm
  --platform "linux/$target_arch"
  --user "$(id -u):$(id -g)"
  --env HOME=/tmp/copilot-home
  --env "USER=$user_name"
  --ulimit nofile=65536:65536
  --workdir /workspace
  "${mounts[@]}"
)

if [[ -n "$ledger_path" ]]; then
  {
    printf '## container toolchain %s (%s)\n' "$docker_image" "$target_arch"
    "${docker_args[@]}" \
      "$docker_image" \
      bash -c \
      'for tool in bazel cmake clang-format clang-tidy cppcheck valgrind; do
         printf "%s: " "$tool"
         "$tool" --version 2>&1 | head -1
       done'
  } | tee -a "$ledger_path"
fi

"${docker_args[@]}" \
  "$docker_image" \
  /workspace/.github/skills/yaml-cpp-evaluation-loop/run-evaluation.sh \
  "${args[@]}"
