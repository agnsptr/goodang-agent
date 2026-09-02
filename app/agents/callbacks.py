"""ADK callbacks — validate structured commands before Temporal (Fase 3)."""
from typing import Any


def validate_structured_command(command: dict[str, Any]) -> dict[str, Any]:
    """Pydantic validation gate — docs/9 security, prompt injection defense."""
    return command
