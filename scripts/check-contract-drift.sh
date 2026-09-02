#!/usr/bin/env bash
# scripts/check-contract-drift.sh
# Verifikasi integritas kontrak Goodang sesuai docs/0. GOODANG_CONTRACT.md
# Exit non-zero jika drift terdeteksi.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STATUS=0
ERRORS=()

log_error() {
  ERRORS+=("$1")
  STATUS=1
}

echo "===> 1. Cek duplikat file antara docs/ dan app/* knowledge/ evaluation/"
DUPLICATES=(
  "1. GOODANG_ADK_AGENT_SPECIFICATION.md|knowledge"
  "2. GOODANG_AGENT_CONTRACT.md|app/agents"
  "3. GOODANG_TOOL_CONTRACT.md|app/tools"
  "3.1. GOODANG_TOOL_IMPLEMENTATION_SPEC.md|app/tools"
  "4. GOODANG_DATA_CONTRACT.md|app/schemas"
  "5. GOODANG_TEMPORAL_WORKFLOW_SPEC.md|app/temporal"
  "5.1. GOODANG_TEMPORAL_IMPLEMENTATION_SPEC.md|app/temporal"
  "6. GOODANG_STATE_MACHINE.md|app/agents"
  "7. GOODANG_RESPONSE_SPEC.md|app/agents"
  "8. GOODANG_AGENT_EVALUATION.md|evaluation"
  "9. GOODANG_ADK_IMPLEMENTATION_SPEC.md|knowledge"
  "10. GOODANG_SYSTEM_INVENTORY.md|knowledge"
  "11. GOODANG_TELEGRAM_INTEGRATION_SPEC.md|app/telegram"
  "GOODANG_ADK_PROMPT_SPEC.md|app/agents"
)

for entry in "${DUPLICATES[@]}"; do
  filename="${entry%%|*}"
  dest="${entry##*|}"
  src="docs/$filename"
  dst="$dest/$filename"
  if [ ! -f "$src" ]; then
    log_error "MISSING source: $src"
    continue
  fi
  if [ ! -f "$dst" ]; then
    log_error "MISSING duplicate: $dst (expected to mirror $src)"
    continue
  fi
  if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    log_error "DRIFT: $src vs $dst (must be byte-identical)"
  fi
done

echo "===> 2. Cek ghost state tidak muncul di docs/ app/ knowledge/ evaluation/"
GHOST_STATES=("WAITING_CUSTOMER" "CUSTOMER_CONFIRMATION")
for ghost in "${GHOST_STATES[@]}"; do
  # Izinkan kemunculan di docs/0 (daftar DILARANG), docs/audit (laporan),
  # docs/rules (knowledge base CodeRabbit), docs/17 (CI spec yang menyebut contoh).
  matches=$(grep -rnE "\b${ghost}\b" docs/ app/ knowledge/ evaluation/ 2>/dev/null \
    | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
    | grep -vE "docs/audit/" \
    | grep -vE "docs/rules/" \
    | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
    || true)
  if [ -n "$matches" ]; then
    log_error "GHOST_STATE detected '$ghost':\n$matches"
  fi
done

# VALIDATION sebagai state (bukan sebagai kata umum).
# Hanya flag jika VALIDATION muncul sebagai state name standalone atau di transition line (dengan arrow).
matches=$(grep -rnE "(^\s*VALIDATION\s*$|VALIDATION\s*[→↓]|[→↓]\s*VALIDATION\b)" docs/ app/ knowledge/ evaluation/ 2>/dev/null \
  | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
  | grep -vE "docs/audit/" \
  | grep -vE "docs/rules/" \
  | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
  | grep -vE "VALIDATION_ERROR" \
  || true)
if [ -n "$matches" ]; then
  log_error "GHOST_STATE detected 'VALIDATION' (use VALIDATING_ORDER):\n$matches"
fi

echo "===> 3. Cek nama tool kontradiktif tidak muncul"
FORBIDDEN_TOOLS=("lookup_customer" "create_draft" "get_draft" "update_draft" "update_draft_order" "add_item" "remove_item" "cancel_draft")
for tool in "${FORBIDDEN_TOOLS[@]}"; do
  # Izinkan sebagai nama activity dengan suffix _activity, dan di docs/0 (daftar DILARANG),
  # docs/audit (laporan), docs/rules (knowledge base), docs/17 (CI spec).
  matches=$(grep -rnE "\b${tool}\b" docs/ app/ knowledge/ evaluation/ 2>/dev/null \
    | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
    | grep -vE "docs/audit/" \
    | grep -vE "docs/rules/" \
    | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
    | grep -vE "${tool}_activity" \
    || true)
  if [ -n "$matches" ]; then
    log_error "FORBIDDEN_TOOL_NAME '$tool' (see docs/0 §3.5):\n$matches"
  fi
done

echo "===> 4. Cek error code kontradiktif tidak muncul"
# RESOLVED sebagai result code (bukan sebagai audit event PRODUCT_RESOLVED)
matches=$(grep -rnE "\bRESOLVED\b" docs/ app/ knowledge/ evaluation/ 2>/dev/null \
  | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
  | grep -vE "docs/audit/" \
  | grep -vE "docs/rules/" \
  | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
  | grep -vE "PRODUCT_RESOLVED" \
  || true)
if [ -n "$matches" ]; then
  log_error "FORBIDDEN_CODE 'RESOLVED' (use PRODUCT_FOUND for tool result, PRODUCT_RESOLVED for audit):\n$matches"
fi

# VALID sebagai status code (bukan sebagai kata "valid" umum, validasi, validation, valid_until, dll)
matches=$(grep -rnE '"(code|status)":\s*"VALID"' docs/ app/ knowledge/ evaluation/ 2>/dev/null \
  | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
  | grep -vE "docs/audit/" \
  | grep -vE "docs/rules/" \
  | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
  || true)
if [ -n "$matches" ]; then
  log_error "FORBIDDEN_CODE 'VALID' (use PAYMENT_VALID):\n$matches"
fi

# UNAVAILABLE tanpa prefix STOCK_
matches=$(grep -rnE '"(code|status)":\s*"UNAVAILABLE"' docs/ app/ knowledge/ evaluation/ 2>/dev/null \
  | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
  | grep -vE "docs/audit/" \
  | grep -vE "docs/rules/" \
  | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
  || true)
if [ -n "$matches" ]; then
  log_error "FORBIDDEN_CODE 'UNAVAILABLE' (use STOCK_UNAVAILABLE):\n$matches"
fi

# HANDOVER tanpa suffix _CS atau _CREATED atau _REQUIRED
matches=$(grep -rnE '"(code|status|state)":\s*"HANDOVER"' docs/ app/ knowledge/ evaluation/ 2>/dev/null \
  | grep -vE "docs/0\. GOODANG_CONTRACT\.md" \
  | grep -vE "docs/audit/" \
  | grep -vE "docs/rules/" \
  | grep -vE "docs/17\. GOODANG_CI_BRANCH_PROTECTION_SPEC\.md" \
  || true)
if [ -n "$matches" ]; then
  log_error "FORBIDDEN_CODE 'HANDOVER' (use HANDOVER_CS for state, HANDOVER_CREATED for result):\n$matches"
fi

echo "===> 5. Cek docs/0. GOODANG_CONTRACT.md ada"
if [ ! -f "docs/0. GOODANG_CONTRACT.md" ]; then
  log_error "MISSING docs/0. GOODANG_CONTRACT.md (single source of truth)"
fi

echo ""
if [ "$STATUS" -eq 0 ]; then
  echo "✓ Contract drift check PASSED"
  exit 0
else
  echo "✗ Contract drift check FAILED"
  echo ""
  printf '%s\n' "${ERRORS[@]}"
  exit 1
fi
