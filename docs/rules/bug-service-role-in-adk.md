# Rule: SUPABASE_SERVICE_ROLE_KEY Tidak Boleleh di ADK Container

**Severity:** P0
**Konteks:** Container env, security, secret management
**Referensi:** `docs/12` ADR-003, `docs/13` §7

## Don't

`SUPABASE_SERVICE_ROLE_KEY` **TIDAK BOLEH** ada di env `goodang-adk` atau `goodang-app-layer` container. Service role key bypass RLS dan hanya boleh dipakai oleh `goodang-temporal-worker` untuk Class D writes.

## Do

- `goodang-adk` container: hanya `SUPABASE_ANON_KEY`
- `goodang-app-layer` container: hanya `SUPABASE_ANON_KEY`
- `goodang-temporal-worker` container: `SUPABASE_SERVICE_ROLE_KEY` (untuk Class D activities)
- Cloudflare Workers: `SUPABASE_SERVICE_ROLE_KEY` hanya untuk enqueue + dedup insert (insert-only policy)

## Contoh SALAH

```yaml
# docker/docker-compose.fase1.yml — DILARANG
services:
  goodang-adk:
    environment:
      SUPABASE_URL: ${SUPABASE_URL}
      SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY}
      SUPABASE_SERVICE_ROLE_KEY: ${SUPABASE_SERVICE_ROLE_KEY}  # P0 violation
```

```python
# app/agents/goodang_agent.py — DILARANG
supabase = create_client(url, os.environ["SUPABASE_SERVICE_ROLE_KEY"])  # P0
```

## Contoh BENAR

```yaml
# docker/docker-compose.fase1.yml — BENAR
services:
  goodang-adk:
    environment:
      SUPABASE_URL: ${SUPABASE_URL}
      SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY}
      # NO SUPABASE_SERVICE_ROLE_KEY — ADK pakai anon + RLS

  goodang-temporal-worker:
    environment:
      SUPABASE_URL: ${SUPABASE_URL}
      SUPABASE_SERVICE_ROLE_KEY: ${SUPABASE_SERVICE_ROLE_KEY}  # OK — Class D only
```

```python
# app/agents/goodang_agent.py — BENAR
supabase = create_client(url, os.environ["SUPABASE_ANON_KEY"])  # RLS protect
```

## Deteksi

- CI secret scan (`.github/workflows/ci.yml` job `security-scan`)
- CodeRabbit — review env var usage
- Docker compose config audit
