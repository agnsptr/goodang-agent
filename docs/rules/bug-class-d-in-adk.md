# Rule: Class D Tools Tidak Boleh Dipanggil dari ADK Layer

**Severity:** P0
**Konteks:** ADK Agent, Temporal Worker, Tool Registry
**Referensi:** `docs/0` §3.4, `docs/12` ADR-003

## Don't

Class D tools (`create_transaction`, `deduct_stock`, `execute_payment`, `write_pos_transaction_log`) **TIDAK BOLEH** dipanggil dari ADK layer atau didaftarkan di `app/tools/registry.yaml` class_a/class_b/class_c. Mereka hanya boleh dipanggil dari `goodang-temporal-worker` sebagai Temporal activity.

## Do

- Daftar Class D tools HANYA di `class_d_forbidden_in_adk` section di `app/tools/registry.yaml`
- Implement Class D tools sebagai Temporal activity di `app/temporal/activities/`
- Panggil dari Temporal worker yang pegang `SUPABASE_SERVICE_ROLE_KEY`

## Contoh SALAH

```python
# app/agents/goodang_agent.py — DILARANG
from app.tools.class_d import create_transaction

async def handle_confirm(intent):
    # ADK langsung call Class D tool — P0 violation
    result = await create_transaction(order_id=order_id)
```

```yaml
# app/tools/registry.yaml — DILARANG
class_a:
  - name: create_transaction   # P0 violation: Class D di ADK registry
```

## Contoh BENAR

```python
# app/temporal/worker.py — BENAR
@activity.defn
async def create_transaction_activity(order_id: str) -> dict:
    # Class D tool, hanya di Temporal worker
    return await transaction_service.create(order_id)

# app/agents/goodang_agent.py — BENAR
async def handle_confirm(intent):
    # ADK kirim Update ke Temporal workflow, workflow yang call activity
    await temporal_client.send_update(
        workflow_id=f"GOODANG:{order_id}",
        update_name="confirm_order",
        args={},
    )
```

```yaml
# app/tools/registry.yaml — BENAR
class_d_forbidden_in_adk:
  - create_transaction
  - deduct_stock
  - execute_payment
  - write_pos_transaction_log
```

## Deteksi

- `scripts/check-tool-registry-sync.py` — CI hard gate
- CodeRabbit — review kontekstual
- Bandit — statik analysis
