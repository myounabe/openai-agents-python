# PR Auto Review Skill

This skill automatically reviews pull requests by analyzing code changes, checking for common issues, and providing structured feedback.

## What It Does

- Analyzes diff of changed files in a pull request
- Checks for code quality issues (unused imports, long functions, missing docstrings)
- Validates that tests exist for new functionality
- Ensures changelog or release notes are updated when appropriate
- Posts a structured review summary as a PR comment

## When to Use

Trigger this skill when:
- A new pull request is opened or updated
- You want a quick automated sanity check before human review
- Reviewing dependency updates or refactors

## Inputs

| Variable | Description | Required |
|---|---|---|
| `PR_NUMBER` | The pull request number to review | Yes |
| `REPO` | Repository in `owner/name` format | Yes |
| `GITHUB_TOKEN` | Token with repo read and PR comment write access | Yes |
| `BASE_BRANCH` | Base branch to diff against (default: `main`) | No |
| `STRICT_MODE` | Fail on warnings as well as errors (`true`/`false`, default: `false`) | No |

## Outputs

- A markdown review comment posted to the PR
- Exit code `0` if no blocking issues found, `1` otherwise

## How to Run

```bash
export PR_NUMBER=42
export REPO=my-org/my-repo
export GITHUB_TOKEN=ghp_...
bash .agents/skills/pr-auto-review/scripts/run.sh
```

## Review Checks Performed

1. **File size** — Warns if any single file exceeds 500 lines changed
2. **Test coverage signal** — Checks that at least one test file is modified when source files change
3. **Secrets scan** — Looks for patterns resembling API keys or tokens in the diff
4. **TODO/FIXME count** — Reports newly introduced TODO or FIXME comments
5. **Docs update** — Reminds reviewers if `docs/` is not touched on feature branches

## Notes

- This skill uses the GitHub REST API and requires no additional dependencies beyond `curl` and `jq`.
- It does not push commits or modify files; it only reads and comments.
