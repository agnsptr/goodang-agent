# Goodang Agent — Deep Audit Report (Specification Layer)

**Audit ID:** AUD-SPEC-001
**Scope:** Seluruh file repositori `goodang-agent` (baseline `54ed2d9` @ `main`)
**Mode:** deep-codebase-dive + deep-bug-audit (full-pipeline, specification-only)
**Date:** 2026-09-02
**Methodology:** STD-ENT-QA-001, BA-ENT-DEV-005, WI-ENT-DEV-004

---

## 0. Ringkasan Eksekutif

Repo `goodang-agent` pada baseline `54ed2d9` adalah **specification-only repository**. Tidak ada satu pun file kode implementasi (`.py`, `.yaml`, `.json`, `.env.example`, `pyproject.toml`) yang ada. Yang ada hanya:

- 14 file markdown spesifikasi (~24.000 baris) di `docs/`
- 14 duplikat byte-identik tersebar di `app/agents/`, `app/tools/`, `app/schemas/`, `app/temporal/`, `app/telegram/`, `knowledge/`, `evaluation/`
- 9 file `.gitkeep` untuk direktori kosong
- `README.md`, `.gitignore`

Karena tidak ada kode, audit berfokus pada **(a) konsistensi internal antar dokumen**, **(b) gap referensi file yang disebut tapi tidak ada**, **(c) risiko desain kontrak**.

### Temuan kunci

| # | Kategori | Severity | Jumlah |
|---|---|---|---|
| C1 | Inkonsistensi penamaan tool/activity antar dokumen | Critical | 7 |
| C2 | Inkonsistensi state machine antar dokumen | Critical | 6 |
| C3 | Inkonsistensi result/error code antar dokumen | Critical | 5 |
| C4 | Inkonsistensi aturan konfirmasi (hard gate) | Critical | 2 |
| C5 | Inkonsistensi target jumlah evaluation cases | Major | 3 dokumen |
| M1 | Field schema TBD / tidak didefinisikan | Major | 8 |
| M2 | File referensi yang tidak ada di repo | Major | 20+ |
| M3 | Risiko desain (TOCTOU, compensation, EXPIRED) | Major | 6 |
| L1 | Typo / format / duplikasi file | Low | 4 |
| L2 | Marker artefak `filecite` di System Inventory | Low | banyak |

**Bottom line:** Spesifikasi secara arsitektural sangat matang, tetapi **belum siap ditanganikan ke implementor** karena banyak nama tool/state/code kontradiktif antar dokumen. Implementor yang membaca dokumen berbeda akan menghasilkan kode yang tidak interoperable.

---

## 1. Inventory Repo

### 1.1 File ada

```
.gitignore, README.md
docs/{1..11}. GOODANG_*.md + docs/GOODANG_ADK_PROMPT_SPEC.md
app/agents/{2,6,7}. GOODANG_*.md + GOODANG_ADK_PROMPT_SPEC.md  (duplikat)
app/tools/{3,3.1}. GOODANG_*.md                                  (duplikat)
app/schemas/4. GOODANG_*.md                                      (duplikat)
app/temporal/{5,5.1}. GOODANG_*.md                               (duplikat)
app/telegram/11. GOODANG_*.md                                    (duplikat)
evaluation/8. GOODANG_*.md                                       (duplikat)
knowledge/{1,9,10}. GOODANG_*.md                                 (duplikat)
{app/agents,app/integrations,app/schemas,app/telegram,app/temporal,
 app/tools,evaluation,rules,tests}/.gitkeep
```

### 1.2 File TIDAK ada (tapi dirujuk spesifikasi)

| Path direferensikan | Sumber | Status |
|---|---|---|
| `app/agents/root_agent.py`, `prompts.py`, `callbacks.py` | `docs/9:234-244` | Tidak ada |
| `app/tools/*_tools.py` | `docs/9:248-256` | Tidak ada |
| `app/schemas/{intent,order,product,customer}.py` | `docs/9:258-264` | Tidak ada |
| `app/integrations/*_client.py` | `docs/9:266-272` | Tidak ada |
| `app/temporal/client.py`, `worker.py` | `docs/9:274-276` | Tidak ada |
| `app/temporal/workflows/order_workflow.py` | `docs/9:278` | Tidak ada |
| `app/temporal/activities/*.py` | `docs/9:280-286` | Tidak ada |
| `app/telegram/webhook.py`, `router.py`, `sender.py` | `docs/9:288-292`, `docs/11:602` | Tidak ada |
| `knowledge/CS_SOP.md`, `DATA_RULES.md`, `COLUMN_MAPPING.md`, `PAYMENT_POLICY.md`, `HANDOVER_POLICY.md` | `docs/1:1080-1084` | Tidak ada |
| `rules/order_rules.yaml`, `payment_rules.yaml`, `escalation_rules.yaml` | `docs/1:1092`, `docs/9:300-304` | Tidak ada |
| `prompts/system.md` … `examples.md` | `docs/GOODANG_ADK_PROMPT_SPEC.md:76-84` | Tidak ada |
| `tests/unit/`, `tests/integration/`, `tests/eval/` | `docs/1:1088-1090` | Hanya `.gitkeep` |
| `evaluation/dataset/golden/*.json` | `docs/8:1575-1583` | Hanya `.gitkeep` |
| `POS_TRANSACTION_LOG_Documentation.md` | `docs/11:73` | Tidak ada |
| `.env.example`, `pyproject.toml` | `docs/9:319-320` | Tidak ada |

### 1.3 Verifikasi duplikat

Semua 14 pasangan duplikat antara `docs/` dan `app/*`/`knowledge/`/`evaluation/` adalah **byte-identical** (md5 cocok). Tidak ada divergensi konten saat ini, tetapi **tidak ada mekanisme** untuk menjaga kesinkronan ke depan (tidak ada symlink, tidak ada generator, tidak ada CI check). Risiko divergensi = tinggi saat edit pertama dilakukan.

---

## 2. Cross-Document Inconsistencies (Critical)

### C1 — Inkonsistensi penamaan tool / activity

| Konsep | Tool Contract (docs 3/3.1/9) | Temporal Spec (docs 5/5.1) | Agent Contract (doc 2) |
|---|---|---|---|
| Identifikasi customer | `identify_customer` | `lookup_customer` | `identify_customer` |
| Buat draft | `create_draft_order` | `create_draft` | `create_draft_order` |
| Ambil draft | `get_order_draft` | `get_draft` | `get_order_draft` |
| Update draft | `update_order_draft` | `update_draft` / `update_draft_order` | `update_draft_order` |
| Tambah item | `add_order_item` | (n/a, pakai `update_draft`) | `add_item` |
| Hapus item | `remove_order_item` | (n/a, pakai `update_draft`) | `remove_item` |
| Cancel | `cancel_order` | (n/a) | `cancel_order` |
| Cancel (doc 10) | `cancel_order` | (n/a) | `cancel_draft` (doc 10:706) |

**Bukti path:line:**

- `docs/3.1:135-145` — `identify_customer` vs `docs/5:441,1684` — `lookup_customer`
- `docs/3.1:150-154` — `create_draft_order`, `get_order_draft`, `update_order_draft` vs `docs/5:1703-1705` — `create_draft`, `get_draft`, `update_draft`
- `docs/2:1110-1130` — `add_item`, `remove_item` vs `docs/3.1:153-154` — `add_order_item`, `remove_order_item`
- `docs/10:706` — `cancel_draft` vs `cancel_order` di dokumen lain

**Risiko:** Activity `lookup_customer` yang membungkus tool `identify_customer` tidak ada mapping eksplisit. Integration test akan gagal karena nama berbeda.

**Rekomendasi:** Tambahkan tabel mapping eksplisit "ADK tool name ↔ Temporal activity name" di `docs/3` dan `docs/5`. Atau samakan namanya.

---

### C2 — Inkonsistensi state machine

State machine didefinisikan di 6+ dokumen dan **tidak semua state muncul di semua dokumen**.

| State | doc 1 | doc 4 §20 | doc 5 | doc 5.1 | doc 6 | doc 9 §25 | doc 7 §42 |
|---|---|---|---|---|---|---|---|
| `NEW` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `IDENTIFYING_CUSTOMER` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `BUILDING_ORDER` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `NEED_PRODUCT_CONFIRMATION` | ✗ | ✓ | ✓ | ✓ | ✓ | **✗** | ✓ |
| `VALIDATING_ORDER` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CHECKING_STOCK` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CHECKING_PRICE` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CHECKING_PAYMENT` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `WAITING_CONFIRMATION` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `MODIFICATION_REQUESTED` | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CONFIRMED` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `PROCESSING` | ✓ | ✗ (enum §52) | ✓ | ✓ | ✓ | ✓ | **✗ ABSENT** |
| `CREATING_TRANSACTION` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `UPDATING_STOCK` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `COMPLETED` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CANCELLED` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `HANDOVER_CS` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `ERROR` | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| `EXPIRED` (opsional) | ✓ sebut | ✗ | ✓ future | ✓ TBD | ✓ future | ✗ | ✗ |

**Ghost states** (disebut di transisi tapi tidak ada di daftar state resmi):

- `WAITING_CUSTOMER` — `docs/5:345`
- `CUSTOMER_CONFIRMATION` — `docs/5:346`
- `VALIDATION` — `docs/6:1319` (seharusnya `VALIDATING_ORDER`)

**Inkonsistensi internal di doc 4:** Order Status enum §52 (`docs/4:1354-1363`) adalah subset yang tidak selaras dengan workflow state §20 (`docs/4:521-539`) — hilang `IDENTIFYING_CUSTOMER`, `CHECKING_*`, `CREATING_TRANSACTION`, `UPDATING_STOCK`, `MODIFICATION_REQUESTED`, `NEED_PRODUCT_CONFIRMATION`. Dua enum di file yang sama, tanpa penjelasan.

**Inkonsistensi internal di doc 5.1:** State `NEED_PRODUCT_CONFIRMATION` ada di daftar minimum (`docs/5.1:242-261`) tetapi tidak ada di happy path sequence (`docs/5.1:833-859`).

**Risiko:** Implementor yang membaca doc 9 akan menganggap `NEED_PRODUCT_CONFIRMATION` tidak perlu. Implementor yang membaca doc 6 akan mengimplementasinya. Hasilnya: state yang seharusnya menghentikan flow ketika produk ambigu jadi tidak ada → agent memilih produk random → melanggar Rule 001 (No Guessing).

**Rekomendasi:** Jadikan `docs/6. GOODANG_STATE_MACHINE.md` sebagai **single source of truth** untuk state. Hapus daftar state dari docs 1, 4, 5, 5.1, 9; ganti dengan referensi ke doc 6.

---

### C3 — Inkonsistensi result / error code

| Konsep | doc 3 | doc 4 | doc 5 | doc 5.1 | doc 6 | doc 8 |
|---|---|---|---|---|---|---|
| Produk ditemukan | `PRODUCT_FOUND` | `PRODUCT_FOUND` | `RESOLVED` | (n/a) | `PRODUCT_FOUND` | `PRODUCT_NOT_FOUND` |
| Audit produk resolved | (n/a) | `PRODUCT_RESOLVED` | `PRODUCT_RESOLVED` | (n/a) | (n/a) | (n/a) |
| Pembayaran valid | `PAYMENT_VALID` | `PAYMENT_VALID` | `VALID` | `PAYMENT_VALID` | `PAYMENT_VALID` | (n/a) |
| Stok unavailable | `STOCK_UNAVAILABLE` | `STOCK_UNAVAILABLE` | (n/a) | (n/a) | `STOCK_UNAVAILABLE` | (n/a) |
| Stok enum unavailable | (n/a) | `UNAVAILABLE` (4:1381) | (n/a) | (n/a) | (n/a) | (n/a) |
| Handover state | `HANDOVER_CS` | `HANDOVER_CS` | `HANDOVER_CS` | `HANDOVER_CS` | `HANDOVER_CS` | `HANDOVER_CS` |
| Handover result | `HANDOVER_CREATED` | (n/a) | `HANDOVER_CREATED` | (n/a) | (n/a) | `HANDOVER` (8:1172) |

**Bukti:**

- `docs/5:489` — `RESOLVED` (bukan `PRODUCT_FOUND`)
- `docs/5:632` — `status: "VALID"` (bukan `PAYMENT_VALID`)
- `docs/4:361` — `STOCK_UNAVAILABLE` vs `docs/4:1381` — `UNAVAILABLE` (di file yang sama)
- `docs/8:1172` — `HANDOVER` vs `docs/8:955` — `HANDOVER_CS` (di file yang sama)

**Risiko:** Agent logic `if code == "PRODUCT_FOUND"` akan fail saat activity return `RESOLVED`. Error handling bocor.

**Rekomendasi:** Buat katalog kanonik error code di satu tempat (mis. `docs/3. GOODANG_TOOL_CONTRACT.md` §27 sudah ada, jadikan itu SoT). Semua dokumen lain referensi ke sana.

---

### C4 — Inkonsistensi aturan konfirmasi (hard gate)

Dua invariant konfirmasi yang **wording-nya berbeda** dan bisa ditafsirkan sebagai gate berbeda:

- `docs/5.1:1728-1730` (INV-001): `state != WAITING_CONFIRMATION` → "YA" tidak boleh finalize transaction
- `docs/6:174-177` (INV-001): `state != CONFIRMED` → no transaction created

Ini dua state berbeda. `WAITING_CONFIRMATION` adalah state sebelum customer confirm. `CONFIRMED` adalah state setelah customer confirm, sebelum transaction dibuat. Jika implementor membaca doc 6, mereka mungkin mengizinkan transaction creation di state `CONFIRMED` tanpa pernah validasi bahwa transition `WAITING_CONFIRMATION → CONFIRMED` benar-benar terjadi karena customer said "YA". Ini bisa membuka bypass di mana workflow masuk `CONFIRMED` via path lain lalu transaction dibuat.

**Rekomendasi:** Satukan wording invariant: "Transaction creation membutuhkan `state == CONFIRMED` **DAN** transition ke `CONFIRMED` hanya boleh dari `WAITING_CONFIRMATION` **DAN** hanya via event `CUSTOMER_CONFIRM`."

---

### C5 — Inkonsistensi target jumlah evaluation cases

| Dokumen | Kategori | Target per kategori | Total |
|---|---|---|---|
| `docs/1:1286-1318` (§43) | 24 | 5 | **120** |
| `docs/2:1500-1530` (§46) | 17 | 5 | **>= 85** |
| `docs/8:272-314` (§1) | 30 | 5 | **150** |

Tiga target berbeda di tiga dokumen. QA yang membaca doc 2 akan membuat 85 cases; QA yang membaca doc 8 akan membuat 150. Coverage matrix akan berbeda.

**Rekomendasi:** Jadikan `docs/8. GOODANG_AGENT_EVALUATION.md` sebagai SoT (paling baru, paling banyak). Update doc 1 dan doc 2 untuk referensi.

---

## 3. Gap & Missing Definitions (Major)

### M1 — Field schema TBD / tidak didefinisikan

| Item | Status | Sumber |
|---|---|---|
| `cooked_qty` semantics | TBD, formula universal tidak ada | `docs/4:773-777` |
| Service fee rule | `SERVICE_FEE_RULE = BUSINESS_RULE / TBD` | `docs/4:798` |
| `line_amount = qty × selling_price` — service_fee di line item TIDAK masuk formula | Inkonsistensi formula | `docs/4:812` vs `docs/4:463` |
| `total = subtotal + applicable service fee` — agregasi per-line vs per-order tidak spesifik | Ambigu | `docs/4:845` |
| `execute_payment` input/output schema | TBD | `docs/3.1:1421-1440`, `docs/5.1:751-773` |
| `get_product` output schema | Tidak ada | `docs/5.1:520-533` |
| `create_draft_order`, `get_order_draft` detail section | Tidak ada | `docs/5.1` |
| Idempotency key payment execution | TBD | `docs/3.1:1704`, `docs/5.1` |
| EXPIRED timeout duration | TBD | `docs/5.1:1572-1574`, `docs/6:1496-1503` |
| Backend API endpoint | TBD | `docs/4:1401-1406`, `docs/10` |
| Temporal namespace policy | TBD | `docs/5.1:163-165` |
| Signal vs Update mechanism | Belum dipilih | `docs/5:772, 1640` |
| Workflow versioning strategy | Prinsip saja | `docs/5:1663-1674` |
| Payment compensation (refund/reverse/reconcile) | TBD | `docs/5.1:1663-1675` |
| Stock reservation rule | Optional, deferred | `docs/1:1199-1222`, `docs/5:1511-1537` |
| Backend HTTP status → canonical code mapping | TBD | `docs/3.1:1615` |

### M2 — File referensi yang tidak ada di repo

Lihat tabel di §1.2. Total 20+ path file kode/konfigurasi/yaml/json/md direferensikan spesifikasi tetapi tidak ada. Ini wajar karena repo masih specification-only, tetapi **tidak ada checklist atau issue tracker** yang mencatat gap ini. Implementor yang mulai Phase 1 tidak akan tahu mana yang harus dibuat dulu.

**Rekomendasi:** Buat `docs/IMPLEMENTATION_CHECKLIST.md` yang memetakan setiap fase (docs 1 §46, docs 9 milestone) ke file yang harus dibuat.

### M3 — Risiko desain kontrak

#### M3.1 — TOCTOU stock race condition (Major)

Spesifikasi eksplisit: stock reservation **deferred** untuk MVP (`docs/1:1199-1222`). Alur:

```
check_stock(sku, qty) → AVAILABLE
WAITING_CONFIRMATION (durasi TBD, bisa menit/jam)
confirm_order → create_transaction → deduct_stock
```

Antara `check_stock` dan `deduct_stock` tidak ada lock/reservation. Jika dua customer (atau dua workflow paralel untuk chat berbeda) melewati `check_stock` untuk SKU yang sama dengan total qty > stok, keduanya akan dapat `AVAILABLE`. Salah satu akan gagal di `deduct_stock` setelah customer konfirmasi — experience buruk + potensi double-allocate.

**Rekomendasi:** Walaupun reservation penuh deferred, tambahkan **soft reservation dengan TTL** di workflow state (mis. `reserved_qty` per SKU dengan TTL 5 menit), atau dokumentasikan eksplisit bahwa ini adalah known limitation yang ditangani via `INSUFFICIENT_STOCK` di akhir.

#### M3.2 — Confirmation keyword mapping tidak lengkap

`docs/1:727-737` mendaftar kata konfirmasi: `ya, iya, oke, ok, setuju, jadi, lanjut, pesan`. Tetapi `docs/7:373-375` hanya mendefinisikan tiga opsi: `YA`, `UBAH`, `BATAL`. Tidak ada mapping eksplisit dari "setuju"/"ok"/"lanjut" ke `CONFIRM_ORDER` command. Case sensitivity tidak dispesifikasi ("Ya" vs "YA").

**Risiko:** Agent akan inconsistent — kadang "setuju" diterima, kadang tidak, tergantung model LLM.

**Rekomendasi:** Tambah tabel kanonik di `docs/7`:

```
ya, iya, oke, ok, setuju, jadi, lanjut, pesan, yes → CONFIRM
ubah, ganti, rubah, edit, revisi → MODIFY
batal, cancel, gak jadi, batalkan → CANCEL
```

#### M3.3 — Success message gate ambigu (Major)

`docs/7:387-399` (§18): success message butuh `workflow_state = CONFIRMED`.
`docs/7:521-536` (§25): success message setelah transaction berhasil (umumnya `COMPLETED`).

`CONFIRMED` adalah state pre-transaction. `COMPLETED` adalah state post-transaction. Jika agent mengatakan "Pesanan berhasil dibuat" saat `CONFIRMED`, itu **pre-mature** — transaction belum ada. Ini melanggar Rule 008 (`docs/2:1440` — "Claim success before backend success").

**Rekomendasi:** Hapus §18 atau samakan: success message hanya boleh saat `transaction.status == COMPLETED` (lihat `docs/2:870-880`).

#### M3.4 — Payment idempotency key tidak didefinisikan

Transaction: `GOODANG:{order_id}`. Stock: `GOODANG-STOCK:{transaction_id}`. Payment: **TBD** (`docs/3.1:1704`). Padahal payment adalah operasi dengan side-effect paling berbahaya untuk di-retry tanpa idempotency.

**Rekomendasi:** Definisikan `GOODANG-PAY:{transaction_id}` atau `GOODANG-PAY:{order_id}` sebelum Phase 6.

#### M3.5 — `check_payment` tool tidak konsisten terdaftar

`check_payment` ada di `docs/3.1:768`, `docs/5:615`, `docs/5.1:607`, `docs/6:654`, prompt spec `:329`. Tetapi **tidak ada** di:
- `docs/1:568-578` (read tools list)
- `docs/9:363-378` (root agent tools)
- `docs/3:150-160` (Class A read tools)

Implementor yang hanya baca doc 9 akan lupa expose `check_payment` ke root agent → payment validation skip → pelanggaran Rule 005 (Source of Truth).

#### M3.6 — `get_order_status` tool tidak terdaftar di doc 3/9

`docs/1:568-578` mendaftar `get_order_status` sebagai read tool, tetapi doc 3 Class A dan doc 9 root agent tools hanya punya `get_order` dan `get_order_history`. Tidak jakah bedanya `get_order_status` vs `get_order` — apakah sama atau beda?

---

## 4. Low-Severity Findings

### L1 — Typo / format

- `docs/11:1911` — `[payment check` bracket tidak tertutup di checklist §80.
- `docs/5:345` — `WAITING_CUSTOMER` (ghost state, kemungkinan typo untuk `BUILDING_ORDER` atau `WAITING_CONFIRMATION`).
- `docs/5:346` — `CUSTOMER_CONFIRMATION` (ghost state, kemungkinan typo untuk `WAITING_CONFIRMATION`).
- `docs/6:1319` — `VALIDATION` (kemungkinan typo untuk `VALIDATING_ORDER`).
- `docs/6:1474` — `STOCK_DEDUCT` vs `STOCK_DEDUCTED` di §28 system events (di file yang sama).
- `docs/6:352` — `CUSTOMER_IDENTIFIED` (§9) vs `CUSTOMER_FOUND` (guard table §43, `docs/6:1558`) — dua nama untuk event yang sama.

### L2 — Marker artefak `filecite` di System Inventory

`docs/10. GOODANG_SYSTEM_INVENTORY.md` mengandung banyak marker `filecite` (mis. `:101, :162, :454, :654, :721, :984, :1262, :1364, :1456, :1480, :1774, :2349`) yang merupakan referensi ke sumber eksternal (kemungkinan dari tool extraction ENTIGI), bukan referensi ke file di repo. Marker ini tidak dijelaskan di dokumen. Pembaca baru akan bingung.

**Rekomendasi:** Tambahkan note di header doc 10: "Marker `filecite:N` adalah referensi internal ke evidence pack ENTIGI, bukan file repo."

### L3 — Duplikasi file tanpa mekanisme sync

14 dokumen diduplikasi ke `app/agents/`, `app/tools/`, `app/schemas/`, `app/temporal/`, `app/telegram/`, `knowledge/`, `evaluation/`. Saat ini byte-identical, tetapi:

- Tidak ada symlink (jadi konsumsi storage 2x)
- Tidak ada CI check untuk verifikasi kesinkronan
- Tidak ada dokumentasi mengapa duplikasi diperlukan

**Rekomendasi:** Pilih salah satu:
1. Hapus duplikat, simpan hanya di `docs/`. Update referensi.
2. Ganti dengan symlink: `ln -s ../../docs/1.\ GOODANG_ADK_AGENT_SPECIFICATION.md app/agents/1.\ GOODANG_ADK_AGENT_SPECIFICATION.md`
3. Tambah CI check: `md5sum docs/*.md app/**/*.md knowledge/*.md evaluation/*.md | sort | awk '{print $1}' | uniq -d` untuk detect hash yang muncul >1x (yang berarti duplikat divergen).

### L4 — Struktur `knowledge/` tidak sesuai spec

`docs/1:1080-1084` dan `docs/9:294-298` mengharapkan `knowledge/` berisi: `CS_SOP.md`, `DATA_RULES.md`, `COLUMN_MAPPING.md`, `PAYMENT_POLICY.md`, `HANDOVER_POLICY.md`. Yang ada di repo: `1. GOODANG_ADK_AGENT_SPECIFICATION.md`, `9. GOODANG_ADK_IMPLEMENTATION_SPEC.md`, `10. GOODANG_SYSTEM_INVENTORY.md` (duplikat docs/) + `.gitkeep`. Tidak ada satu pun file policy yang disebut.

---

## 5. Strategic Recommendations

### 5.1 Sebelum Phase 1 (ADK Skeleton) dimulai

1. **Resolve semua C1-C5 inconsistencies.** Tidak boleh ada dua nama untuk konsep yang sama. Buat glossary kanonik di `docs/0. GLOSSARY.md` berisi: state names, tool names, activity names, error codes, event names. Semua dokumen referensi ke glossary ini.
2. **Tetapkan single source of truth per dimensi:**
   - State → `docs/6`
   - Tool contract → `docs/3`
   - Error codes → `docs/3` §27
   - Evaluation → `docs/8`
   - Data schema → `docs/4`
   - Temporal workflow → `docs/5`
   - Temporal implementation → `docs/5.1`
   - ADK implementation → `docs/9`
   - Telegram integration → `docs/11`
   - Prompt → `docs/GOODANG_ADK_PROMPT_SPEC.md`
3. **Hapus duplikat** di `app/*`, `knowledge/`, `evaluation/` ATAU ganti dengan symlink. Tambah CI check.
4. **Buat IMPLEMENTATION_CHECKLIST.md** yang memetakan setiap fase ke file yang harus dibuat.
5. **Definisikan confirmation keyword mapping** kanonik di `docs/7`.
6. **Definisikan idempotency key untuk payment** sebelum Phase 6.

### 5.2 Saat implementasi

1. Implementasi mengikuti urutan fase di `docs/1:1466-1583` (Phase 0-9).
2. Setiap fase wajib menulis test terlebih dahulu (TDD) berdasarkan acceptance test di `docs/8` dan `docs/1:1322-1407`.
3. Setiap tool wajib punya test matrix di `docs/3:1700-1730` (happy, not found, invalid, ambiguous, unavailable, timeout, auth, duplicate, unexpected).
4. Setiap mutation wajib audit trail (`docs/3:1320-1340`).
5. Tidak ada `SUCCESS` claim sebelum test lulus (`docs/1:1599`).

### 5.3 Setelah implementasi

1. Jalankan full evaluation dataset (150 cases per `docs/8`).
2. Jalankan critical acceptance tests A-H (`docs/1:1322-1407`).
3. Audit security: webhook secret, secrets in env, Temporal not public, DB not public, no credential logging, prompt-injection handling.
4. Run worker restart test (test G di `docs/1:1386-1393`).
5. Run transaction retry test (test H di `docs/1:1397-1403`).

---

## 6. Definition of Done (Audit)

Audit ini dianggap selesai jika:

- [x] Semua file di repo di-inventory
- [x] Semua duplikat diverifikasi (byte-identical)
- [x] Semua inkonsistensi cross-document teridentifikasi (C1-C5)
- [x] Semua gap schema teridentifikasi (M1)
- [x] Semua file referensi yang tidak ada teridentifikasi (M2)
- [x] Semua risiko desain teridentifikasi (M3)
- [x] Rekomendasi strategis diberikan (§5)

## 7. Disclaimer

Audit ini adalah audit spesifikasi (static analysis terhadap dokumen), bukan audit kode dinamis. Tidak ada kode yang dijalankan. Temuan berdasarkan pembacaan dokumen dan cross-reference. Verifikasi manusia wajib sebelum remediasi produksi.

Audit ini tidak mengubah kode atau dokumen apa pun di repo. Semua rekomendasi bersifat proposal — keputusan eksekusi tetap di tangan tim engineering.

---

## 8. Referensi

- Skill: `deep-codebase-dive` (ENTIGI)
- Skill: `deep-bug-audit` (ENTIGI)
- Governance: STD-ENT-QA-001, BA-ENT-DEV-005, WI-ENT-DEV-004
- Baseline: `54ed2d9` @ `main`
- Subagent audit:
  - [Audit docs 3.1/4/5](2af46b40-e36f-41c3-8347-4bada235b981)
  - [Audit docs 5.1/6/7](3c3da4ab-63fe-4949-8e9d-0b4bd789ec6b)
  - [Audit docs 8/9/10/11/prompt](ae511fc7-6a03-495e-91e5-9d65d7377caa)
