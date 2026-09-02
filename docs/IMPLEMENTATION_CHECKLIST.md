# GOODANG IMPLEMENTATION CHECKLIST

**Project:** Goodang Autonomous CS Agent  
**Purpose:** Map README Fase 2–4 milestones → concrete files, gates, and owners  
**Canonical contract:** `docs/0. GOODANG_CONTRACT.md`

---

## How to Use

1. Pick phase doc: `docs/execution/FASE2_MVP.md` | `docs/execution/FASE3_ADOPSI.md` | `docs/execution/FASE4_AI_NATIVE.md`
2. Complete items in order (dependencies noted)
3. Run local gates before PR (see bottom)
4. Update this checklist when items complete (`[x]`)

---

## Fase 2 — MVP / Ekstraksi (Bulan 3–4)

| # | Deliverable | Files / paths | Gate |
|:--|:--|:--|:--|
| 2.1 | Python project bootstrap | `pyproject.toml`, `.env.example`, `app/config.py` | `ruff check`, `mypy` |
| 2.2 | Supabase migrations Fase 1–2 | `supabase/migrations/00_*.sql` … `11_*.sql` | `check-schema-sync.py` |
| 2.3 | Class A read tools (13) | `app/tools/customer_tools.py` … `payment_tools.py` | unit tests per tool |
| 2.4 | Integration clients | `app/integrations/*_client.py` | mock Supabase tests |
| 2.5 | Pydantic schemas | `app/schemas/*.py` | match `docs/0` §10 |
| 2.6 | ADK root agent skeleton | `app/agents/root_agent.py`, `prompts.py` | loads `registry.yaml` |
| 2.7 | Eval harness | `evaluation/harness/*.py` | `run_evals.sh` |
| 2.8 | Eval cases (target 60) | `evaluation/cases/**` | accuracy ≥ 90% |
| 2.9 | Unit tests | `tests/unit/`, `tests/tools/` | pytest green |

**Exit criteria:** 13 Class A tools callable via ADK test client; 60 eval cases pass; CI ruff/mypy/pytest green.

---

## Fase 3 — Adopsi (Bulan 5–8)

| # | Deliverable | Files / paths | Gate |
|:--|:--|:--|:--|
| 3.1 | Class B draft tools (4) | `app/tools/order_tools.py` | draft CRUD tests |
| 3.2 | Class C workflow commands (4) | `app/temporal/client.py` — Updates + StartWorkflow | mock Temporal tests |
| 3.3 | Temporal workflow 19-state | `app/temporal/workflows/order_workflow.py` | workflow unit tests |
| 3.4 | Activities A/B/C/D split | `app/temporal/activities/*.py` | Class D only in worker |
| 3.5 | Telegram edge → queue → ADK | `app/telegram/*.py` + CF Worker (separate repo) | webhook integration test |
| 3.6 | POS_TRANSACTION_LOG lock | migration `09_pos_transaction_log.sql` | trigger test |
| 3.7 | Observability | OTel in `app/main.py`, worker | span export smoke test |
| 3.8 | Eval cases (target 150) | all `evaluation/cases/*` | accuracy ≥ 95%, safety 100% |
| 3.9 | Integration tests | `tests/integration/`, `tests/temporal/` | testcontainers optional |

**Exit criteria:** End-to-end happy path in staging; Class D isolated; eval 150 cases; no `service_role` in ADK image.

---

## Fase 4 — AI Native (Bulan 9–12)

| # | Deliverable | Files / paths | Gate |
|:--|:--|:--|:--|
| 4.1 | Hermes memory | `supabase/migrations/12_agent_memory.sql` | RLS + vector index |
| 4.2 | Prompt A/B via search attr | `app/agents/prompts.py`, workflow attrs | eval by `prompt_version` |
| 4.3 | 9Router model routing | env `ADK_MODEL_ID` + router config | fallback test |
| 4.4 | Temporal Cloud migration | `docs/15` runbook executed | parity test vs self-host |
| 4.5 | Eval regression CI | `.github/workflows/eval.yml` gates | block PR on >2% drop |
| 4.6 | Production observability | dashboards + alerts (`docs/13` §6) | alert dry-run |

**Exit criteria:** Production on Temporal Cloud; Hermes memory live; eval regression in CI; SLO dashboards.

---

## Pre-PR Local Gates

```bash
bash scripts/check-contract-drift.sh
python3 scripts/check-tool-registry-sync.py
python3 scripts/check-schema-sync.py
ruff check app/ scripts/ evaluation/
mypy --ignore-missing-imports app/
pytest tests/ -v
bash evaluation/run_evals.sh
```

---

## Contract Change Protocol

Any new state/tool/error code → update `docs/0` first (version bump in header) → run drift checks → sync mirrors → update `registry.yaml` / migrations → `contract:` commit.
