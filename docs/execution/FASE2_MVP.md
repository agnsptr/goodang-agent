# FASE 2 — MVP / Ekstraksi

**Timeline:** Bulan 3–4 (BA-ENT-STR-001)  
**Goal:** ADK skeleton + 13 Class A read tools + eval harness + Supabase schema live  
**Exit gate:** 60 eval cases, accuracy ≥ 90%, CI green

> **Contract:** `docs/0. GOODANG_CONTRACT.md` — update before any new name.

---

## 1. Scope

### In scope
- Python project structure (`docs/9` §6)
- Supabase migrations `00`–`11` (app data, no `agent_memory`)
- 13 Class A tools registered in `app/tools/registry.yaml`
- ADK root agent with tool allowlist (no Class D)
- Eval harness + 60 cases (stub 10 in repo, expand to 60)
- Unit tests for tools and schemas

### Out of scope (Fase 3+)
- Class B draft mutation tools
- Temporal workflow implementation
- Telegram production webhook
- Class D transaction activities
- `agent_memory` table

---

## 2. Architecture (Fase 2)

```text
Developer / Eval harness
        ↓
   ADK Test Client (evaluation/harness/client.py)
        ↓
   goodang-adk (root_agent.py)
        ↓ tool calls Class A only
   goodang-app-layer (FastAPI stubs → integrations)
        ↓ anon key + RLS
   Supabase Project #1 (goodang schema)
```

Temporal and Telegram are **mocked** in Fase 2 eval (`evaluation/harness/mocks.py`).

---

## 3. Implementation Order

### Week 1 — Foundation
1. `pyproject.toml`, `.env.example`, `app/config.py`
2. Run `supabase db push` or apply migrations locally
3. `app/schemas/*` from `docs/0` §10 + `docs/4`
4. `app/integrations/*_client.py` — Supabase REST/RPC wrappers (anon key)

### Week 2 — Class A tools
Implement in order (dependency chain):
1. `identify_customer` / `get_customer`
2. `search_product` / `get_product`
3. `get_price`
4. `check_stock`
5. `get_plafon` / `check_payment` / `get_payment_status`
6. `get_order` / `get_order_history` / `get_order_status` / `get_order_draft`

Each tool:
- Input/output Pydantic model in `app/schemas/`
- Function in `app/tools/*.py`
- Entry in `app/tools/registry.yaml`
- Unit test in `tests/tools/`

### Week 3 — ADK agent
1. `app/agents/prompts.py` — load from `docs/GOODANG_ADK_PROMPT_SPEC.md` version tag
2. `app/agents/root_agent.py` — register Class A tools only
3. `app/agents/callbacks.py` — structured command validation (Pydantic)
4. Smoke test: single-turn identify + search

### Week 4 — Eval harness
1. `evaluation/harness/runner.py` — load YAML cases, run client, score
2. `evaluation/fixtures/*.yaml` — seed data
3. 60 cases across `01_happy_path` … `05_payment` (defer 06–10 to Fase 3)
4. Gate in CI: stub pass until cases exist; strict gate when count ≥ 60

---

## 4. Tool Implementation Notes

| Tool | Activity (Temporal, Fase 3) | Fase 2 implementation |
|:--|:--|:--|
| `identify_customer` | `lookup_customer_activity` | Supabase query `member` by phone/name |
| `search_product` | `search_product_activity` | `pg_trgm` fuzzy on `product.product_name` |
| `check_stock` | `check_stock_activity` | Read `stock.quantity` (no deduct) |
| `get_price` | `get_price_activity` | Active row in `price` for outlet |

**Security:** ADK container env has `SUPABASE_ANON_KEY` only. CI fails if `service_role` grep in `app/agents/` or `app/tools/`.

---

## 5. Eval Case Categories (Fase 2 target: 60)

| Folder | Cases | Focus |
|:--|:--|:--|
| `01_happy_path/` | 10 | Full read-only order inquiry |
| `02_identification/` | 10 | `identify_customer` edge cases |
| `03_product_search/` | 15 | Ambiguous product, not found |
| `04_stock_price/` | 15 | `INSUFFICIENT_STOCK`, `PRICE_NOT_FOUND` |
| `05_payment/` | 10 | Plafon, `INSUFFICIENT_PAYMENT_LIMIT` |

Case YAML schema (`docs/16` §4):

```yaml
id: HP-001
phase: fase2
category: happy_path
input:
  messages:
    - role: user
      content: "Saya Bu Sari, mau pesan beras 10 kg"
expected:
  intent: build_order
  tools_called:
    - identify_customer
    - search_product
  forbidden_tools: []
  min_accuracy: 1.0
```

---

## 6. CI / Quality Gates

| Check | Command | Required |
|:--|:--|:--|
| Contract drift | `check-contract-drift.sh` | ✅ |
| Tool registry | `check-tool-registry-sync.py` | ✅ |
| Schema sync | `check-schema-sync.py` | ✅ |
| Lint | `ruff check app/` | ✅ |
| Types | `mypy app/` | ✅ |
| Unit tests | `pytest tests/` | ✅ |
| Eval | `run_evals.sh` | ✅ (stub OK until 60 cases) |

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|:--|:--|
| ADK API drift | Pin `google-adk` in `pyproject.toml`, re-run eval on bump |
| Supabase RLS blocks reads | Use anon + policies from `docs/14`; integration test with local Supabase |
| Tool name drift | CI registry sync + contract drift |

---

## 8. References

- `docs/9. GOODANG_ADK_IMPLEMENTATION_SPEC.md`
- `docs/3. GOODANG_TOOL_CONTRACT.md`
- `docs/14. GOODANG_SUPABASE_SCHEMA_SPEC.md`
- `docs/16. GOODANG_EVALUATION_HARNESS_SPEC.md`
- `docs/IMPLEMENTATION_CHECKLIST.md` § Fase 2
