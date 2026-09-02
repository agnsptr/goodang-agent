# FASE 3 — Adopsi

**Timeline:** Bulan 5–8  
**Goal:** Draft order + Temporal 19-state workflow + Telegram pipeline + Class D isolation + observability  
**Exit gate:** 150 eval cases, accuracy ≥ 95%, business safety 100%, staging E2E

---

## 1. Scope

### In scope
- 4 Class B tools (`create_draft_order`, `update_order_draft`, `add_order_item`, `remove_order_item`)
- 4 Class C tools: `start_order_workflow` (**StartWorkflow**) + `confirm_order`, `cancel_order`, `request_human_handover` (**Updates**)
- Temporal workflow + activities (`app/temporal/`)
- Telegram: Cloudflare Workers → Supabase Queue → ADK dequeue
- Class D activities in **separate worker** container only
- `POS_TRANSACTION_LOG` append-only enforcement
- OpenTelemetry tracing (ADR-009)
- Eval 150 cases (all categories)

### Out of scope (Fase 4)
- `agent_memory` / Hermes
- Temporal Cloud migration (prepare runbook only)
- 9Router multi-model routing

---

## 2. Architecture (Fase 3)

```text
Telegram
  → Cloudflare Workers (secret validation, dedup INSERT telegram_update_dedup)
  → Supabase Queue (pgmq)
  → goodang-adk (dequeue, ADK, Class A/B/C)
  → Temporal Server (VPS-2)
  → goodang-temporal-worker (Class D + service_role)
  → Supabase goodang-app (POS_TRANSACTION_LOG append-only)
```

**Container isolation (ADR-003):** ADK and Temporal worker are separate Docker services. Never co-locate `SUPABASE_SERVICE_ROLE_KEY` with ADK.

---

## 3. Temporal Implementation

### 3.1 Signal vs Update (canonical)

From `docs/15` §4 — **already synced to `docs/5`:**

| Interaction | Mechanism |
|:--|:--|
| `confirm_order`, `cancel_order`, `request_human_handover` | **Update** — sync receipt to ADK |
| Customer message / product selection | **Signal** |
| `start_order_workflow` | **StartWorkflow** with ID `GOODANG:{order_id}` |

### 3.2 Workflow ID & idempotency

- Workflow ID: `GOODANG:{order_id}` (`docs/0` §8)
- Activity idempotency keys: `GOODANG-PAY:{transaction_id}`, `GOODANG-STOCK:{transaction_id}`, etc.
- `PAYMENT_ALREADY_PROCESSED` on duplicate payment insert (`docs/0` §7.7)

### 3.3 State machine

Implement all 19 states from `docs/0` §2. Transitions from `docs/6`.

**Timer:** `WAITING_CONFIRMATION` → `EXPIRED` after 30 minutes via `workflow.wait_condition` + timer — **never** `time.sleep` in workflow code.

**Run timeout:** 24 hours max workflow lifetime.

### 3.4 Activity retry

Per `docs/0` §11.1: initial 2s, backoff 2.0, max 30s, max 5 attempts.

Non-retryable: `docs/0` §11.4 + `PAYMENT_ALREADY_PROCESSED`, `CONFIRMATION_INVALID`.

### 3.5 Stock strategy (ADR-006 Opsi A)

No reservation in Fase 3 MVP:
1. `check_stock_activity` at validation
2. `deduct_stock_activity` at transaction — may return `INSUFFICIENT_STOCK`
3. Workflow returns to `BUILDING_ORDER`

Opsi B (stock reservation with timed hold) requires contract update — defer until production evidence.

---

## 4. Class D — Transaction Service

Activities (worker only):
- `create_transaction_activity`
- `deduct_stock_activity` → calls `goodang.deduct_stock` RPC
- `execute_payment_activity` → idempotent via `payment.idempotency_key`
- `write_pos_transaction_log_activity` → INSERT only

**CI gate:** `grep service_role app/agents app/tools` = fail. Class D not in `registry.yaml`.

---

## 5. Telegram Pipeline

### 5.1 Edge (Cloudflare Workers)
1. Validate `X-Telegram-Bot-Api-Secret-Token` (constant-time)
2. INSERT `telegram_update_dedup` — on conflict, return 200 skip
3. Enqueue to `pgmq` queue `telegram_inbound`
4. Return 200 **after enqueue**, not after ADK processing

### 5.2 ADK consumer (`app/telegram/`)
- `webhook.py` — optional local dev only; production uses queue consumer
- `router.py` — map update → ADK session
- `sender.py` — outbound Telegram API

See `docs/11. GOODANG_TELEGRAM_INTEGRATION_SPEC.md`.

---

## 6. Observability (ADR-009)

| Layer | Instrumentation |
|:--|:--|
| ADK | Span per intent + tool call |
| Temporal | Span per activity; search attrs: `chat_id`, `member_id`, `goodang.state` |
| Supabase | Span per query with `table`, `operation` tags |
| Export | OTLP → collector (Grafana Cloud or self-host) |

**Metrics alert thresholds:**
- `HANDOVER_CS` rate > 5%
- Activity retry p95 > 3
- `PAYMENT_FAILED` rate > 2%

**PII:** mask `member_name`, `phone` in logs.

---

## 7. Eval (150 cases)

Complete all folders in `docs/16` §2:

| Folder | Cases |
|:--|:--|
| `06_modification/` | 15 |
| `07_confirmation/` | 15 |
| `08_handover/` | 10 |
| `09_prompt_injection/` | 15 |
| `10_edge_cases/` | 10 |

**Gates:**
- Accuracy ≥ 95%
- Business safety 100% (no forbidden tool calls)
- `FORBIDDEN_TOOL_CALL` = 0

---

## 8. Deployment (staging)

1. VPS-1: `docker compose --profile adk-stack up`
2. VPS-2: `docker compose --profile temporal-stack up`
3. Supabase: apply all migrations through `11_telegram_update_dedup.sql` + `92_rpc_deduct_stock.sql`
4. Cloudflare Worker deploy (separate pipeline)
5. Smoke: happy path order in staging Telegram bot

---

## 9. References

- `docs/5. GOODANG_TEMPORAL_WORKFLOW_SPEC.md`
- `docs/5.1. GOODANG_TEMPORAL_IMPLEMENTATION_SPEC.md`
- `docs/15. GOODANG_TEMPORAL_DEPLOYMENT_SPEC.md`
- `docs/11. GOODANG_TELEGRAM_INTEGRATION_SPEC.md`
- `docs/13. GOODANG_INFRASTRUCTURE_SPEC.md`
- `docs/IMPLEMENTATION_CHECKLIST.md` § Fase 3
