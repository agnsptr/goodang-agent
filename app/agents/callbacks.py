"""ADK callbacks — validate structured commands before Temporal (Fase 3)."""
from typing import Any

from pydantic import ValidationError

from app.schemas.commands import COMMAND_MODELS


class CommandValidationError(ValueError):
    """Raised when structured command fails Pydantic validation."""


def validate_structured_command(command: dict[str, Any]) -> dict[str, Any]:
    """Validate and normalize structured command — reject unknown fields."""
    cmd_type = command.get("command")
    if not cmd_type or cmd_type not in COMMAND_MODELS:
        raise CommandValidationError(f"Unknown or missing command: {cmd_type!r}")

    try:
        model = COMMAND_MODELS[cmd_type].model_validate(command)
    except ValidationError as exc:
        raise CommandValidationError(str(exc)) from exc

    return model.model_dump()
