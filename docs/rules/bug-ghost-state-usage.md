# Rule: Ghost State Names Dilarang

**Severity:** P0
**Konteks:** State machine, workflow state, response spec
**Referensi:** `docs/0` §2.4, `docs/6`

## Don't

State berikut **TIDAK BOLEH** dipakai sebagai state name di dokumen, code, atau workflow:

- `WAITING_CUSTOMER` → gunakan `BUILDING_ORDER` atau `WAITING_CONFIRMATION`
- `CUSTOMER_CONFIRMATION` → gunakan `WAITING_CONFIRMATION`
- `VALIDATION` → gunakan `VALIDATING_ORDER`

## Do

- Pakai hanya 19 state kanonik di `docs/0` §2.1–§2.3
- State transition: referensi `docs/6. GOODANG_STATE_MACHINE.md`
- Workflow state: simpan sebagai string, upsert ke Temporal search attribute `goodang.state`

## Contoh SALAH

```python
# DILARANG
self.state = "WAITING_CUSTOMER"  # P0: ghost state
```

```python
# DILARANG
if self.state == "CUSTOMER_CONFIRMATION":  # P0: ghost state
    ...
```

```markdown
<!-- DILARANG di spec docs -->
State: VALIDATION  → CONFIRMED
```

## Contoh BENAR

```python
# BENAR
self.state = "WAITING_CONFIRMATION"  # canonical
```

```python
# BENAR
if self.state == "VALIDATING_ORDER":  # canonical
    ...
```

## Deteksi

- `scripts/check-contract-drift.sh` — CI hard gate (grep ghost state names)
- CodeRabbit — review state usage
- `check-tool-registry-sync.py` — tidak terkait, tapi bagian dari contract integrity
