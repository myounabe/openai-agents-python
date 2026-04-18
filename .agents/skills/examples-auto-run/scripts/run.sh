#!/bin/bash
# examples-auto-run skill: Automatically discovers and runs example scripts,
# capturing output and reporting success/failure for each.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
RESULTS_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/results"
TIMEOUT=${EXAMPLES_TIMEOUT:-60}
PASS=0
FAIL=0
SKIP=0
FAILED_EXAMPLES=()

mkdir -p "${RESULTS_DIR}"

log() {
  echo "[examples-auto-run] $*"
}

check_dependencies() {
  if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required but not found." >&2
    exit 1
  fi
}

is_skippable() {
  local file="$1"
  # Skip examples that require interactive input or external credentials not set
  if grep -qE 'input\(|getpass\.' "${file}" 2>/dev/null; then
    return 0
  fi
  # Skip if file contains a skip marker
  if grep -q '# examples-auto-run: skip' "${file}" 2>/dev/null; then
    return 0
  fi
  return 1
}

run_example() {
  local example_file="$1"
  local rel_path="${example_file#${REPO_ROOT}/}"
  local result_file="${RESULTS_DIR}/$(echo "${rel_path}" | tr '/' '_').txt"

  if is_skippable "${example_file}"; then
    log "SKIP  ${rel_path}"
    ((SKIP++)) || true
    return
  fi

  log "RUN   ${rel_path}"
  local start_time
  start_time=$(date +%s)

  set +e
  timeout "${TIMEOUT}" python3 "${example_file}" > "${result_file}" 2>&1
  local exit_code=$?
  set -e

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  if [[ ${exit_code} -eq 0 ]]; then
    log "PASS  ${rel_path} (${duration}s)"
    ((PASS++)) || true
  elif [[ ${exit_code} -eq 124 ]]; then
    log "FAIL  ${rel_path} — timed out after ${TIMEOUT}s"
    echo "TIMEOUT after ${TIMEOUT}s" >> "${result_file}"
    ((FAIL++)) || true
    FAILED_EXAMPLES+=("${rel_path} (timeout)")
  else
    log "FAIL  ${rel_path} — exit code ${exit_code}"
    ((FAIL++)) || true
    FAILED_EXAMPLES+=("${rel_path} (exit ${exit_code})")
  fi
}

print_summary() {
  echo ""
  echo "======================================="
  echo " Examples Auto-Run Summary"
  echo "======================================="
  echo "  PASSED : ${PASS}"
  echo "  FAILED : ${FAIL}"
  echo "  SKIPPED: ${SKIP}"
  echo "  TOTAL  : $((PASS + FAIL + SKIP))"
  if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
    echo ""
    echo "  Failed examples:"
    for ex in "${FAILED_EXAMPLES[@]}"; do
      echo "    - ${ex}"
    done
  fi
  echo "======================================="
  echo "  Results saved to: ${RESULTS_DIR}"
  echo "======================================="
}

main() {
  check_dependencies

  if [[ ! -d "${EXAMPLES_DIR}" ]]; then
    log "No examples directory found at ${EXAMPLES_DIR}. Nothing to run."
    exit 0
  fi

  log "Discovering examples in ${EXAMPLES_DIR}..."

  # Find all Python files in examples dir, sorted for deterministic order
  while IFS= read -r -d '' example_file; do
    run_example "${example_file}"
  done < <(find "${EXAMPLES_DIR}" -name '*.py' -not -path '*/__pycache__/*' -print0 | sort -z)

  print_summary

  if [[ ${FAIL} -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
