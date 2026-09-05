# Container evaluation

The host evaluator is the first choice. Use the container when a host tool is
missing, too old for the repository, or would require a privileged install:

```sh
.github/skills/yaml-cpp-evaluation-loop/run-container-evaluation.sh \
  --base upstream/master \
  --ledger /path/to/private/evidence-ledger.md
```

The image installs the current Debian Trixie build tools, Valgrind, the
libyaml C parser development files, and the official Bazel 9.2.0 Linux
binary. The Bazel binaries are downloaded over HTTPS and checked against the
SHA-256 values in the Dockerfile. Update the base-image digest, version, and
both architecture checksums together when the project or Bazel support moves
on. The evaluator records the image and tool versions in the private ledger.

The runner mounts only the repository and, when requested, the ledger's
parent directory. It runs as the invoking user's UID and keeps its default
build output in the disposable container under `/tmp`. A caller can provide
`--build-root` when persistent output is needed. It does not install anything
on the host. Bazel evaluation disables lockfile writes with
`--lockfile_mode=off`; the repository's checked-in lockfile is therefore
unchanged, and lockfile freshness must still be covered by upstream CI.

Docker provides a Linux toolchain, not Windows or macOS coverage. Use the
repository GitHub Actions matrix for those platforms. QEMU is useful only when
Docker Buildx reports the requested foreign platform and a working binfmt
handler is installed. The current x86_64 setup does not need QEMU for the
native image, and this runner refuses unsupported architectures instead of
pretending that emulation proves a native build.
