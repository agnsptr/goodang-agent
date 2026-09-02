# Goodang Agent — Windows Setup

Panduan setup lingkungan development **Goodang ADK Agent** di Windows 10/11.

**Stack:** Google ADK + FastAPI + Temporal + Supabase  
**Canonical contract:** `docs/0. GOODANG_CONTRACT.md`

---

## Rekomendasi lingkungan

| Opsi | Kapan dipakai |
|------|----------------|
| **WSL2 (Ubuntu)** | Paling stabil untuk script `bash` dan Docker |
| **PowerShell native** | Cukup untuk ADK + Python; gunakan script `scripts/setup-windows.ps1` |

Jika WSL2 tersedia, jalankan langkah yang sama di dalam Ubuntu setelah `git clone`.

---

## Prasyarat

| Tool | Versi | Download |
|------|-------|----------|
| Git | terbaru | https://git-scm.com/download/win |
| Python | **3.11+** (64-bit) | https://www.python.org/downloads/windows/ |
| Docker Desktop | terbaru (opsional) | https://www.docker.com/products/docker-desktop/ |

Saat install Python, centang **Add python.exe to PATH**.

Opsional:
- **WSL2:** `wsl --install` (PowerShell Administrator, lalu restart)
- **ngrok** / **Cloudflare Tunnel** untuk webhook Telegram lokal

---

## Quick start (PowerShell)

Dari root repository:

```powershell
# Izinkan script lokal (sekali per user)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# Jalankan setup otomatis
.\scripts\setup-windows.ps1
```

Opsi:

```powershell
.\scripts\setup-windows.ps1 -SkipDocker          # tanpa Temporal Docker
.\scripts\setup-windows.ps1 -SkipAdk            # tanpa pip install google-adk
.\scripts\setup-windows.ps1 -SkipVerification     # tanpa pytest / drift checks
```

Setelah selesai:

```powershell
.\.venv\Scripts\Activate.ps1
notepad .env    # isi GOOGLE_API_KEY, SUPABASE_*, dll.
adk web         # UI dev ADK (setelah google-adk terpasang)
```

---

## Setup manual (step by step)

### 1. Clone repository

```powershell
cd $HOME\Documents
git clone https://github.com/agnsptr/goodang-agent.git
cd goodang-agent
```

### 2. Virtual environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
```

Jika `Activate.ps1` diblokir:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 3. Install dependencies

**Jika `pyproject.toml` ada** (branch `main` setelah Fase 2 scaffold):

```powershell
pip install -e ".[dev]"
pip install google-adk
```

**Jika belum ada** (legacy spec-only branch):

```powershell
pip install google-adk fastapi "uvicorn[standard]" pydantic pydantic-settings httpx pyyaml pytest ruff mypy temporalio
```

Pin versi ADK sesuai https://adk.dev/get-started/python/

### 4. Environment variables

```powershell
copy .env.example .env
notepad .env
```

Isi minimal untuk ADK lokal:

```env
GOOGLE_API_KEY=your-gemini-api-key
ADK_MODEL_ID=gemini-2.0-flash
ADK_PROMPT_VERSION=v1.0.0
ADK_AGENT_NAME=goodang-cs

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

TEMPORAL_ADDRESS=127.0.0.1:7233
TEMPORAL_NAMESPACE=goodang
```

**Hard rules Goodang:**

- `SUPABASE_SERVICE_ROLE_KEY` **hanya** di `docker/.env` (Temporal worker) — **bukan** di root `.env` / proses ADK
- Class D tools (`docs/0. GOODANG_CONTRACT.md` §3.4) **tidak** didaftarkan di ADK — hanya di Temporal worker

### 5. Jalankan ADK (dev UI)

```powershell
.\.venv\Scripts\Activate.ps1
adk web
```

Buka URL yang muncul di terminal (biasanya `http://localhost:8000`).

### 6. Temporal lokal (Docker Desktop)

```powershell
cd docker
copy .env.example .env
notepad .env   # set TEMPORAL_DB_PASSWORD, SUPABASE_SERVICE_ROLE_KEY, TELEGRAM_BOT_TOKEN
docker compose -f docker-compose.fase1.yml --profile temporal-stack config
docker compose -f docker-compose.fase1.yml --profile temporal-stack up -d
```

Pastikan Docker Desktop berjalan dan WSL2 backend aktif (Settings → General).

### 7. Verifikasi

**PowerShell** (jika `pytest` terpasang):

```powershell
pytest tests/ -v
ruff check app/
```

**Git Bash / WSL** (script bash penuh):

```bash
bash scripts/check-contract-drift.sh
python scripts/check-tool-registry-sync.py
python scripts/check-schema-sync.py
bash evaluation/run_evals.sh
```

---

## Telegram webhook lokal

Windows tidak bisa menerima webhook Telegram tanpa tunnel publik.

```powershell
# Contoh ngrok
ngrok http 8080
```

Arsitektur produksi Goodang: **Cloudflare Workers → Supabase Queue → ADK** (bukan webhook langsung ke laptop). Lihat `docs/13. GOODANG_INFRASTRUCTURE_SPEC.md`.

---

## Cheat sheet

| Task | PowerShell |
|------|------------|
| Aktifkan venv | `.\.venv\Scripts\Activate.ps1` |
| Deaktivasi venv | `deactivate` |
| Install deps | `pip install -e ".[dev]"` |
| ADK dev UI | `adk web` |
| FastAPI (jika ada `app/main.py`) | `uvicorn app.main:app --reload --port 8080` |
| Copy env | `copy .env.example .env` |
| Docker Temporal | `docker compose -f docker/docker-compose.fase1.yml --profile temporal-stack up -d` |

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `python` tidak dikenali | Reinstall Python dengan **Add to PATH** |
| `Activate.ps1` diblokir | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `bash: command not found` | Install Git Bash atau gunakan WSL2 |
| Docker tidak start | Aktifkan virtualization di BIOS; enable WSL2 di Docker Desktop |
| Port sudah dipakai | Ganti port: `uvicorn ... --port 8081` |
| `pip install -e ".[dev]"` gagal | Pastikan `pyproject.toml` ada; atau install paket manual (§3) |
| CRLF / line ending | `git config core.autocrlf true` |

---

## Dokumen terkait

| Doc | Isi |
|-----|-----|
| `docs/9. GOODANG_ADK_IMPLEMENTATION_SPEC.md` | Blueprint implementasi ADK |
| `docs/1. GOODANG_ADK_AGENT_SPECIFICATION.md` | Spesifikasi agent |
| `docs/GOODANG_ADK_PROMPT_SPEC.md` | Struktur prompt |
| `docs/13. GOODANG_INFRASTRUCTURE_SPEC.md` | Infra & Docker topology |
| `docs/0. GOODANG_CONTRACT.md` | Kontrak kanonik (wajib baca) |

---

## Milestone implementasi

1. ADK skeleton + `adk web` jalan  
2. Class A read tools (13)  
3. Class B draft tools  
4. Temporal bridge (Class C Updates)  
5. Confirmation gate (`docs/0` §9)  
6. Class D di worker saja  
7. Telegram E2E  
8. Eval harness (gate ≥90% Fase 2)

Detail: `docs/9` §44 Development Milestones.
