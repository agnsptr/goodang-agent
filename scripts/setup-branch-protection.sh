#!/usr/bin/env bash
# =============================================================================
# scripts/setup-branch-protection.sh
# Apply branch protection rules ke GitHub repo via REST API.
#
# Sesuai docs/17. GOODANG_CI_BRANCH_PROTECTION_SPEC.md & WI-ENT-DEV-002.
#
# Prasyarat:
#   - gh CLI ter-install dan ter-auth (gh auth login)
#   - Token dengan scope: repo (untuk private) / public_repo (untuk public)
#   - User adalah admin repo
#
# Usage:
#   bash scripts/setup-branch-protection.sh                    # pakai repo dari git remote
#   bash scripts/setup-branch-protection.sh owner/repo         # explicit repo
#   REPO=owner/repo BRANCH=main bash scripts/setup-branch-protection.sh
#
# Dry-run (preview tanpa apply):
#   DRY_RUN=1 bash scripts/setup-branch-protection.sh
#
# Solo maintainer (personal repo, tanpa tim Guardian):
#   SOLO=1 bash scripts/setup-branch-protection.sh owner/repo
#   → CI checks tetap wajib; code owner review OFF; approving count 0
#
# Catatan GitHub Free: branch protection pada private repo butuh GitHub Pro.
#   Alternatif: buat repo public, atau upgrade ke Pro.
# =============================================================================
set -euo pipefail

# --- Resolve repo ---
if [ -n "${1:-}" ]; then
  REPO="$1"
elif [ -n "${REPO:-}" ]; then
  REPO="$REPO"
else
  # Parse dari git remote origin
  REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
  if [ -z "$REMOTE_URL" ]; then
    echo "✗ Tidak bisa resolve repo. Pass sebagai argumen: bash $0 owner/repo"
    exit 1
  fi
  # SSH: git@github.com:owner/repo.git  → owner/repo
  # HTTPS: https://github.com/owner/repo.git → owner/repo
  REPO="$(echo "$REMOTE_URL" | sed -E 's#(git@github\.com:|https://github\.com/)(.*)\.git#\2#' | sed -E 's#(git@github\.com:|https://github\.com/)(.*)#\2#')"
fi

BRANCH="${BRANCH:-main}"
DRY_RUN="${DRY_RUN:-0}"
SOLO="${SOLO:-0}"

# Review policy: org (default) vs solo maintainer
if [ "$SOLO" = "1" ]; then
  REQUIRE_CODE_OWNER_REVIEWS="false"
  REQUIRED_APPROVING_REVIEW_COUNT=0
  REVIEW_MODE="solo (CI gate only, no code owner review)"
else
  REQUIRE_CODE_OWNER_REVIEWS="true"
  REQUIRED_APPROVING_REVIEW_COUNT=1
  REVIEW_MODE="org (Guardian code owner review required)"
fi

echo "===> Branch Protection Setup"
echo "   Repo   : $REPO"
echo "   Branch : $BRANCH"
echo "   Mode   : $REVIEW_MODE"
echo "   Dry run: $([ "$DRY_RUN" = "1" ] && echo "YES" || echo "NO")"
echo ""

# --- Cek gh CLI ---
if ! command -v gh >/dev/null 2>&1; then
  echo "✗ gh CLI tidak ter-install. Install: https://cli.github.com/"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "✗ gh CLI belum ter-auth. Jalankan: gh auth login"
  exit 1
fi

# --- Status check contexts (wajib pass sebelum merge) ---
# Sesuai .github/workflows/ci.yml jobs
REQUIRED_CONTEXTS=(
  "Contract Drift Check"
  "Tool Registry Sync"
  "YAML Lint"
  "Python Lint (ruff)"
  "Python Type Check (mypy)"
  "Security Scan (bandit + secrets)"
  "Tests (pytest)"
  "Docker Compose Validate"
  "CI Summary (Required)"
)

# --- Build JSON payload ---
# Ref: https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection
json_payload=$(cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": $(printf '%s\n' "${REQUIRED_CONTEXTS[@]}" | jq -R . | jq -s .)
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": ${REQUIRE_CODE_OWNER_REVIEWS},
    "required_approving_review_count": ${REQUIRED_APPROVING_REVIEW_COUNT},
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF
)

if [ "$DRY_RUN" = "1" ]; then
  echo "===> DRY RUN — payload yang akan dikirim:"
  echo "$json_payload" | jq .
  echo ""
  echo "Endpoint: PUT /repos/$REPO/branches/$BRANCH/protection"
  exit 0
fi

# --- Apply via gh api ---
echo "===> Apply branch protection..."
gh api \
  --method PUT \
  "/repos/$REPO/branches/$BRANCH/protection" \
  --input - <<< "$json_payload" \
  --silent

echo "✓ Branch protection applied ke $REPO@$BRANCH"
echo ""

# --- Verifikasi ---
echo "===> Verifikasi..."
gh api "/repos/$REPO/branches/$BRANCH/protection" --silent | jq '{
  "required_status_checks.contexts": .required_status_checks.contexts,
  "enforce_admins.enabled": .enforce_admins.enabled,
  "required_pull_request_reviews.required_approving_review_count": .required_pull_request_reviews.required_approving_review_count,
  "required_pull_request_reviews.require_code_owner_reviews": .required_pull_request_reviews.require_code_owner_reviews,
  "required_linear_history": .required_linear_history,
  "allow_force_pushes": .allow_force_pushes,
  "allow_deletions": .allow_deletions
}'

echo ""
echo "===> Done. Ringkasan aturan:"
echo "   - Required status checks: ${#REQUIRED_CONTEXTS[@]} contexts (CI hard gate)"
echo "   - Strict (require branch up-to-date): YES"
if [ "$SOLO" = "1" ]; then
  echo "   - Code owner review required: NO (SOLO mode)"
  echo "   - Min approving reviews: 0"
else
  echo "   - Code owner review required: YES"
  echo "   - Min approving reviews: 1"
fi
echo "   - Linear history: YES (no merge commits)"
echo "   - Force push: DISABLED"
echo "   - Branch delete: DISABLED"
echo "   - Enforce for admins: YES"
echo "   - Conversation resolution required: YES"
echo ""
echo "Catatan:"
echo "   - CodeRabbit (AI review) berjalan via GitHub App, otomatis review tiap PR"
if [ "$SOLO" = "1" ]; then
  echo "   - SOLO mode: merge setelah CI lulus (tanpa Guardian approval)"
else
  echo "   - Guardian tetap wajib approve (code owner review)"
  echo "   - Self-merge DILARANG (require_code_owner_reviews + approving_review_count=1)"
fi
