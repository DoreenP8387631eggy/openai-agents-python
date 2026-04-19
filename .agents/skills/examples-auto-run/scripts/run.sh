#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
RESULTS_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/results"
TIMEOUT=${EXAMPLES_TIMEOUT:-60}
PYTHON=${PYTHON_BIN:-python}

mkdir -p "${RESULTS_DIR}"

passed=0
failed=0
skipped=0
failed_list=()

log() {
  echo "[examples-auto-run] $*"
}

run_example() {
  local example_file="$1"
  local relative_path="${example_file#${REPO_ROOT}/}"
  local result_file="${RESULTS_DIR}/$(echo "${relative_path}" | tr '/' '_').log"

  log "Running: ${relative_path}"

  # Skip examples that require interactive input or special env vars marked with SKIP_AUTO_RUN
  if grep -q 'SKIP_AUTO_RUN' "${example_file}" 2>/dev/null; then
    log "  SKIPPED (marked SKIP_AUTO_RUN)"
    ((skipped++)) || true
    return
  fi

  # Check required env vars declared in the file via: # REQUIRES_ENV: VAR1 VAR2
  local missing_vars=0
  while IFS= read -r line; do
    for var in $line; do
      if [[ -z "${!var:-}" ]]; then
        log "  SKIPPED (missing env var: ${var})"
        missing_vars=1
        break 2
      fi
    done
  done < <(grep -oP '(?<=# REQUIRES_ENV: ).*' "${example_file}" 2>/dev/null || true)

  if [[ "${missing_vars}" -eq 1 ]]; then
    ((skipped++)) || true
    return
  fi

  set +e
  timeout "${TIMEOUT}" "${PYTHON}" "${example_file}" \
    > "${result_file}" 2>&1
  local exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "  PASSED"
    ((passed++)) || true
  elif [[ ${exit_code} -eq 124 ]]; then
    log "  FAILED (timeout after ${TIMEOUT}s)"
    ((failed++)) || true
    failed_list+=("${relative_path} [timeout]") 
  else
    log "  FAILED (exit code ${exit_code})"
    ((failed++)) || true
    failed_list+=("${relative_path} [exit ${exit_code}]")
  fi
}

# Discover examples
if [[ ! -d "${EXAMPLES_DIR}" ]]; then
  log "ERROR: examples directory not found at ${EXAMPLES_DIR}"
  exit 1
fi

log "Discovering examples in ${EXAMPLES_DIR}..."
mapfile -t example_files < <(find "${EXAMPLES_DIR}" -name '*.py' | sort)

if [[ ${#example_files[@]} -eq 0 ]]; then
  log "No example files found."
  exit 0
fi

log "Found ${#example_files[@]} example(s). Starting run..."
echo ""

for f in "${example_files[@]}"; do
  run_example "$f"
done

echo ""
log "======================================"
log "Results: ${passed} passed, ${failed} failed, ${skipped} skipped"
log "======================================"

if [[ ${#failed_list[@]} -gt 0 ]]; then
  log "Failed examples:"
  for item in "${failed_list[@]}"; do
    log "  - ${item}"
  done
fi

# Write summary JSON
summary_file="${RESULTS_DIR}/summary.json"
cat > "${summary_file}" <<EOF
{
  "passed": ${passed},
  "failed": ${failed},
  "skipped": ${skipped},
  "total": $((passed + failed + skipped))
}
EOF
log "Summary written to ${summary_file}"

if [[ ${failed} -gt 0 ]]; then
  exit 1
fi
