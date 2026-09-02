"""Mock Temporal + Supabase for eval harness — docs/16 §3."""
from dataclasses import dataclass, field
from typing import Any

from app.schemas.commands import CANONICAL_CONFIRM_KEYWORDS

WAITING_CONFIRMATION = "WAITING_CONFIRMATION"


@dataclass
class MockTemporalWorker:
    calls: list = field(default_factory=list)
    workflow_states: dict = field(default_factory=dict)

    async def send_update(self, workflow_id: str, update_name: str, args: dict) -> Any:
        self.calls.append(("update", workflow_id, update_name, args))
        state = self.workflow_states.get(workflow_id, "NEW")

        if update_name == "confirm_order":
            if state != WAITING_CONFIRMATION:
                raise ValueError(f"CONFIRMATION_REQUIRED: state={state}")
            raw = args.get("confirmation_keyword") or args.get("keyword") or ""
            keyword = raw.strip().upper()
            if keyword not in CANONICAL_CONFIRM_KEYWORDS:
                raise ValueError("CONFIRMATION_INVALID: keyword not in canonical set")
            self.workflow_states[workflow_id] = "CONFIRMED"
            return "CONFIRMATION_ACCEPTED"

        if update_name == "cancel_order":
            self.workflow_states[workflow_id] = "CANCELLED"
            return "ORDER_CANCELLED"

        if update_name == "request_human_handover":
            self.workflow_states[workflow_id] = "HANDOVER_CS"
            return "HANDOVER_CREATED"

        raise ValueError(f"Unknown update: {update_name}")
