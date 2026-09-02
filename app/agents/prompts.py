"""Prompt loader — versioned per ADK_PROMPT_VERSION. See docs/GOODANG_ADK_PROMPT_SPEC.md."""
from app.config import settings


def load_system_prompt() -> str:
    """Load system prompt for current version."""
    # Fase 2: load from prompts/ or docs mirror by settings.adk_prompt_version
    return f"# Goodang CS Agent prompt {settings.adk_prompt_version}\n"
