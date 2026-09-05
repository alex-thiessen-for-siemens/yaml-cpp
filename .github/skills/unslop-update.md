# Updating the private unslop subtree

The `unslop` skill in `.github/skills/unslop` is imported from
`https://github.com/cursor/plugins.git`, source path
`pstack/skills/unslop`, using a Git subtree split. It is private workflow
infrastructure, not part of an upstream yaml-cpp contribution.

The initial import used source commit
`93b00b89ef425a9c1bac0d0b317dfc49c930ac99` and split commit
`f6028cffe32ef0f9d1c856221c02d110ed2d96ae`. The subtree merge commit is
`804434a025e45ef6b67cd9052a186c9cbd2a7be7`.

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
