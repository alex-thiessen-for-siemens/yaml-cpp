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
3. For YAML-observable behavior changes, run
   `/yaml-cpp-reference-check` after the targeted regression and before the
   broad evaluator. Use only local adapters and a local fixture; record the
   implementation version, schema, normalization, and result. For parser- or
   event-level behavior, include the private libyaml C adapter as an
   additional parser-only comparison. For resolved or constructed values,
   retain a matching semantic implementation as a separate comparison. A
   mismatch is a failure. If no matching local implementation exists, record
   the explicit limitation and do not call the behavior reference-verified.
4. Run the smallest relevant CMake test and formatting check first. Then run
   `run-evaluation.sh` on the host or the container runner with the selected
   waivers. Both evaluators use isolated build directories and never change
   source files. Formatting is checked on changed line ranges, and cppcheck
   diagnostics are compared with those ranges, so a pre-existing finding on
   an untouched line must not force unrelated cleanup. A finding in a changed
   range remains a failure.
5. Diagnose the first concrete failure. Inspect its output and affected code,
   make one focused repair, and rerun the affected phase. Do not rewrite a
   passing area or restart all model reasoning for an unrelated failure. If
   the failure was introduced by the feature, keep the repair in the existing
   feature commit or logical series; use amend or fixup/autosquash rather than
   adding a correction-only commit.
6. After deterministic checks pass, run bounded safety and acceptance reviews.
   Repair only concrete blockers and rerun the affected checks.
7. Before upstream readiness, inspect the complete feature history. Fold
   review repairs caused by the feature into the relevant commit or series,
   then rerun affected checks. If a reference comparison passed, require a
   `Reference verification:` block in the feature commit body with every
   reference's exact version, schema or layer, and result. If no reference
   applies, require the explicit not-applicable reason instead. Stop only when
   all required checks pass, every waiver is recorded, reviewers have no
   actionable blocker, the history has no correction-only commit, and the
   ledger states remaining limitations. Use
   `check-reference-commit-message.sh` to enforce the body requirement.

The evaluator covers CMake C++11 debug tests, sanitizer tests when the
compiler supports them, changed-file formatting, clang-tidy, cppcheck,
Valgrind, Bazel, and Bzlmod when selected and available. The container route
uses Debian Trixie and Bazel 9.2.0 on native amd64 or arm64 Docker platforms.
Both Bazel commands use `--lockfile_mode=off` so evaluation never rewrites the
repository's checked-in `MODULE.bazel.lock`; lockfile freshness remains a
repository CI concern. It never claims that unavailable or waived checks
passed. GitHub's complete multi-platform matrix remains authoritative for
platform-only behavior.

The reference comparison is local-only evidence and does not replace
yaml-test-suite or the upstream multi-platform CI matrix. It must not download
packages, contact a hosted parser, or publish fixtures and results.

Do not repair a baseline diagnostic merely to make this evaluator green.
When a tool reports an unchanged-line finding, preserve the line, record it
as baseline debt in the ledger, and continue with the changed-hunk result.
If a tool cannot provide a scoped result, stop before widening the diff and
record the coverage limitation for review.

Keep context bounded. Do not paste full logs into the conversation. At each
phase boundary, compact only after saving the ledger. After compaction, reread
the ledger, `git status`, and the current diff before continuing.
