#!/usr/bin/env bash
# Release Automation Script
# Automates the release process for openai-agents-python:
#   - Validates version bump
#   - Updates changelog
#   - Creates git tag
#   - Builds and publishes package
#   - Creates GitHub release

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PYPROJECT="${REPO_ROOT}/pyproject.toml"
CHANGELOG="${REPO_ROOT}/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
require_env() {
  local var="$1"
  if [[ -z "${!var:-}" ]]; then
    log_error "Required environment variable '${var}' is not set."
    exit 1
  fi
}

get_current_version() {
  grep -E '^version\s*=' "${PYPROJECT}" | head -1 | sed 's/.*=\s*"\(.*\)"/\1/'
}

validate_semver() {
  local version="$1"
  if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\-(alpha|beta|rc)\.[0-9]+)?$ ]]; then
    log_error "Version '${version}' does not follow semver (e.g. 1.2.3 or 1.2.3-rc.1)."
    exit 1
  fi
}

check_clean_workdir() {
  if [[ -n "$(git -C "${REPO_ROOT}" status --porcelain)" ]]; then
    log_error "Working directory is not clean. Commit or stash changes before releasing."
    exit 1
  fi
}

check_branch() {
  local current_branch
  current_branch="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)"
  if [[ "${current_branch}" != "main" && "${current_branch}" != "master" ]]; then
    log_warn "Releasing from branch '${current_branch}' — expected 'main'."
    read -r -p "Continue anyway? [y/N] " confirm
    [[ "${confirm}" =~ ^[Yy]$ ]] || exit 1
  fi
}

bump_version_in_pyproject() {
  local new_version="$1"
  sed -i.bak -E "s/^version = \"[^\"]+\"/version = \"${new_version}\"/" "${PYPROJECT}"
  rm -f "${PYPROJECT}.bak"
  log_info "Updated pyproject.toml → version = \"${new_version}\""
}

build_package() {
  log_info "Building distribution packages..."
  cd "${REPO_ROOT}"
  python -m build --sdist --wheel --outdir dist/
  log_info "Build complete. Artifacts in dist/"
}

publish_package() {
  local dry_run="${1:-false}"
  require_env TWINE_USERNAME
  require_env TWINE_PASSWORD

  log_info "Publishing to PyPI (dry_run=${dry_run})..."
  if [[ "${dry_run}" == "true" ]]; then
    log_warn "DRY RUN — skipping actual upload."
    return 0
  fi
  python -m twine upload dist/* --non-interactive
  log_info "Package published to PyPI."
}

create_git_tag() {
  local version="$1"
  local tag="v${version}"
  log_info "Creating git tag '${tag}'..."
  git -C "${REPO_ROOT}" add pyproject.toml CHANGELOG.md
  git -C "${REPO_ROOT}" commit -m "chore: release ${tag}"
  git -C "${REPO_ROOT}" tag -a "${tag}" -m "Release ${tag}"
  log_info "Tag '${tag}' created."
}

push_release() {
  local version="$1"
  local dry_run="${2:-false}"
  if [[ "${dry_run}" == "true" ]]; then
    log_warn "DRY RUN — skipping git push."
    return 0
  fi
  log_info "Pushing commit and tag to origin..."
  git -C "${REPO_ROOT}" push origin HEAD "v${version}"
}

create_github_release() {
  local version="$1"
  local dry_run="${2:-false}"
  require_env GH_TOKEN

  if [[ "${dry_run}" == "true" ]]; then
    log_warn "DRY RUN — skipping GitHub release creation."
    return 0
  fi

  log_info "Creating GitHub release for v${version}..."
  gh release create "v${version}" \
    --repo "$(git -C "${REPO_ROOT}" remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')" \
    --title "v${version}" \
    --generate-notes \
    dist/*
  log_info "GitHub release created."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local new_version="${1:-}"
  local dry_run="${DRY_RUN:-false}"

  if [[ -z "${new_version}" ]]; then
    log_error "Usage: $0 <new-version> [--dry-run]"
    log_error "Example: $0 1.3.0"
    exit 1
  fi

  if [[ "${2:-}" == "--dry-run" ]]; then
    dry_run="true"
  fi

  log_info "=== Release Automation — openai-agents-python ==="
  log_info "Target version : ${new_version}"
  log_info "Dry run        : ${dry_run}"

  validate_semver "${new_version}"

  local current_version
  current_version="$(get_current_version)"
  log_info "Current version: ${current_version}"

  check_clean_workdir
  check_branch

  bump_version_in_pyproject "${new_version}"
  build_package
  create_git_tag "${new_version}"
  push_release "${new_version}" "${dry_run}"
  publish_package "${dry_run}"
  create_github_release "${new_version}" "${dry_run}"

  log_info "=== Release v${new_version} complete! ==="
}

main "$@"
