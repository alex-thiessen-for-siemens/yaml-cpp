---
name: yaml-cpp-upstream-readiness
description: Check that a yaml-cpp contribution is focused, evidenced, cleanly exported, and ready for upstream review.
---

Review the complete diff against the intended upstream base, not only the last
commit. Confirm:

* the request, root cause, invariant, and behavior change are clear;
* production edits are narrow and preserve C++11, public API/ABI, exception,
  ownership, and platform contracts;
* the regression lives in the owning existing suite and covers the changed
  boundary plus nearby valid behavior;
* CMake source lists, Bazel targets or globs, installation, package checks,
  and CI implications were considered when relevant;
* `git diff --check` passes, changed C++ files match `.clang-format`, and the
  evaluation ledger contains exact commands, results, user waivers, and
  remaining platform limitations. If host tools were missing or incompatible,
  it distinguishes Docker toolchain coverage from host coverage and records
  the image and tool versions;
* commit messages are imperative and describe the change, not the model;
* no private Copilot setup files, session ledgers, generated documentation, or
  unrelated cleanup will appear in the upstream PR.

Run `/unslop` only after the technical review. Apply it to the commit message,
PR title/body, or a concise review reply. Preserve every fact, number,
limitation, and attribution. Remove formulaic AI wording, but do not add
personality or claims that the diff and ledger cannot support. Never apply it
to source, tests, public documentation, or upstream text.

If the current work began on the private `llm-contribute` setup branch, use
`export-clean-branch.sh` to create a contribution branch from the upstream
base. That script carries only the contribution diff and leaves setup files
out of the final tree. Inspect the staged file list before committing. The
final comparison with the upstream base must contain only contribution files.

If the current CI, contribution rules, accepted patch patterns, or maintainer
culture have changed since calibration, run
`/yaml-cpp-standards-refresh` before declaring the contribution ready. Docker
and QEMU can provide Linux toolchain evidence only; they do not replace the
upstream Windows, macOS, or native ARM matrix.

Return only actionable blockers and a short evidence summary. Do not edit
files during this review unless the user explicitly asks for repairs.
