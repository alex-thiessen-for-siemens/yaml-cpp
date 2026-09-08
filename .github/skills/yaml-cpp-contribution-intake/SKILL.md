---
name: yaml-cpp-contribution-intake
description: Investigate and scope a yaml-cpp bug, feature, or maintenance contribution before editing. Use this for every non-trivial yaml-cpp change.
---

Treat the request as an engineering investigation, not as an instruction to
edit the first plausible file.

Before the numbered steps, confirm that the work is running in a dedicated
implementation worktree created with the private setup overlay. From the
setup checkout, use
`.github/skills/yaml-cpp-contribution-intake/create-contribution-worktree.sh
WORKTREE_PATH IMPLEMENTATION_BRANCH [SETUP_REF] [BASE_REF]`. The helper starts
the implementation branch from `BASE_REF`, copies only the private `.github`
setup from `SETUP_REF`, and commits that overlay. The implementation worktree
must contain `.github/copilot-instructions.md`, the required skills, and the
custom agents. Do not implement on the setup checkout or on a clean
upstream-only branch, because those checkouts cannot discover the
repository-local workflow.

Before any commit, run
`.github/skills/yaml-cpp-contribution-intake/configure-commit-signing.sh`.
All commits must be signed with key ID `9F77750E827051B3`. Use
`check-commit-signatures.sh BASE..HEAD` before export and record its result in
the private evidence ledger.

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
   Look for the invariant they protected, the smallest test that guards it,
   and compatibility choices they made. Do not imitate their wording or copy
   unrelated cleanup.
5. Classify the task as a bug fix, behavior addition, compatibility/build
   change, or maintenance-only change. State the affected invariant and the
   smallest file and hunk set you expect to change. Record any pre-existing
   formatting, lint, or static-analysis findings in those files separately;
   they are not part of the contribution unless the request depends on them.
6. Before implementation, write a short hypothesis in the ledger:
   symptom, root cause, proposed correction, expected test behavior, risks,
   and checks. For a behavior change, classify whether YAML syntax or a public
   conversion can express it and identify a locally installed reference
   implementation, version, schema, fixture, and canonical result. If no
   matching local implementation exists, record an explicit limitation.
   Prefer the latest stable matching release available locally; record the
   latest release known at intake and any freshness waiver. Plan a
   `Reference verification:` block with exact reference versions for the
   eventual commit body when the comparison is applicable.
   If the request is genuinely ambiguous or would cause destructive changes,
   ask the user. Otherwise choose the least surprising behavior and proceed.
7. For any public header, exported symbol or class, inline implementation,
   installed include path, visibility macro, package boundary, or
   `SOVERSION` change, invoke `/yaml-cpp-abi-analysis`. Record whether the
   change requires consumer recompilation, relinking, or an ABI transition;
   identify the last released baseline; and state the required SONAME and
   platform checks. Do not assume an unchanged SONAME proves compatibility.

The intake is complete only when another engineer could use the ledger to
understand why the proposed files and test are the right scope.
