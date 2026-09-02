from pathlib import Path

import yaml

REQUIRED_EXPECTED_KEYS = ("intent", "tools_called", "forbidden_tools")


def test_eval_cases_load():
    cases_dir = Path("evaluation/cases")
    files = list(cases_dir.rglob("*.yaml"))
    assert len(files) >= 10
    for f in files:
        data = yaml.safe_load(f.read_text())
        assert isinstance(data, dict)
        assert "id" in data
        expected = data.get("expected")
        assert isinstance(expected, dict)
        for key in REQUIRED_EXPECTED_KEYS:
            assert key in expected, f"{f}: missing expected.{key}"
        assert isinstance(expected["tools_called"], list)
        assert isinstance(expected["forbidden_tools"], list)
