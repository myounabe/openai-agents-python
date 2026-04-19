# Dependency Update Skill

Automatically checks for outdated dependencies and creates pull requests to update them.

## Overview

This skill scans the project's dependency files (pyproject.toml, requirements.txt, etc.) for outdated packages, evaluates the impact of updates, and creates pull requests with the necessary changes.

## Trigger

This skill can be triggered:
- On a schedule (e.g., weekly)
- Manually via workflow dispatch
- When a security advisory is published for a dependency

## Process

1. **Scan Dependencies** — Parse all dependency files and identify current versions
2. **Check for Updates** — Query PyPI for latest versions of each dependency
3. **Evaluate Impact** — Categorize updates as patch, minor, or major
4. **Run Tests** — Execute the test suite against updated dependencies
5. **Create PR** — Open a pull request with changelog notes and test results

## Outputs

- Pull request with dependency updates grouped by type (security, major, minor, patch)
- Summary comment listing all changes and their changelogs
- Test run results attached to the PR

## Configuration

```yaml
# .agents/skills/dependency-update/config.yaml
schedule: weekly
group_updates: true
auto_merge:
  patch: true
  minor: false
  major: false
ignore:
  - package: some-package
    versions: [">=2.0.0"]
```

## Requirements

- Python 3.9+
- `pip-audit` for security scanning
- `pip index` or `pip install --dry-run` for version resolution
- GitHub CLI (`gh`) for PR creation

## Notes

- Major version updates are flagged for manual review
- Security updates are prioritized and can trigger immediate PRs
- Updates are tested in isolation before being combined into a single PR
