# PR Review Skill

This skill automates pull request review by analyzing code changes, checking for common issues, and providing structured feedback.

## What it does

- Analyzes diffs for potential bugs, security issues, and style violations
- Checks that tests are included for new functionality
- Verifies documentation is updated alongside code changes
- Summarizes the PR with a structured review comment

## Inputs

| Name | Description | Required |
|------|-------------|----------|
| `pr_number` | The pull request number to review | Yes |
| `repo` | Repository in `owner/name` format | Yes |
| `review_level` | One of `light`, `standard`, `thorough` | No (default: `standard`) |

## Outputs

| Name | Description |
|------|-------------|
| `review_body` | Full review comment body in Markdown |
| `verdict` | One of `approve`, `request-changes`, `comment` |
| `issues_found` | Count of issues identified |

## How to use

```yaml
- skill: pr-review
  inputs:
    pr_number: ${{ github.event.pull_request.number }}
    repo: ${{ github.repository }}
    review_level: standard
```

## Review checklist

The skill evaluates the following:

1. **Correctness** — Are there obvious logic errors or off-by-one mistakes?
2. **Security** — Are inputs validated? Are secrets handled safely?
3. **Tests** — Does new code have corresponding tests?
4. **Docs** — Are docstrings and README sections updated?
5. **Style** — Does the code follow project conventions?
6. **Complexity** — Are functions kept small and focused?

## Notes

- Requires a GitHub token with `pull-requests: write` permission.
- Large PRs (>500 changed lines) will automatically use `thorough` review level.
- The skill respects `.agentignore` files to skip generated or vendored files.
