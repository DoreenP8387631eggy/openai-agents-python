#!/usr/bin/env bash
# Dependency Update Skill
# Checks for outdated dependencies and creates a PR with updates

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BRANCH_PREFIX="deps/auto-update"
DATE_STAMP="$(date +%Y%m%d)"
UPDATE_BRANCH="${BRANCH_PREFIX}-${DATE_STAMP}"
COMMIT_MSG="chore: auto-update dependencies (${DATE_STAMP})"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[dep-update]${NC} $*"; }
warn() { echo -e "${YELLOW}[dep-update]${NC} $*"; }
err()  { echo -e "${RED}[dep-update]${NC} $*" >&2; }

# ─── Prerequisite checks ──────────────────────────────────────────────────────
check_prerequisites() {
  local missing=()
  for cmd in git python3 pip gh; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    err "Missing required tools: ${missing[*]}"
    exit 1
  fi

  log "All prerequisites satisfied."
}

# ─── Detect package manager ───────────────────────────────────────────────────
detect_package_manager() {
  if [[ -f "${REPO_ROOT}/pyproject.toml" ]]; then
    if grep -q '\[tool\.poetry\]' "${REPO_ROOT}/pyproject.toml" 2>/dev/null; then
      echo "poetry"
    else
      echo "pip"
    fi
  elif [[ -f "${REPO_ROOT}/requirements.txt" ]]; then
    echo "pip"
  else
    echo "unknown"
  fi
}

# ─── Collect outdated packages ────────────────────────────────────────────────
collect_outdated_pip() {
  log "Checking for outdated pip packages..."
  pip list --outdated --format=columns 2>/dev/null | tail -n +3 || true
}

collect_outdated_poetry() {
  log "Checking for outdated poetry packages..."
  cd "${REPO_ROOT}"
  poetry show --outdated 2>/dev/null || true
}

# ─── Apply updates ────────────────────────────────────────────────────────────
apply_updates_pip() {
  log "Upgrading all pip packages..."
  cd "${REPO_ROOT}"
  pip list --outdated --format=freeze 2>/dev/null \
    | grep -v '^\-e' \
    | cut -d= -f1 \
    | xargs -r pip install --upgrade

  # Regenerate requirements files if they exist
  if [[ -f requirements.txt ]]; then
    pip freeze > requirements.txt
    log "requirements.txt updated."
  fi
  if [[ -f requirements-dev.txt ]]; then
    pip freeze > requirements-dev.txt
    log "requirements-dev.txt updated."
  fi
}

apply_updates_poetry() {
  log "Upgrading poetry dependencies..."
  cd "${REPO_ROOT}"
  poetry update
}

# ─── Git helpers ──────────────────────────────────────────────────────────────
create_branch() {
  cd "${REPO_ROOT}"
  git fetch origin
  git checkout -b "${UPDATE_BRANCH}" origin/main
  log "Created branch: ${UPDATE_BRANCH}"
}

has_changes() {
  cd "${REPO_ROOT}"
  ! git diff --quiet
}

commit_and_push() {
  cd "${REPO_ROOT}"
  git add -A
  git commit -m "${COMMIT_MSG}"
  git push origin "${UPDATE_BRANCH}"
  log "Pushed branch ${UPDATE_BRANCH}."
}

# ─── Pull-request creation ────────────────────────────────────────────────────
create_pr() {
  local pkg_manager="$1"
  local outdated_summary="$2"

  local pr_body
  pr_body=$(cat <<EOF
## Automated Dependency Update

**Date:** ${DATE_STAMP}  
**Package manager:** ${pkg_manager}

### Packages updated

\`\`\`
${outdated_summary}
\`\`\`

> This PR was created automatically by the dependency-update skill.
EOF
)

  gh pr create \
    --title "chore: dependency update ${DATE_STAMP}" \
    --body "${pr_body}" \
    --base main \
    --head "${UPDATE_BRANCH}" \
    --label "dependencies,automated" || warn "Could not create PR (gh may not be authenticated)."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  log "Starting dependency update skill..."
  check_prerequisites

  local pkg_manager
  pkg_manager="$(detect_package_manager)"
  log "Detected package manager: ${pkg_manager}"

  if [[ "$pkg_manager" == "unknown" ]]; then
    err "Could not detect a supported package manager. Exiting."
    exit 1
  fi

  # Capture outdated list before updating
  local outdated_summary
  if [[ "$pkg_manager" == "poetry" ]]; then
    outdated_summary="$(collect_outdated_poetry)"
  else
    outdated_summary="$(collect_outdated_pip)"
  fi

  if [[ -z "$outdated_summary" ]]; then
    log "All dependencies are up to date. Nothing to do."
    exit 0
  fi

  log "Outdated packages found:\n${outdated_summary}"

  create_branch

  if [[ "$pkg_manager" == "poetry" ]]; then
    apply_updates_poetry
  else
    apply_updates_pip
  fi

  if has_changes; then
    commit_and_push
    create_pr "${pkg_manager}" "${outdated_summary}"
    log "Dependency update PR created successfully."
  else
    warn "No file changes after update — skipping PR creation."
  fi
}

main "$@"
