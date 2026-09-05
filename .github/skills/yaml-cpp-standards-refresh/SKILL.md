---
name: yaml-cpp-standards-refresh
description: Refresh the private yaml-cpp Copilot setup when upstream standards, accepted patch patterns, CI, toolchains, or maintainer culture change.
---

Use this skill when upstream moves, a review rejects a pattern the setup
endorses, the evaluator reports tool drift, or the setup has not been reviewed
for a meaningful release cycle. Do not refresh from model intuition.

1. Fetch the intended upstream base and inspect current `CONTRIBUTING.md`,
   `SECURITY.md`, `.github/workflows/`, CMake settings, Bazel module files, and
   recent accepted pull requests. Use a bounded sample of patches that
   maintainers approved. Judge examples by correctness, scope, tests,
   compatibility, and review outcome rather than contributor identity or
   commit count.
2. Compare the current setup's instructions, skills, agents, evaluator, and
   calibration table with that evidence. Record proposed changes and the
   evidence for each in the private ledger before editing.
3. Refresh only the rule or resource that drifted. Keep always-loaded
   instructions short. Put detailed procedures in a skill. Update container
   tool versions and checksums together, and record the source release.
   Recheck whether the selected local reference implementations still match
   the YAML versions, schemas, and extension behavior used by the project;
   local-reference availability is evidence coverage, not a new upstream
   dependency. Recheck libyaml's parser/emitter scope separately and do not
   promote it to a constructor oracle. Refresh the latest stable release
   recorded for each selected reference library and require exact versions in
   future reference-verification commit bodies.
4. Run the host inventory and the container evaluator. If Docker is missing or
   its daemon is unavailable, ask the user to install or waive container
   coverage. Use QEMU only when Docker Buildx exposes the target platform with
   a working emulator. Never treat a Linux container or emulated ARM run as
   proof of Windows, macOS, or native ARM behavior.
5. Recheck Copilot CLI skill discovery and custom-agent frontmatter. Run
   `git diff --check`, inspect the complete setup diff, and update the
   calibration date and examples. Do not rewrite the setup merely to make its
   prose sound newer.
6. Commit the refresh separately with an imperative message and include the
   upstream commit or PRs that motivated it in the private ledger. Keep the
   setup branch's history reviewable.

Use `/unslop` only for the maintenance commit or review prose after its facts
are fixed. It must not edit source, tests, public documentation, or upstream
quotes.
