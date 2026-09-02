"""ADK test client wrapper — Fase 2."""
from typing import Any


class GoodangTestClient:
    def __init__(self, agent: Any = None, mock_tools: dict | None = None):
        self.agent = agent
        self.mock_tools = mock_tools or {}

    async def run_turn(self, message: str) -> dict[str, Any]:
        # Fase 2: wire google.adk.testing.TestAgent
        return {"message": message, "stub": True}
