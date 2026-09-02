<!--
PR Template — Goodang Autonomous CS Agent
Sesuai docs/17. GOODANG_CI_BRANCH_PROTECTION_SPEC.md & SOP-ENT-DEV-004.
CodeRabbit akan auto-review PR ini. Guardian wajib approve sebelum merge.
-->

## Ringkasan

<!-- 1-2 kalimat: apa yang diubah & kenapa -->

## Jenis Perubahan

- [ ] Fix bug
- [ ] Fitur baru
- [ ] Refactor
- [ ] Dokumentasi
- [ ] CI/Infra
- [ ] Kontrak (docs/0) — wajib referensi ADR

## Checklist Kontrak (wajib jika sentuh kontrak)

- [ ] Update `docs/0. GOODANG_CONTRACT.md` terlebih dahulu (§13 Change Management)
- [ ] Update `app/tools/registry.yaml` jika tambah/ubah tool
- [ ] Tidak ada ghost state (`WAITING_CUSTOMER`, `CUSTOMER_CONFIRMATION`, `VALIDATION`)
- [ ] Tidak ada forbidden tool name (`lookup_customer`, `add_item`, `cancel_draft`, dll — docs/0 §3.5)
- [ ] Tidak ada forbidden error code (`RESOLVED`, `VALID`, `UNAVAILABLE`, `HANDOVER` — docs/0 §7.13)

## Checklist Keamanan (wajib)

- [ ] Tidak ada secret di code (SUPABASE_SERVICE_ROLE_KEY, TELEGRAM_BOT_TOKEN, password)
- [ ] Class D tools tidak dipanggil dari ADK layer (hanya Temporal worker)
- [ ] `service_role` key tidak digunakan di ADK/App Layer container
- [ ] Tidak ada UPDATE/DELETE pada `pos_transaction_log`
- [ ] PII (member_name, phone, chat_id) di-mask di log

## Checklist Testing

- [ ] pytest lulus lokal
- [ ] Tambah test case baru untuk fitur/fix
- [ ] Eval harness lulus (jika sentuh `app/agents/` atau prompt)

## Referensi

- ADR terkait: <!-- docs/12. GOODANG_ADR.md#ADR-XXX -->
- Issue terkait: <!-- #NNN -->
- Dokumen terkait: <!-- docs/N. GOODANG_XXX.md -->

## Catatan untuk Reviewer

<!-- Hal spesifik yang perlu diperhatikan, trade-off, dll -->

---

**Untuk Guardian:** CodeRabbit memberi pre-review. Verifikasi hard gate CI lulus, lalu approve/merge sesuai SOP-ENT-DEV-004.
