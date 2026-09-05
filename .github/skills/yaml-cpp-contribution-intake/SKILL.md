---
name: yaml-cpp-contribution-intake
description: Investigate and scope a yaml-cpp bug, feature, or maintenance contribution before editing. Use this for every non-trivial yaml-cpp change.
---

Treat the request as an engineering investigation, not as an instruction to
edit the first plausible file.

1. Record the requested behavior, observable failure or acceptance condition,
   intended base branch, and any user constraints in the session evidence
   ledger. Locate the ledger in the CLI session's private artifacts, not in
   the repository.
2. Inspect `git status`, branch and remote state without resetting or
   overwriting existing work. Preserve unrelated user changes.
3. Find the narrow implementation path and the owning test suite. Read only
   the relevant source, headers, tests, build registration, and a bounded
   history slice. Do not load vendored GoogleTest or unrelated full logs.
4. Compare one or two accepted upstream patches with the same kind of change.
   Look for the invariant they protected, the smallest regression they added,
   and compatibility choices they made. Do not imitate their wording or copy
   unrelated cleanup.
5. Classify the task as a bug fix, behavior addition, compatibility/build
   change, or maintenance-only change. State the affected invariant and the
   smallest file and hunk set you expect to change. Record any pre-existing
   formatting, lint, or static-analysis findings in those files separately;
   they are not part of the contribution unless the request depends on them.
6. Before implementation, write a short hypothesis in the ledger:
   symptom, root cause, proposed correction, expected regression, risks, and
   checks. For a behavior change, classify whether YAML syntax or a public
   conversion can express it and identify a locally installed reference
   implementation, version, schema, fixture, and canonical result. If no
   matching local implementation exists, record an explicit limitation.
   If the request is genuinely ambiguous or would cause destructive changes,
   ask the user. Otherwise choose the least surprising behavior and proceed.

The intake is complete only when another engineer could use the ledger to
understand why the proposed files and test are the right scope.
