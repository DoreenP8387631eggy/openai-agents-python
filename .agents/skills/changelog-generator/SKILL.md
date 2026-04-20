# Changelog Generator Skill

Automatically generates or updates the CHANGELOG.md file based on merged pull requests and commit history since the last release tag.

## What This Skill Does

1. Detects the latest release tag in the repository
2. Collects all merged PRs and commits since that tag
3. Categorizes changes into: Features, Bug Fixes, Breaking Changes, Documentation, and Chores
4. Generates a well-formatted changelog entry following Keep a Changelog conventions
5. Prepends the new entry to CHANGELOG.md (or creates the file if absent)
6. Opens a PR with the changelog update

## Trigger

This skill is typically triggered:
- Manually before cutting a new release
- Automatically when a release branch is created
- On demand via a workflow dispatch event

## Inputs

| Variable | Description | Required | Default |
|---|---|---|---|
| `GITHUB_TOKEN` | Token with repo read/write access | Yes | — |
| `NEXT_VERSION` | The version string for the new release (e.g. `1.2.0`) | No | Derived from latest tag + patch bump |
| `BASE_BRANCH` | Branch to target for the changelog PR | No | `main` |

## Outputs

- Updated or created `CHANGELOG.md` at the repo root
- A pull request titled `chore: update changelog for vX.Y.Z`

## Categorization Rules

PR labels are used to categorize entries:

| Label | Changelog Section |
|---|---|
| `breaking-change` | ⚠ Breaking Changes |
| `enhancement`, `feature` | Added |
| `bug`, `fix` | Fixed |
| `documentation`, `docs` | Documentation |
| `chore`, `dependencies`, `ci` | Chores |
| *(unlabeled)* | Changed |

## Example Output

```markdown
## [1.2.0] - 2024-11-15

### Added
- Support for streaming tool calls (#142)

### Fixed
- Correct token counting for vision models (#138)

### Documentation
- Add tracing guide to docs (#135)
```

## Notes

- Commits that are part of a merged PR are deduplicated; only the PR entry is used.
- Bot-authored PRs (e.g. Dependabot) are grouped under **Chores** regardless of label.
- The skill respects a `.changelogignore` file listing PR numbers (one per line) to exclude.
