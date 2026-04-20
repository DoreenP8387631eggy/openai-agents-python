# Release Automation Skill

Automates the release process for the openai-agents-python package, including version bumping, changelog finalization, PyPI publishing, and GitHub release creation.

## What This Skill Does

1. **Version Management** — Reads the current version from `pyproject.toml`, determines the next version based on conventional commits or explicit input, and updates all version references.
2. **Changelog Finalization** — Moves entries from the `[Unreleased]` section into a versioned release block with today's date.
3. **Build & Publish** — Runs `python -m build` and uploads the distribution to PyPI using `twine`.
4. **GitHub Release** — Creates a GitHub release with the changelog excerpt as the release body and attaches the built distribution artifacts.
5. **Post-release Bump** — Optionally bumps the version to the next development pre-release (e.g., `0.2.1.dev0`) so `main` is always ahead of the last release.

## Inputs

| Variable | Required | Description |
|---|---|---|
| `RELEASE_VERSION` | No | Explicit version string (e.g., `0.2.0`). If omitted the skill infers the version from commits. |
| `RELEASE_TYPE` | No | One of `patch`, `minor`, `major`. Used when `RELEASE_VERSION` is not set. Defaults to `patch`. |
| `PYPI_TOKEN` | Yes | API token for uploading to PyPI. |
| `GITHUB_TOKEN` | Yes | Token with `contents: write` permission for creating GitHub releases. |
| `DRY_RUN` | No | Set to `true` to skip PyPI upload and GitHub release creation. Defaults to `false`. |

## Outputs

- Updated `pyproject.toml` with the new version.
- Updated `CHANGELOG.md` with the versioned release block.
- A GitHub Release tagged `v<version>`.
- Distribution artifacts uploaded to PyPI (unless `DRY_RUN=true`).

## Usage

```bash
export PYPI_TOKEN="pypi-..."
export GITHUB_TOKEN="ghp_..."
export RELEASE_TYPE="minor"
bash .agents/skills/release-automation/scripts/run.sh
```

## Notes

- The script must be run from the repository root.
- Requires Python 3.9+, `build`, `twine`, and the `gh` CLI to be installed.
- The skill will abort without making changes if the working tree is dirty (uncommitted changes).
- Tag format is always `v<semver>` (e.g., `v0.2.0`).
