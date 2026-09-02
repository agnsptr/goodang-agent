# CodeRabbit Rules Knowledge Base

Folder ini adalah **Knowledge Base** untuk CodeRabbit AI review (sesuai WI-ENT-DEV-003 & SOP-ENT-DEV-004).

## Aturan Penulisan Rule

Setiap file rule wajib:

1. **Nama file**: `bug-[slug].md` (contoh: `bug-class-d-in-adk.md`)
2. **Severity**: P0 / P1 / P2
3. **Struktur**: Do / Don't + contoh SALAH + contoh BENAR
4. **Tidak boleh mengandung secret**
5. **Ringkas** — CodeRabbit baca ini sebagai konteks review

## Severity

| Severity | Arti | Aksi CodeRabbit |
|:--|:--|:--|
| P0 | Security, data integrity, contract violation | Request changes (block merge) |
| P1 | Kualitas, konsistensi, missing best practice | Comment (tidak block) |
| P2 | Style, dokumentasi, minor | Suggestion |

## Daftar Rule (seed)

| File | Severity | Konteks |
|:--|:--|:--|
| `bug-class-d-in-adk.md` | P0 | Class D tools dipanggil dari ADK layer |
| `bug-service-role-in-adk.md` | P0 | SUPABASE_SERVICE_ROLE_KEY di ADK container |
| `bug-pos-tl-mutation.md` | P0 | UPDATE/DELETE pada pos_transaction_log |
| `bug-time-sleep-in-workflow.md` | P0 | time.sleep / asyncio.sleep di Temporal workflow |
| `bug-ghost-state-usage.md` | P0 | Ghost state (WAITING_CUSTOMER, CUSTOMER_CONFIRMATION, VALIDATION) |
| `bug-forbidden-tool-name.md` | P0 | Forbidden tool name (lookup_customer, add_item, cancel_draft, dll) |
| `bug-missing-idempotency-key.md` | P1 | Side-effect activity tanpa idempotency key |
| `bug-missing-retry-policy.md` | P1 | Activity tanpa RetryPolicy |
| `bug-missing-otel-span.md` | P1 | Activity/tool tanpa OTel span |
| `bug-pii-in-log.md` | P0 | PII (member_name, phone, chat_id) di log plaintext |

## Tambah Rule Baru

Saat bug kritis di-fix, buat rule pencegahan:

1. Buat file `docs/rules/bug-[slug].md`
2. Set severity (P0/P1/P2)
3. Tulis Do/Don't + contoh SALAH/BENAR
4. Commit di PR yang sama dengan fix, atau PR terpisah dalam 1 hari kerja (SOP-ENT-DEV-004 §5.4)
5. CodeRabbit akan baca rule ini di PR berikutnya

## Referensi

- `docs/17. GOODANG_CI_BRANCH_PROTECTION_SPEC.md`
- SOP-ENT-DEV-004 (AI Code Review & PR Guardrail)
- WI-ENT-DEV-003 (Menulis Aturan Bug untuk CodeRabbit)
- BA-ENT-DEV-004 (AI-Powered Code Review & PR Guardrail)
