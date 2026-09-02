# Rule: Forbidden Tool Names Dilarang

**Severity:** P0
**Konteks:** ADK tool registry, Temporal activity names, code
**Referensi:** `docs/0` §3.5

## Don't

Tool names berikut **TIDAK BOLEH** dipakai (kecuali sebagai nama activity dengan suffix `_activity`):

- `lookup_customer` → tool = `identify_customer`, activity = `lookup_customer_activity`
- `create_draft` → gunakan `create_draft_order`
- `get_draft` → gunakan `get_order_draft`
- `update_draft` → gunakan `update_order_draft`
- `update_draft_order` → gunakan `update_order_draft`
- `add_item` → gunakan `add_order_item`
- `remove_item` → gunakan `remove_order_item`
- `cancel_draft` → gunakan `cancel_order`

## Do

- Pakai hanya nama kanonik di `docs/0` §3.1–§3.4
- Activity names: `<tool_name>_activity` (docs/0 §4)
- Update `app/tools/registry.yaml` sink dengan `docs/0` §3

## Contoh SALAH

```python
# DILARANG
@activity.defn
async def lookup_customer(phone: str) -> dict:  # P0: forbidden name tanpa _activity suffix
    ...
```

```python
# DILARANG
async def add_item(order_id: str, sku: str) -> dict:  # P0: forbidden
    ...
```

```yaml
# app/tools/registry.yaml — DILARANG
class_b:
  - name: update_draft_order  # P0: forbidden, pakai update_order_draft
```

## Contoh BENAR

```python
# BENAR
@activity.defn
async def lookup_customer_activity(phone: str) -> dict:  # OK: _activity suffix
    ...

@activity.defn
async def update_order_draft_activity(...) -> dict:  # OK: canonical name + suffix
    ...
```

```yaml
# app/tools/registry.yaml — BENAR
class_b:
  - name: update_order_draft  # canonical
    activity: update_order_draft_activity
```

## Deteksi

- `scripts/check-contract-drift.sh` — CI hard gate (grep forbidden tool names)
- `scripts/check-tool-registry-sync.py` — CI hard gate (registry ↔ contract)
- CodeRabbit — review tool usage
