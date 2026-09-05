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
   For every useful missing tool, ask the user whether to install it or waive
   the corresponding check. Never install software without that decision.
   Record the decision and scope. A waiver is not a pass.
3. Run the smallest relevant CMake test and formatting check first. Then run
   `run-evaluation.sh` with the selected waivers. The evaluator uses isolated
   build directories and never changes source files.
4. Diagnose the first concrete failure. Inspect its output and affected code,
   make one focused repair, and rerun the affected phase. Do not rewrite a
   passing area or restart all model reasoning for an unrelated failure.
5. After deterministic checks pass, run bounded safety and acceptance reviews.
   Repair only concrete blockers and rerun the affected checks.
6. Stop when all required checks pass, every waiver is recorded, reviewers have
   no actionable blocker, and the ledger states remaining limitations.

The evaluator covers CMake C++11 debug tests, sanitizer tests when the
compiler supports them, changed-file formatting, clang-tidy, cppcheck,
Valgrind, Bazel, and Bzlmod when selected and available. It never claims that
unavailable or waived checks passed. GitHub's complete multi-platform matrix
remains authoritative for platform-only behavior.

Keep context bounded. Do not paste full logs into the conversation. At each
phase boundary, compact only after saving the ledger. After compaction, reread
the ledger, `git status`, and the current diff before continuing.
