# FASE 4 — AI Native

**Timeline:** Bulan 9–12  
**Goal:** Hermes memory, prompt A/B, Temporal Cloud, eval regression CI, production SLO  
**Exit gate:** Production traffic on managed Temporal; eval blocks PR regression; memory per-project

---

## 1. Scope

### In scope
- `agent_memory` table + Hermes retrieval (`docs/14` §12)
- Prompt versioning + A/B via Temporal search attribute `prompt_version`
- 9Router model routing (`ADK_MODEL_ID` + fallback tiers per BA-ENT-STR-001 §8)
- Temporal Cloud migration from self-host (`docs/15` §7)
- Eval regression gate in CI (compare vs `main` baseline, alert on >2% drop)
- Production dashboards + on-call runbooks
- Knowledge pack for agents: `knowledge/CS_SOP.md`, `PAYMENT_POLICY.md`, etc.

### Out of scope
- Multi-region (unless volume requires — TBD)
- Stock reservation Opsi B (unless race conditions proven in prod)

---

## 2. Hermes Memory Architecture

```text
ADK agent
  ↓ retrieve context
agent_memory (Supabase, pgvector)
  ├─ project_key = "goodang-cs"
  ├─ memory_type = "sop" | "example" | "correction"
  └─ embedding VECTOR(1536)
```

**Rules:**
- Memory stored in Supabase, **not** VPS filesystem (VPS ephemeral)
- Per-project isolation via `project_key` — no cross-project leakage
- RLS: `service_role` write, `authenticated` read for CS dashboard
- Migration: `supabase/migrations/12_agent_memory.sql`

**Fase 4 eval:** add cases for memory retrieval correctness (no PII leak across projects).

---

## 3. Prompt A/B Testing

1. Prompts git-tracked in `prompts/` + `docs/GOODANG_ADK_PROMPT_SPEC.md`
2. Semver tag per release (`ADK_PROMPT_VERSION=v1.2.0`)
3. On workflow start, set search attribute `prompt_version`
4. Eval runner accepts `--prompt-version` flag
5. Compare metrics per version in `evaluation/results/`

**Rollback:** deploy previous prompt version via env var — no code change.

---

## 4. 9Router Model Routing

| Tier | Model | Use case |
|:--|:--|:--|
| Primary | `ADK_MODEL_ID` (env) | Normal classification + tool selection |
| Fallback 1 | Cheaper model | Rate limit / timeout |
| Fallback 2 | Rule-based | Hard failure — escalate `HANDOVER_CS` |

Never hardcode model ID in source. CI grep for `gemini-` in `app/` = warning.

---

## 5. Temporal Cloud Migration

**Trigger:** >1k workflows/day OR ops burden exceeds 4h/week (ADR-007).

### Migration checklist (`docs/15` §7)
1. Export workflow types + task queues config
2. Create Temporal Cloud namespace `goodang`
3. Dual-write period: new workflows to Cloud, drain self-host
4. Update `TEMPORAL_ADDRESS` in worker + ADK client
5. Verify search attributes + visibility queries
6. Decommission VPS-2 Temporal server

**Rollback:** keep self-host docker-compose for 30 days post-migration.

---

## 6. Eval Regression CI

Update `.github/workflows/eval.yml`:

```yaml
- name: Run evaluation harness
  run: |
    bash evaluation/run_evals.sh \
      --baseline evaluation/results/main.json \
      --gate-accuracy 0.95 \
      --gate-business-safety 1.0 \
      --max-regression 0.02
```

**On PR touching `app/agents/` or `prompts/`:** eval required check.

---

## 7. Production SLO

| Metric | Target |
|:--|:--|
| Workflow success rate | ≥ 99% (excl. user cancel) |
| P95 response time (Telegram reply) | < 8s |
| `HANDOVER_CS` rate | < 5% |
| Eval accuracy | ≥ 95% |
| Zero Class D in ADK | 100% |

---

## 8. Security Hardening

- Secret rotation quarterly (Supabase JWT, Telegram bot token)
- Temporal mTLS if self-host retained for DR
- Snyk / dependency scan in CI (optional add-on)
- Prompt injection suite: 15 cases in `09_prompt_injection/` must pass 100%

---

## 9. References

- `docs/12. GOODANG_ADR.md` — ADR-007 (Temporal Cloud), ADR-009 (OTel)
- `docs/15. GOODANG_TEMPORAL_DEPLOYMENT_SPEC.md`
- `docs/16. GOODANG_EVALUATION_HARNESS_SPEC.md`
- `docs/8. GOODANG_AGENT_EVALUATION.md`
- BA-ENT-STR-001 — AI-Driven Business Blueprint §8
- `docs/IMPLEMENTATION_CHECKLIST.md` § Fase 4
