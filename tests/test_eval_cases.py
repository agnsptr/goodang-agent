from pathlib import Path

import yaml


def test_eval_cases_load():
    cases_dir = Path("evaluation/cases")
    files = list(cases_dir.rglob("*.yaml"))
    assert len(files) >= 10
    for f in files:
        data = yaml.safe_load(f.read_text())
        assert "id" in data
        assert "expected" in data
