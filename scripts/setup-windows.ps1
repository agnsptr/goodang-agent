#Requires -Version 5.1
<#
.SYNOPSIS
  Bootstrap Goodang Agent development environment on Windows.

.DESCRIPTION
  Creates a Python venv, installs dependencies, copies .env templates,
  and optionally starts Temporal via Docker Compose.

.EXAMPLE
  .\scripts\setup-windows.ps1

.EXAMPLE
  .\scripts\setup-windows.ps1 -SkipDocker -SkipVerification
#>
[CmdletBinding()]
param(
    [switch]$SkipDocker,
    [switch]$SkipAdk,
    [switch]$SkipVerification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "OK  $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "WARN  $Message" -ForegroundColor Yellow
}

function Assert-LastExitCode([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

function Test-Command([string]$Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PythonCommand {
    foreach ($candidate in @("python", "python3", "py")) {
        if (-not (Test-Command $candidate)) { continue }
        try {
            $versionText = & $candidate -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
            if ($versionText -match '^(\d+)\.(\d+)$') {
                $major = [int]$Matches[1]
                $minor = [int]$Matches[2]
                if ($major -gt 3 -or ($major -eq 3 -and $minor -ge 11)) {
                    return $candidate
                }
            }
        } catch {
            continue
        }
    }
    return $null
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

Write-Step "Goodang Agent - Windows setup"
Write-Host "Repository: $RepoRoot"

# --- Prerequisites ---
Write-Step "Checking prerequisites"

if (-not (Test-Command "git")) {
    Write-Warn "Git not found. Install from https://git-scm.com/download/win"
} else {
    Write-Ok "git $(git --version)"
}

$PythonCmd = Get-PythonCommand
if (-not $PythonCmd) {
    throw "Python 3.11+ not found. Install from https://www.python.org/downloads/windows/ and enable 'Add to PATH'."
}
Write-Ok "$PythonCmd $(& $PythonCmd --version 2>&1)"

if (-not $SkipDocker) {
    if (Test-Command "docker") {
        Write-Ok "docker $(docker --version)"
    } else {
        Write-Warn "Docker not found - skipping Temporal stack. Install Docker Desktop or use -SkipDocker."
        $SkipDocker = $true
    }
}

# --- Virtual environment ---
Write-Step "Creating virtual environment (.venv)"

$VenvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    & $PythonCmd -m venv (Join-Path $RepoRoot ".venv")
    Assert-LastExitCode "python -m venv"
    Write-Ok "Created .venv"
} else {
    Write-Ok ".venv already exists"
}

$VenvPip = Join-Path $RepoRoot ".venv\Scripts\pip.exe"
& $VenvPython -m pip install --upgrade pip --quiet
Assert-LastExitCode "pip upgrade"
Write-Ok "pip upgraded"

# --- Dependencies ---
Write-Step "Installing Python dependencies"

$PyProject = Join-Path $RepoRoot "pyproject.toml"
if (Test-Path $PyProject) {
    & $VenvPip install -e ".[dev]"
    Assert-LastExitCode "pip install -e .[dev]"
    Write-Ok "Installed editable package from pyproject.toml"
} else {
    Write-Warn "pyproject.toml not found - installing baseline packages"
    $Baseline = @(
        "fastapi>=0.110",
        "uvicorn[standard]>=0.27",
        "pydantic>=2.6",
        "pydantic-settings>=2.2",
        "httpx>=0.27",
        "pyyaml>=6.0",
        "temporalio>=1.7.0",
        "pytest>=8.0",
        "pytest-asyncio>=0.23",
        "ruff>=0.4",
        "mypy>=1.9"
    )
    & $VenvPip install @Baseline
    Assert-LastExitCode "pip install baseline"
    Write-Ok "Baseline packages installed"
}

if (-not $SkipAdk) {
    & $VenvPip install "google-adk"
    Assert-LastExitCode "pip install google-adk"
    Write-Ok "google-adk installed"
} else {
    Write-Warn "Skipped google-adk (-SkipAdk)"
}

# --- Environment files ---
Write-Step "Configuring environment files"

$EnvExample = Join-Path $RepoRoot ".env.example"
$EnvFile = Join-Path $RepoRoot ".env"
if ((Test-Path $EnvExample) -and -not (Test-Path $EnvFile)) {
    Copy-Item $EnvExample $EnvFile
    Write-Ok "Created .env from .env.example - edit GOOGLE_API_KEY and SUPABASE_ANON_KEY"
} elseif (Test-Path $EnvFile) {
    Write-Ok ".env already exists (not overwritten)"
} else {
    Write-Warn ".env.example missing - create .env manually"
}

$DockerDir = Join-Path $RepoRoot "docker"
$DockerEnvExample = Join-Path $DockerDir ".env.example"
$DockerEnv = Join-Path $DockerDir ".env"
if ((Test-Path $DockerEnvExample) -and -not (Test-Path $DockerEnv)) {
    Copy-Item $DockerEnvExample $DockerEnv
    Write-Ok "Created docker/.env from docker/.env.example"
    Write-Warn "Edit docker/.env: set TEMPORAL_DB_PASSWORD, SUPABASE_SERVICE_ROLE_KEY, and TELEGRAM_BOT_TOKEN before starting worker stack"
} elseif (-not (Test-Path $DockerEnvExample)) {
    Write-Warn "docker/.env.example not found - set worker credentials manually for Docker"
}

# --- Docker Temporal (optional) ---
if (-not $SkipDocker) {
    Write-Step "Validating Docker Compose (temporal-stack profile)"
    $ComposeFile = Join-Path $DockerDir "docker-compose.fase1.yml"
    if (Test-Path $ComposeFile) {
        Push-Location $DockerDir
        try {
            if (-not (Test-Path $DockerEnv)) {
                @"
TEMPORAL_DB_USER=temporal
TEMPORAL_DB_PASSWORD=change-me-local-dev
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_URL=https://your-project.supabase.co
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
"@ | Set-Content -Path ".env" -Encoding UTF8
                Write-Warn "Created minimal docker/.env - set TEMPORAL_DB_PASSWORD, SUPABASE_SERVICE_ROLE_KEY, and TELEGRAM_BOT_TOKEN before up -d"
            }
            docker compose -f docker-compose.fase1.yml --profile temporal-stack config | Out-Null
            Assert-LastExitCode "docker compose config"
            Write-Ok "docker compose config validated"
            Write-Host "  Start stack: cd docker; docker compose -f docker-compose.fase1.yml --profile temporal-stack up -d"
        } finally {
            Pop-Location
        }
    } else {
        Write-Warn "docker-compose.fase1.yml not found"
    }
}

# --- Verification ---
if (-not $SkipVerification) {
    Write-Step "Running verification"

    $TestsDir = Join-Path $RepoRoot "tests"
    if (Test-Path $TestsDir) {
        $Pytest = Join-Path $RepoRoot ".venv\Scripts\pytest.exe"
        if (Test-Path $Pytest) {
            & $Pytest (Join-Path $TestsDir) -q
            Assert-LastExitCode "pytest"
            Write-Ok "pytest completed"
        }
    } else {
        Write-Warn "tests/ not found - skip pytest"
    }

    $Ruff = Join-Path $RepoRoot ".venv\Scripts\ruff.exe"
    $AppDir = Join-Path $RepoRoot "app"
    if ((Test-Path $Ruff) -and (Test-Path $AppDir)) {
        $PyFiles = Get-ChildItem -Path $AppDir -Recurse -Filter "*.py" -ErrorAction SilentlyContinue
        if ($PyFiles.Count -gt 0) {
            & $Ruff check $AppDir
            Assert-LastExitCode "ruff check"
            Write-Ok "ruff check completed"
        } else {
            Write-Warn "No .py files under app/ yet - skip ruff"
        }
    }

    if (Test-Command "bash") {
        $DriftScript = Join-Path $RepoRoot "scripts\check-contract-drift.sh"
        if (Test-Path $DriftScript) {
            bash $DriftScript
            Assert-LastExitCode "check-contract-drift.sh"
            Write-Ok "contract drift check completed"
        }
    } else {
        Write-Warn "bash not available - run drift checks from Git Bash or WSL"
    }

    $RegistryScript = Join-Path $RepoRoot "scripts\check-tool-registry-sync.py"
    if (Test-Path $RegistryScript) {
        & $VenvPython $RegistryScript
        Assert-LastExitCode "check-tool-registry-sync.py"
        Write-Ok "tool registry sync check completed"
    }
}

# --- Done ---
Write-Step "Setup complete"
Write-Host @"

Next steps:
  1. Activate venv:    .\.venv\Scripts\Activate.ps1
  2. Edit ADK secrets: notepad .env
     - GOOGLE_API_KEY, SUPABASE_URL, SUPABASE_ANON_KEY (no service_role here)
  3. Edit worker secrets: notepad docker\.env
     - TEMPORAL_DB_PASSWORD, SUPABASE_SERVICE_ROLE_KEY, and TELEGRAM_BOT_TOKEN (worker only)
  4. ADK dev UI:       adk web
  5. Full guide:       docs/setup/WINDOWS_SETUP.md

Hard rules:
  - Class D tools (docs/0 section 3.4) only in Temporal worker
  - service_role key never in ADK process
  - Start here: docs/0. GOODANG_CONTRACT.md

"@ -ForegroundColor White
