"""JSON + Markdown report generator."""
import json
from pathlib import Path
from typing import Any


def write_report(data: dict[str, Any], path: Path) -> None:
    path.write_text(json.dumps(data, indent=2))
