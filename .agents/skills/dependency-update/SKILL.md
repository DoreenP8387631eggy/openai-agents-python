# Dependency Update Skill

This skill automates the process of reviewing and updating project dependencies, checking for security vulnerabilities, and ensuring compatibility.

## What This Skill Does

1. **Scans dependencies** — Identifies outdated packages in `pyproject.toml` and `requirements*.txt` files
2. **Checks for vulnerabilities** — Uses `pip-audit` or similar tools to flag known CVEs
3. **Tests compatibility** — Runs the test suite after updates to catch regressions
4. **Creates a PR** — Opens a pull request with a structured summary of changes

## When to Use

- Scheduled weekly/monthly dependency maintenance
- After a security advisory is published affecting a dependency
- Before a major release to ensure up-to-date dependencies

## Inputs

| Variable | Description | Required |
|---|---|---|
| `TARGET_BRANCH` | Branch to base updates on (default: `main`) | No |
| `UPDATE_SCOPE` | `patch`, `minor`, or `major` (default: `minor`) | No |
| `SKIP_PACKAGES` | Comma-separated list of packages to skip | No |
| `DRY_RUN` | If `true`, report only without making changes | No |

## Outputs

- Pull request with dependency updates grouped by type (security, feature, patch)
- Comment on the PR with a compatibility report
- Summary table of updated packages with old → new versions

## Example Usage

```yaml
- skill: dependency-update
  with:
    UPDATE_SCOPE: minor
    SKIP_PACKAGES: "numpy,torch"
    DRY_RUN: false
```

## Notes

- Major version bumps are flagged for human review even if `UPDATE_SCOPE` is `major`
- The skill respects version pins and constraints in `pyproject.toml`
- If tests fail after update, the PR is still opened but marked as draft with a failure annotation
