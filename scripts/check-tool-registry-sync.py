#!/usr/bin/env python3
"""
check-tool-registry-sync.py
Verifikasi sync antara app/tools/registry.yaml dan docs/0. GOODANG_CONTRACT.md §3.

Check yang dijalankan:
1. Parse docs/0 §3.1–§3.4 (canonical tool names per class)
2. Parse app/tools/registry.yaml (ADK tool registry)
3. Compare: setiap tool di registry wajib ada di kontrak, sebaliknya
4. Class D tools (create_transaction, deduct_stock, execute_payment,
   write_pos_transaction_log) TIDAK BOLEH ada di class_a/class_b/class_c
   registry (hanya boleh di class_d_forbidden_in_adk)
5. Forbidden tool names (docs/0 §3.5) tidak boleh muncul di registry

Exit non-zero jika drift terdeteksi.

Usage:
    python3 scripts/check-tool-registry-sync.py
"""
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTRACT_FILE = REPO_ROOT / "docs" / "0. GOODANG_CONTRACT.md"
REGISTRY_FILE = REPO_ROOT / "app" / "tools" / "registry.yaml"

STATUS = 0
ERRORS = []


def log_error(msg: str):
    ERRORS.append(msg)
    global STATUS
    STATUS = 1


def parse_contract_tools():
    """Parse docs/0 §3 untuk extract canonical tool names per class."""
    if not CONTRACT_FILE.exists():
        log_error(f"MISSING contract file: {CONTRACT_FILE}")
        return {}

    content = CONTRACT_FILE.read_text(encoding="utf-8")

    tools = {
        "class_a": [],
        "class_b": [],
        "class_c": [],
        "class_d": [],
        "forbidden": [],
    }

    # Pattern: section header + fenced code block
    # §3.1 Class A, §3.2 Class B, §3.3 Class C, §3.4 Class D, §3.5 Forbidden
    section_patterns = {
        "class_a": r"### 3\.1 Class A.*?```\n(.*?)```",
        "class_b": r"### 3\.2 Class B.*?```\n(.*?)```",
        "class_c": r"### 3\.3 Class C.*?```\n(.*?)```",
        "class_d": r"### 3\.4 Class D.*?```\n(.*?)```",
        "forbidden": r"### 3\.5 Nama yang DILARANG.*?```\n(.*?)```",
    }

    for key, pattern in section_patterns.items():
        m = re.search(pattern, content, re.DOTALL)
        if not m:
            log_error(f"MISSING section §3 for {key} in {CONTRACT_FILE.name}")
            continue
        block = m.group(1)
        # Extract tool names (skip comment lines dan ❌ markers)
        for line in block.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # Forbidden section: format "tool_name  ❌ (gunakan ...)"
            if key == "forbidden":
                m2 = re.match(r"^(\S+)\s+❌", line)
                if m2:
                    tools["forbidden"].append(m2.group(1))
            else:
                # Plain tool name
                m2 = re.match(r"^(\S+)$", line)
                if m2:
                    tools[key].append(m2.group(1))

    return tools


def parse_registry():
    """Parse app/tools/registry.yaml (simple YAML parser, no deps)."""
    if not REGISTRY_FILE.exists():
        log_error(f"MISSING registry file: {REGISTRY_FILE}")
        return {}

    content = REGISTRY_FILE.read_text(encoding="utf-8")

    registry = {
        "class_a": [],
        "class_b": [],
        "class_c": [],
        "class_d_forbidden_in_adk": [],
    }

    current_section = None
    for line in content.splitlines():
        stripped = line.strip()
        # Detect section headers
        if re.match(r"^class_a\s*:", stripped):
            current_section = "class_a"
            continue
        elif re.match(r"^class_b\s*:", stripped):
            current_section = "class_b"
            continue
        elif re.match(r"^class_c\s*:", stripped):
            current_section = "class_c"
            continue
        elif re.match(r"^class_d_forbidden_in_adk\s*:", stripped):
            current_section = "class_d_forbidden_in_adk"
            continue
        elif stripped.startswith(("version:", "#")) or not stripped:
            continue

        # Parse tool entry: "- name: <tool_name>" or "- <tool_name>" (plain)
        if current_section:
            m = re.match(r"^- name:\s*(\S+)", stripped)
            if not m:
                m = re.match(r"^-\s*(\S+)\s*$", stripped)
            if m:
                registry[current_section].append(m.group(1))

    return registry


def main():
    print("===> 1. Parse contract tools (docs/0 §3)")
    contract = parse_contract_tools()
    for key, tools in contract.items():
        print(f"   {key}: {len(tools)} tools")

    print("===> 2. Parse registry (app/tools/registry.yaml)")
    registry = parse_registry()
    for key, tools in registry.items():
        print(f"   {key}: {len(tools)} tools")

    print("===> 3. Compare registry vs contract")

    # Class A: registry wajib == contract
    reg_a = set(registry.get("class_a", []))
    con_a = set(contract.get("class_a", []))
    if reg_a != con_a:
        missing = con_a - reg_a
        extra = reg_a - con_a
        if missing:
            log_error(f"Class A MISSING in registry: {sorted(missing)}")
        if extra:
            log_error(f"Class A EXTRA in registry (not in contract): {sorted(extra)}")

    # Class B: registry wajib == contract
    reg_b = set(registry.get("class_b", []))
    con_b = set(contract.get("class_b", []))
    if reg_b != con_b:
        missing = con_b - reg_b
        extra = reg_b - con_b
        if missing:
            log_error(f"Class B MISSING in registry: {sorted(missing)}")
        if extra:
            log_error(f"Class B EXTRA in registry (not in contract): {sorted(extra)}")

    # Class C: registry wajib == contract
    reg_c = set(registry.get("class_c", []))
    con_c = set(contract.get("class_c", []))
    if reg_c != con_c:
        missing = con_c - reg_c
        extra = reg_c - con_c
        if missing:
            log_error(f"Class C MISSING in registry: {sorted(missing)}")
        if extra:
            log_error(f"Class C EXTRA in registry (not in contract): {sorted(extra)}")

    print("===> 4. Verify Class D tools NOT in ADK registry")
    con_d = set(contract.get("class_d", []))
    all_adk_tools = (
        set(registry.get("class_a", []))
        | set(registry.get("class_b", []))
        | set(registry.get("class_c", []))
    )
    class_d_in_adk = con_d & all_adk_tools
    if class_d_in_adk:
        log_error(
            f"FORBIDDEN: Class D tools found in ADK registry: {sorted(class_d_in_adk)}. "
            f"Class D only allowed in Temporal worker (goodang-temporal-worker)."
        )

    # Class D forbidden list in registry should match contract
    reg_d_forbidden = set(registry.get("class_d_forbidden_in_adk", []))
    if reg_d_forbidden != con_d:
        missing = con_d - reg_d_forbidden
        extra = reg_d_forbidden - con_d
        if missing:
            log_error(f"Class D forbidden list MISSING: {sorted(missing)}")
        if extra:
            log_error(f"Class D forbidden list EXTRA: {sorted(extra)}")

    print("===> 5. Verify forbidden tool names (docs/0 §3.5) not in registry")
    forbidden_names = set(contract.get("forbidden", []))
    forbidden_in_registry = forbidden_names & all_adk_tools
    if forbidden_in_registry:
        log_error(
            f"FORBIDDEN tool names in registry: {sorted(forbidden_in_registry)}. "
            f"See docs/0 §3.5."
        )

    print()
    if STATUS == 0:
        print("✓ Tool registry sync check PASSED")
        sys.exit(0)
    else:
        print("✗ Tool registry sync check FAILED")
        print()
        for err in ERRORS:
            print(f"  - {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
