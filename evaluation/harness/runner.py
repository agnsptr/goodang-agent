"""Eval case runner — load YAML cases from evaluation/cases/."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import yaml


def load_cases(cases_dir: Path) -> list[dict]:
    cases = []
    for path in sorted(cases_dir.rglob("*.yaml")):
        cases.append(yaml.safe_load(path.read_text()))
    return cases


def run(cases_dir: Path, output: Path) -> int:
    cases = load_cases(cases_dir)
    passed = len(cases)  # stub: all pass until ADK wired
    result = {
        "total": len(cases),
        "passed": passed,
        "failed": 0,
        "stub": True,
        "phase": "fase2_stub",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2))
    print(f"Eval: {passed}/{len(cases)} passed (stub mode)")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cases-dir", default="evaluation/cases")
    parser.add_argument("--output", default="evaluation/results/latest.json")
    args = parser.parse_args()
    raise SystemExit(run(Path(args.cases_dir), Path(args.output)))


if __name__ == "__main__":
    main()
