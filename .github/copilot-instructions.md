# yaml-cpp contribution rules

Work on one focused contribution at a time. Start from a reproducible bug,
requested behavior, or a clearly stated maintenance task. Before editing,
inspect the relevant implementation, its owning tests, nearby invariants, and
recent history. Do not guess from filenames or from an issue title alone.

Preserve the public API, ABI, C++11 support, exception contracts, and the
platform behavior covered by the project. Prefer the smallest change that
fixes the root cause. Do not mix drive-by cleanup, formatting-only changes,
documentation generation, or dependency updates into a code contribution.
Never modify vendored GoogleTest unless the task explicitly requires it.
Scope is hunk-level, not merely file-level: record the intended files and
behavioral hunks before editing, then inspect the complete diff after every
repair. A formatter, linter, or static analyzer finding on an unchanged line
is baseline debt, not permission to rewrite that line. Preserve it, use a
line-scoped or baseline-aware check, and record the limitation rather than
expanding the contribution. Only change an unrelated line when the user
explicitly expands scope or the line is required for the requested behavior.

Every behavior change needs a deterministic regression in the test suite that
owns the behavior. Test valid inputs and the relevant boundary or malformed
input. For changes involving ownership, indexing, arithmetic, streams,
iterators, parser state, or emitter state, trace the full lifetime and state
transition path before editing. Make ownership and failure behavior explicit.

Use the repository's `.clang-format` and surrounding code style. Run the
targeted CMake test first, then the maximum practical evaluation described by
`/yaml-cpp-evaluation-loop`. If a host tool is missing or too old, use the
Docker evaluator when its daemon is available. If Docker is unavailable, stop
and ask the user whether to install it or waive container coverage. Record the
tool or image version, decision, and coverage in the session evidence ledger.
Never silently skip a check or call a waived check passed.

Keep the context small. Read only relevant source, tests, and history. Do not
load vendored GoogleTest or paste full build logs into the conversation. Keep a
session-local evidence ledger with the request, invariant, changed files,
commands and results, unresolved risks, and tool decisions. Update it at phase
boundaries. After context compaction, reread the ledger and the current diff
before acting. Treat the actual files and command output as the source of
truth.

Run independent, bounded safety and acceptance reviews only after a material
diff and deterministic checks. Repair concrete findings, then rerun the
affected checks. Stop when the diff is focused, the evidence is complete, and
no actionable blocker remains. Do not repeatedly ask a model to rewrite a
passing change.

When upstream's build matrix, contribution rules, accepted patch patterns, or
review culture changes, use `/yaml-cpp-standards-refresh` before relying on
this setup. Treat the repository and recent maintainer-approved changes as
the source of current standards, not this setup's older examples.

Before presenting a contribution, run `git diff --check`, inspect the complete
diff against its intended base, and verify that the final branch contains no
private setup files. Use `/yaml-cpp-upstream-readiness` for the final check.
Write imperative commit messages. Use `/unslop` only on fact-checked commit,
pull request, or review prose. Do not use it to generate source comments,
public documentation, tests, or claims not supported by the diff and evidence.
The author remains responsible for understanding and reviewing the contribution.
