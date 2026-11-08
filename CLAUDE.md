# Notes for Claude

## Pull requests
- Merge PRs with a **merge commit**, not squash or rebase. The branch's commits then stay in `main`'s
  history, so the next change on the same branch can be pushed without a force push.
