"""Prompt loader — versioned per ADK_PROMPT_VERSION. See docs/GOODANG_ADK_PROMPT_SPEC.md."""
from pathlib import Path

from app.config import settings

_PROMPTS_ROOT = Path(__file__).resolve().parents[2] / "prompts"


class PromptNotFoundError(FileNotFoundError):
    """Raised when requested prompt version is missing."""


def load_system_prompt(version: str | None = None) -> str:
    """Load system prompt for version. Fail closed if file missing."""
    ver = version or settings.adk_prompt_version
    path = _PROMPTS_ROOT / ver / "system.md"
    if not path.is_file():
        raise PromptNotFoundError(
            f"Prompt version {ver!r} not found at {path}. "
            "Add prompts/<version>/system.md or set ADK_PROMPT_VERSION."
        )
    return path.read_text(encoding="utf-8")
