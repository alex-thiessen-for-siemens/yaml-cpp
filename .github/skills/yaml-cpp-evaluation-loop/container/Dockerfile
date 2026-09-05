FROM debian:trixie-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ARG TARGETARCH
ARG BAZEL_VERSION=9.2.0
ARG BAZEL_SHA256_AMD64=7668a95db1250f12c40407251e4e203b4ec8bf39bc495d2f485b2d8c99048694
ARG BAZEL_SHA256_ARM64=049dd21f40ad979db11c3ee68c96a42ce75f1185e69ac61ab20de1501427a410

LABEL org.opencontainers.image.title="yaml-cpp Copilot evaluation toolchain"
LABEL org.opencontainers.image.description="Pinned Linux checks for yaml-cpp contributions"
LABEL org.opencontainers.image.source="https://github.com/alex-thiessen-for-siemens/yaml-cpp"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    bash \
    build-essential \
    ca-certificates \
    clang-format \
    clang-tidy \
    cmake \
    cppcheck \
    curl \
    default-jre-headless \
    git \
    ninja-build \
    valgrind \
  && case "$TARGETARCH" in \
       amd64) bazel_asset="bazel-${BAZEL_VERSION}-linux-x86_64"; \
              bazel_sha256="$BAZEL_SHA256_AMD64" ;; \
       arm64) bazel_asset="bazel-${BAZEL_VERSION}-linux-arm64"; \
              bazel_sha256="$BAZEL_SHA256_ARM64" ;; \
       *) printf 'unsupported Docker architecture: %s\n' "$TARGETARCH" >&2; exit 1 ;; \
     esac \
  && curl --fail --location --retry 3 \
       "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${bazel_asset}" \
       --output /usr/local/bin/bazel \
  && printf '%s  %s\n' "$bazel_sha256" /usr/local/bin/bazel | sha256sum --check \
  && chmod 755 /usr/local/bin/bazel \
  && mkdir -p /tmp/copilot-home \
  && chmod 1777 /tmp/copilot-home \
  && apt-get clean

ENV HOME=/tmp/copilot-home
WORKDIR /workspace
