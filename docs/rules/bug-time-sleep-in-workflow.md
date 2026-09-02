# Rule: time.sleep / asyncio.sleep Dilarang di Temporal Workflow

**Severity:** P0
**Konteks:** Temporal workflow code, determinism
**Referensi:** `docs/15` §5, Temporal best practices

## Don't

Di dalam Temporal workflow code, **TIDAK BOLEH** pakai `time.sleep()`, `asyncio.sleep()`, `datetime.now()`, `random.random()`, atau operasi non-deterministik lainnya. Workflow code wajib deterministic — replay akan menghasilkan hasil berbeda kalau pakai non-deterministic calls.

## Do

- Untuk timer: `await workflow.execute_timer(timedelta(minutes=30))`
- Untuk datetime: `workflow.now()`
- Untuk random: `workflow.random()`
- Untuk sleep di activity: `time.sleep` OK (activity non-deterministic)

## Contoh SALAH

```python
# app/temporal/workflows/order_workflow.py — DILARANG
import asyncio

@workflow.workflow
class OrderWorkflow:
    @workflow.run
    async def run(self, order_id: str) -> str:
        await asyncio.sleep(1800)  # P0: non-deterministic
        self.state = "EXPIRED"
```

```python
# DILARANG
import time
time.sleep(30)  # P0: blocks worker thread + non-deterministic
```

## Contoh BENAR

```python
# app/temporal/workflows/order_workflow.py — BENAR
from datetime import timedelta
from temporalio import workflow

@workflow.workflow
class OrderWorkflow:
    @workflow.run
    async def run(self, order_id: str) -> str:
        await workflow.execute_timer(timedelta(minutes=30))  # OK: deterministic
        self.state = "EXPIRED"
```

## Deteksi

- Bandit (AST scan untuk `time.sleep` di workflow file)
- CodeRabbit — review workflow code
- Temporal replay test (Fase 2)
