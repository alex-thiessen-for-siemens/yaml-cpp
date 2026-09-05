---
name: yaml-cpp-evaluation-loop
description: Run the deterministic yaml-cpp contribution evaluation loop with explicit tool decisions, focused repair, and a durable evidence ledger.
---

Use this loop after intake and after each material repair:

1. Update the private session evidence ledger with the hypothesis, changed
   files, current base, and the exact checks planned. Keep logs on disk and
   record only commands, exit status, useful diagnostics, and conclusions.
2. Inventory the tools and versions. Run
   `.github/skills/yaml-cpp-evaluation-loop/run-evaluation.sh --inventory`.
   For every useful missing or incompatible host tool, first check whether
   Docker can run
   `.github/skills/yaml-cpp-evaluation-loop/run-container-evaluation.sh`.
   The container installs a pinned Linux toolchain and official Bazel binary
   without changing the host. If Docker is unavailable, ask the user whether
   to install it or waive container coverage. Record the decision and scope. A
   waiver is not a pass.
3. Run the smallest relevant CMake test and formatting check first. Then run
   `run-evaluation.sh` on the host or the container runner with the selected
   waivers. Both evaluators use isolated build directories and never change
   source files.
4. Diagnose the first concrete failure. Inspect its output and affected code,
   make one focused repair, and rerun the affected phase. Do not rewrite a
   passing area or restart all model reasoning for an unrelated failure.
5. After deterministic checks pass, run bounded safety and acceptance reviews.
   Repair only concrete blockers and rerun the affected checks.
6. Stop when all required checks pass, every waiver is recorded, reviewers have
   no actionable blocker, and the ledger states remaining limitations.

The evaluator covers CMake C++11 debug tests, sanitizer tests when the
compiler supports them, changed-file formatting, clang-tidy, cppcheck,
Valgrind, Bazel, and Bzlmod when selected and available. The container route
uses Debian Trixie and Bazel 9.2.0 on native amd64 or arm64 Docker platforms.
Both Bazel commands use `--lockfile_mode=off` so evaluation never rewrites the
repository's checked-in `MODULE.bazel.lock`; lockfile freshness remains a
repository CI concern. It never claims that unavailable or waived checks
passed. GitHub's complete multi-platform matrix remains authoritative for
platform-only behavior.

Keep context bounded. Do not paste full logs into the conversation. At each
phase boundary, compact only after saving the ledger. After compaction, reread
the ledger, `git status`, and the current diff before continuing.
