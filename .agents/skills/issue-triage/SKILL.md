# Issue Triage Skill

Automatically triages new GitHub issues by analyzing content, applying labels, assigning priority, and suggesting relevant team members or areas of ownership.

## What this skill does

1. Reads newly opened or updated GitHub issues
2. Classifies the issue type (bug, feature request, question, documentation, etc.)
3. Applies appropriate labels based on content analysis
4. Assigns a priority level (P0–P3) based on severity signals
5. Identifies affected components or modules
6. Posts a structured triage comment summarizing findings
7. Optionally requests more information if the issue is unclear

## Trigger conditions

- A new issue is opened in the repository
- An existing issue is edited and has not yet been triaged
- Manually invoked via workflow dispatch

## Inputs

| Input | Description |
|-------|-------------|
| `issue_number` | The GitHub issue number to triage |
| `repo` | Repository in `owner/repo` format |
| `github_token` | GitHub token with issues read/write permission |

## Outputs

- Labels applied to the issue
- Priority tag added
- Triage comment posted on the issue

## Label taxonomy

### Type labels
- `type:bug` — Something is broken or behaving unexpectedly
- `type:feature` — Request for new functionality
- `type:question` — Usage question or clarification needed
- `type:docs` — Documentation gap or error
- `type:chore` — Maintenance, dependency updates, refactoring

### Priority labels
- `priority:P0` — Critical, production broken
- `priority:P1` — High, significant impact
- `priority:P2` — Medium, normal queue
- `priority:P3` — Low, nice to have

### Component labels
- `component:agents` — Core agent runtime
- `component:tools` — Tool/function calling
- `component:tracing` — Tracing and observability
- `component:models` — Model providers and interfaces
- `component:examples` — Example scripts
- `component:docs` — Documentation site

## Configuration

Place a `.agents/skills/issue-triage/config.yaml` file to customize label mappings or priority heuristics.

## Usage

This skill is invoked automatically via the GitHub Actions workflow defined in `.github/workflows/issue-triage.yml`.
