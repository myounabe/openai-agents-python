# Changelog Generator Skill

Automatically generates and maintains a CHANGELOG.md file based on merged pull requests, commit history, and semantic versioning conventions.

## Overview

This skill analyzes the Git history and GitHub PR metadata to produce a well-structured changelog following the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format. It groups changes by type (Added, Changed, Deprecated, Removed, Fixed, Security) and organizes them by release version.

## Trigger Conditions

This skill should be invoked when:
- A new release tag is pushed to the repository
- A pull request is merged into the `main` branch with a `changelog` label
- Manually triggered via workflow dispatch
- A milestone is closed on GitHub

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `from_ref` | Starting Git ref (tag, branch, or commit SHA) | No (defaults to last tag) |
| `to_ref` | Ending Git ref | No (defaults to `HEAD`) |
| `version` | The version string for the new entry | No (auto-detected from tags) |
| `output_file` | Path to the changelog file | No (defaults to `CHANGELOG.md`) |

## Outputs

- Updated `CHANGELOG.md` with a new version section prepended
- A summary of changes grouped by category
- A list of contributors for the release

## Behavior

### Change Classification

PR titles and commit messages are classified using conventional commit prefixes:

- `feat:` / `feature:` → **Added**
- `fix:` / `bugfix:` → **Fixed**
- `perf:` → **Changed** (performance improvement)
- `refactor:` → **Changed**
- `deprecate:` → **Deprecated**
- `remove:` / `revert:` → **Removed**
- `security:` → **Security**
- `docs:` / `chore:` / `ci:` → omitted by default (configurable)

### Version Detection

If no version is provided, the skill reads `pyproject.toml` or `package.json` to determine the current version. If a tag matching the version already exists, it bumps the patch version.

### Deduplication

Entries are deduplicated by PR number. If the same fix appears in both a commit and a PR, the PR title takes precedence.

## Configuration

Optional `.agents/skills/changelog-generator/config.yaml`:

```yaml
include_types:
  - feat
  - fix
  - perf
  - refactor
  - security
  - deprecate
  - remove
exclude_labels:
  - skip-changelog
  - internal
contributors: true
links: true
```

## Example Output

```markdown
## [1.2.0] - 2024-06-15

### Added
- Support for streaming tool call responses (#142)
- New `on_handoff` lifecycle hook for agent transitions (#138)

### Fixed
- Race condition in parallel tool execution (#145)
- Incorrect token counting for vision inputs (#139)

### Changed
- Improved retry logic with exponential backoff (#141)

### Contributors
@alice, @bob, @carol
```

## Notes

- The skill respects the `skip-changelog` PR label to omit entries
- Bot commits (dependabot, github-actions) are excluded automatically
- Requires `GITHUB_TOKEN` with `contents: write` and `pull-requests: read` permissions
