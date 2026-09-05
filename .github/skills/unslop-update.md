# Updating the private unslop subtree

The `unslop` skill in `.github/skills/unslop` is imported from
`https://github.com/cursor/plugins.git`, source path
`pstack/skills/unslop`, using a Git subtree split. It is private workflow
infrastructure, not part of an upstream yaml-cpp contribution.

To update it, review the upstream change first, make sure the worktree is
clean, and run:

```sh
.github/skills/update-unslop-subtree.sh
```

The helper clones the source repository into a temporary directory, creates a
subtree split for the source path, and runs `git subtree pull --squash` into
`.github/skills/unslop`. Review the resulting subtree commit and record the
source commit in this file before committing the update. Do not hand-edit
files inside the subtree.
