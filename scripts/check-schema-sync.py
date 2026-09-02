#!/usr/bin/env python3
"""
check-schema-sync.py
Verifikasi sync antara supabase/migrations/*.sql dan docs/14. GOODANG_SUPABASE_SCHEMA_SPEC.md.

Fase 1: jika belum ada migration files, PASS dengan warning (STRICT=1 untuk fail).
Fase 2+: migration wajib ada dan table names harus match spec.

Usage:
    python3 scripts/check-schema-sync.py
    STRICT=1 python3 scripts/check-schema-sync.py
"""
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SPEC_FILE = REPO_ROOT / "docs" / "14. GOODANG_SUPABASE_SCHEMA_SPEC.md"
MIGRATIONS_DIR = REPO_ROOT / "supabase" / "migrations"

# Tables wajib Fase 1 (agent_memory = Fase 4, optional)
REQUIRED_TABLES_FASE1 = {
    "member",
    "product",
    "price",
    "stock",
    "payment_method",
    "payment",
    "order_draft",
    "order_draft_item",
    "pos_transaction_log",
    "audit_log",
    "telegram_update_dedup",
}

OPTIONAL_TABLES = {"agent_memory"}

STATUS = 0
WARNINGS = []
ERRORS = []


def log_error(msg: str):
    ERRORS.append(msg)
    global STATUS
    STATUS = 1


def log_warning(msg: str):
    WARNINGS.append(msg)


def parse_spec_tables() -> set[str]:
    """Parse CREATE TABLE goodang.<name> dari docs/14."""
    if not SPEC_FILE.exists():
        log_error(f"MISSING spec file: {SPEC_FILE}")
        return set()

    content = SPEC_FILE.read_text(encoding="utf-8")
    pattern = re.compile(r"CREATE TABLE goodang\.(\w+)", re.IGNORECASE)
    return set(pattern.findall(content))


def parse_migration_tables() -> set[str]:
    """Parse CREATE TABLE goodang.<name> dari semua migration SQL."""
    tables: set[str] = set()
    if not MIGRATIONS_DIR.exists():
        return tables

    pattern = re.compile(r"CREATE TABLE (?:IF NOT EXISTS )?goodang\.(\w+)", re.IGNORECASE)
    for sql_file in sorted(MIGRATIONS_DIR.glob("*.sql")):
        content = sql_file.read_text(encoding="utf-8")
        tables.update(pattern.findall(content))
    return tables


def main():
    strict = os.environ.get("STRICT", "0") == "1"

    print("===> 1. Parse tables from docs/14")
    spec_tables = parse_spec_tables()
    print(f"   Spec tables: {len(spec_tables)} — {sorted(spec_tables)}")

    print("===> 2. Parse tables from supabase/migrations/")
    migration_files = list(MIGRATIONS_DIR.glob("*.sql")) if MIGRATIONS_DIR.exists() else []
    migration_tables = parse_migration_tables()
    print(f"   Migration files: {len(migration_files)}")
    print(f"   Migration tables: {len(migration_tables)} — {sorted(migration_tables)}")

    if not migration_files:
        msg = (
            "No migration files in supabase/migrations/ (Fase 1 OK, Fase 2+ wajib). "
            "Lihat docs/14 §14.2 migration order."
        )
        if strict:
            log_error(msg)
        else:
            log_warning(msg)
        print()
        _report(strict)
        return

    print("===> 3. Compare spec vs migrations")

    # Required Fase 1 tables must be in spec
    missing_in_spec = REQUIRED_TABLES_FASE1 - spec_tables
    if missing_in_spec:
        log_error(f"Required tables MISSING in docs/14: {sorted(missing_in_spec)}")

    # Migration tables must exist in spec
    extra_in_migrations = migration_tables - spec_tables - OPTIONAL_TABLES
    if extra_in_migrations:
        log_error(f"Tables in migrations NOT in docs/14: {sorted(extra_in_migrations)}")

    missing_in_migrations = (REQUIRED_TABLES_FASE1 & spec_tables) - migration_tables
    if missing_in_migrations:
        log_error(f"Required tables MISSING in migrations: {sorted(missing_in_migrations)}")

    print()
    _report(strict)


def _report(strict: bool):
    if WARNINGS:
        for w in WARNINGS:
            print(f"⚠️  {w}")
    if STATUS == 0:
        print("✓ Schema sync check PASSED")
        sys.exit(0)
    else:
        print("✗ Schema sync check FAILED")
        for e in ERRORS:
            print(f"  - {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
