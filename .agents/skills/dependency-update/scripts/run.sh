#!/usr/bin/env bash
# Dependency Update Skill - run.sh
# Automatically checks for outdated dependencies and creates a PR with updates.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel)"
BRANCH_PREFIX="chore/dependency-update"
DATE_SUFFIX="$(date +%Y%m%d)"
UPDATE_BRANCH="${BRANCH_PREFIX}-${DATE_SUFFIX}"
COMMIT_MSG="chore: update dependencies (${DATE_SUFFIX})"
PR_TITLE="chore: Automated dependency update ${DATE_SUFFIX}"

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------
check_prerequisites() {
    local missing=0
    for cmd in git python3 pip gh; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        exit 1
    fi
    log_info "All prerequisites satisfied."
}

# ---------------------------------------------------------------------------
# Detect package manager files present in the repo
# ---------------------------------------------------------------------------
detect_package_files() {
    PACKAGE_FILES=()
    [[ -f "${REPO_ROOT}/pyproject.toml" ]]     && PACKAGE_FILES+=("pyproject.toml")
    [[ -f "${REPO_ROOT}/requirements.txt" ]]   && PACKAGE_FILES+=("requirements.txt")
    [[ -f "${REPO_ROOT}/requirements-dev.txt" ]] && PACKAGE_FILES+=("requirements-dev.txt")
    if [[ ${#PACKAGE_FILES[@]} -eq 0 ]]; then
        log_warn "No recognised package files found. Nothing to update."
        exit 0
    fi
    log_info "Detected package files: ${PACKAGE_FILES[*]}"
}

# ---------------------------------------------------------------------------
# Collect outdated packages using pip
# ---------------------------------------------------------------------------
collect_outdated() {
    log_info "Checking for outdated packages..."
    OUTDATED_JSON="$(python3 -m pip list --outdated --format=json 2>/dev/null || echo '[]')"
    OUTDATED_COUNT="$(echo "$OUTDATED_JSON" | python3 -c \
        "import sys, json; data=json.load(sys.stdin); print(len(data))")"

    if [[ "$OUTDATED_COUNT" -eq 0 ]]; then
        log_info "All dependencies are up to date. No PR needed."
        exit 0
    fi
    log_info "Found ${OUTDATED_COUNT} outdated package(s)."
}

# ---------------------------------------------------------------------------
# Create a new branch for the updates
# ---------------------------------------------------------------------------
create_branch() {
    cd "$REPO_ROOT"
    git fetch origin --prune
    # If the branch already exists remotely, skip to avoid duplicate PRs
    if git ls-remote --exit-code origin "refs/heads/${UPDATE_BRANCH}" &>/dev/null; then
        log_warn "Branch '${UPDATE_BRANCH}' already exists on remote. Skipping."
        exit 0
    fi
    git checkout -b "$UPDATE_BRANCH" origin/main
    log_info "Created branch: ${UPDATE_BRANCH}"
}

# ---------------------------------------------------------------------------
# Apply updates
# ---------------------------------------------------------------------------
apply_updates() {
    log_info "Upgrading outdated packages..."
    # Upgrade all outdated packages
    python3 -m pip list --outdated --format=freeze \
        | grep -v '^\-e' \
        | cut -d= -f1 \
        | xargs -r python3 -m pip install --upgrade

    # Regenerate requirements files if they exist
    for req_file in "requirements.txt" "requirements-dev.txt"; do
        if [[ -f "${REPO_ROOT}/${req_file}" ]]; then
            log_info "Regenerating ${req_file}..."
            python3 -m pip freeze > "${REPO_ROOT}/${req_file}"
        fi
    done

    # If using pyproject.toml with uv or pip-compile, attempt sync
    if [[ -f "${REPO_ROOT}/pyproject.toml" ]] && command -v uv &>/dev/null; then
        log_info "Running 'uv sync' to update lock file..."
        uv sync --upgrade || log_warn "'uv sync' failed — continuing without lock update."
    fi
}

# ---------------------------------------------------------------------------
# Commit changes
# ---------------------------------------------------------------------------
commit_changes() {
    cd "$REPO_ROOT"
    if git diff --quiet && git diff --cached --quiet; then
        log_info "No file changes detected after upgrade. Exiting."
        exit 0
    fi
    git add -A
    git commit -m "$COMMIT_MSG"
    git push origin "$UPDATE_BRANCH"
    log_info "Changes committed and pushed to '${UPDATE_BRANCH}'."
}

# ---------------------------------------------------------------------------
# Build PR body from outdated package list
# ---------------------------------------------------------------------------
build_pr_body() {
    PR_BODY="## Automated Dependency Update\n\n"
    PR_BODY+="This PR was generated automatically by the **dependency-update** skill.\n\n"
    PR_BODY+="### Packages Updated\n\n"
    PR_BODY+="| Package | Current | Latest |\n|---------|---------|--------|\n"

    while IFS= read -r line; do
        pkg="$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['name'])")"
        cur="$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['version'])")"
        lat="$(echo "$line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['latest_version'])")"
        PR_BODY+="| ${pkg} | ${cur} | ${lat} |\n"
    done < <(echo "$OUTDATED_JSON" | python3 -c \
        "import sys,json; [print(json.dumps(p)) for p in json.load(sys.stdin)]")

    PR_BODY+="\n---\n_Triggered on: ${DATE_SUFFIX}_"
}

# ---------------------------------------------------------------------------
# Open a pull request via GitHub CLI
# ---------------------------------------------------------------------------
open_pull_request() {
    log_info "Opening pull request..."
    gh pr create \
        --title "$PR_TITLE" \
        --body "$(printf '%b' "$PR_BODY")" \
        --base main \
        --head "$UPDATE_BRANCH" \
        --label "dependencies,automated" || log_warn "PR creation failed — it may already exist."
    log_info "Pull request created successfully."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    log_info "=== Dependency Update Skill starting ==="
    check_prerequisites
    detect_package_files
    collect_outdated
    create_branch
    apply_updates
    commit_changes
    build_pr_body
    open_pull_request
    log_info "=== Dependency Update Skill complete ==="
}

main "$@"
