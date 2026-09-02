"""Mock Temporal + Supabase for eval harness — docs/16 §3."""
from dataclasses import dataclass, field
from typing import Any


@dataclass
class MockTemporalWorker:
    calls: list = field(default_factory=list)
    workflow_states: dict = field(default_factory=dict)

    async def send_update(self, workflow_id: str, update_name: str, args: dict) -> Any:
        self.calls.append(("update", workflow_id, update_name, args))
        if update_name == "confirm_order":
            return "CONFIRMATION_ACCEPTED"
        if update_name == "cancel_order":
            return "ORDER_CANCELLED"
        if update_name == "request_human_handover":
            return "HANDOVER_CREATED"
        raise ValueError(f"Unknown update: {update_name}")
