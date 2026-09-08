---
name: yaml-cpp-upstream-readiness
description: Check that a yaml-cpp contribution is focused, evidenced, cleanly exported, and ready for upstream review.
---

Review the complete diff against the intended upstream base, not only the last
commit. Confirm:

* the request, root cause, invariant, and behavior change are clear;
* production edits are narrow and preserve C++11, public API/ABI, exception,
  ownership, and platform contracts. For public headers, exported symbols or
  classes, inline implementations, visibility, package boundaries, and
  `SOVERSION`, require the `/yaml-cpp-abi-analysis` conclusion and verify
  that any ABI transition is explicitly authorized;
* the owning existing suite contains a test that prevents regressions and
  covers the changed boundary plus nearby valid behavior;
* YAML-observable behavior changes have local-reference evidence in the
  private ledger, including implementation version, schema, fixture,
  normalization, and result, or an explicit not-applicable limitation;
* parser- or event-level behavior also records separate local libyaml C
  evidence when available, without treating libyaml as a native-value
  constructor;
* the final feature commit body contains a `Reference verification:` block
  naming every reference library, exact version, schema or parser layer, and
  result when comparison passed, or an explicit not-applicable reason;
  run `check-reference-commit-message.sh` against that commit before export;
* the current upstream `CONTRIBUTING.md` AI-usage policy is followed. AI is a
  tool, not a co-author, so upstream feature commits contain no AI
  `Co-authored-by` trailer; run the commit checker in upstream mode;
* CMake source lists, Bazel targets or globs, installation, package checks,
  and CI implications were considered when relevant;
* shared-library baselines, SONAMEs, class layouts, and old/new
  header-library compatibility probes were considered for ABI-sensitive
  changes. Missing ABI tooling is recorded as a limitation, never as a pass;
* `git diff --check` passes, changed C++ files match `.clang-format`, and the
  evaluation ledger contains exact commands, results, user waivers, and
  remaining platform limitations. If host tools were missing or incompatible,
  it distinguishes Docker toolchain coverage from host coverage and records
  the image and tool versions;
* commit messages are imperative and describe the change, not the model;
  They describe tests as covering a bug or preventing future regressions,
  never as adding a regression. Every subject and body line is at most 72
  characters. Require one subject line, exactly one blank line before the
  body, and contiguous body paragraphs wrapped at natural boundaries close to
  72 rather than prematurely;
* no private Copilot setup files, session ledgers, generated documentation, or
  unrelated cleanup will appear in the upstream PR. Pre-existing formatting
  or static-analysis findings outside changed hunks are preserved rather than
  “fixed” opportunistically;
* feature-introduced review repairs are folded into the relevant feature
  commit or logical series. A correction-only commit is a readiness blocker
  unless the user explicitly requested an incremental history.

Run `/unslop` only after the technical review. Apply it to the commit message,
PR title/body, or a concise review reply. Preserve every fact, number,
limitation, and attribution. Remove formulaic AI wording, but do not add
personality or claims that the diff and ledger cannot support. Never apply it
to source, tests, public documentation, or upstream text.

If the current work began from the private `llm-contribute` setup ref, keep
the implementation worktree on its setup-backed temporary branch. Run
`export-clean-branch.sh` from that worktree to create the contribution branch
and staged diff in a separate worktree based on the upstream base. The script
carries only the contribution diff and leaves private `.github` files and
known setup research documents out of the clean tree. Inspect the staged file
list in the separate worktree before committing. Fold all review repairs
before this export, inspect `git log BASE..HEAD`, and ensure the final
comparison with the upstream base contains only contribution files and no
correction-only commit. Keep the implementation worktree available for any
later skill or reviewer invocation.

If the current CI, contribution rules, accepted patch patterns, or maintainer
culture have changed since calibration, run
`/yaml-cpp-standards-refresh` before declaring the contribution ready. Docker
and QEMU can provide Linux toolchain evidence only; they do not replace the
upstream Windows, macOS, or native ARM matrix.

Return only actionable blockers and a short evidence summary. Do not edit
files during this review unless the user explicitly asks for repairs.
