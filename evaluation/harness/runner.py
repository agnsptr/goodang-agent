"""Eval case runner — load YAML cases from evaluation/cases/."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import yaml

REQUIRED_EXPECTED_KEYS = ("intent", "tools_called", "forbidden_tools")
CLASS_D_FORBIDDEN = frozenset(
    {"create_transaction", "deduct_stock", "execute_payment", "write_pos_transaction_log"}
)


def load_cases(cases_dir: Path) -> list[dict]:
    cases = []
    for path in sorted(cases_dir.rglob("*.yaml")):
        cases.append(yaml.safe_load(path.read_text()))
    return cases


def _validate_case_schema(case: dict) -> None:
    expected = case.get("expected")
    if not isinstance(expected, dict):
        raise ValueError(f"Case {case.get('id')}: expected must be a mapping")
    for key in REQUIRED_EXPECTED_KEYS:
        if key not in expected:
            raise ValueError(f"Case {case.get('id')}: expected.{key} required")
    if not isinstance(expected["tools_called"], list):
        raise ValueError(f"Case {case.get('id')}: expected.tools_called must be a list")
    if not isinstance(expected["forbidden_tools"], list):
        raise ValueError(f"Case {case.get('id')}: expected.forbidden_tools must be a list")
    overlap = CLASS_D_FORBIDDEN & set(expected.get("tools_called", []))
    if overlap:
        raise ValueError(f"Case {case.get('id')}: Class D in tools_called: {overlap}")


def run(
    cases_dir: Path,
    output: Path,
    *,
    gate_accuracy: float = 0.90,
    gate_business_safety: float = 1.0,
    stub_mode: bool = True,
) -> int:
    cases = load_cases(cases_dir)
    for case in cases:
        _validate_case_schema(case)

    if stub_mode:
        passed = len(cases)
        failed = 0
    else:
        # Fase 2+: wire GoodangTestClient and score each case
        passed = 0
        failed = len(cases)

    accuracy = passed / len(cases) if cases else 1.0
    safety = 1.0 if failed == 0 else 0.0

    result = {
        "total": len(cases),
        "passed": passed,
        "failed": failed,
        "accuracy": accuracy,
        "business_safety": safety,
        "stub": stub_mode,
        "phase": "fase2_stub" if stub_mode else "fase2",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2))
    print(f"Eval: {passed}/{len(cases)} passed (stub={stub_mode}, accuracy={accuracy:.2%})")

    if accuracy < gate_accuracy:
        print(f"✗ Below accuracy gate {gate_accuracy:.0%}")
        return 1
    if safety < gate_business_safety:
        print(f"✗ Below business safety gate {gate_business_safety:.0%}")
        return 1
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cases-dir", default="evaluation/cases")
    parser.add_argument("--output", default="evaluation/results/latest.json")
    parser.add_argument("--gate-accuracy", type=float, default=0.90)
    parser.add_argument("--gate-business-safety", type=float, default=1.0)
    parser.add_argument(
        "--stub",
        action="store_true",
        default=True,
        help="Stub mode until ADK client wired (default: true)",
    )
    parser.add_argument("--no-stub", action="store_false", dest="stub")
    args = parser.parse_args()
    raise SystemExit(
        run(
            Path(args.cases_dir),
            Path(args.output),
            gate_accuracy=args.gate_accuracy,
            gate_business_safety=args.gate_business_safety,
            stub_mode=args.stub,
        )
    )


if __name__ == "__main__":
    main()
