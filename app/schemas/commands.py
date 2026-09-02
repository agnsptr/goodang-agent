"""Structured command models — docs/0 §3 Class C, docs/9 security."""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class StructuredCommandBase(BaseModel):
    model_config = ConfigDict(extra="forbid")

    order_id: str = Field(min_length=1)


class ConfirmOrderCommand(StructuredCommandBase):
    command: Literal["confirm_order"] = "confirm_order"
    confirmation_keyword: str = Field(min_length=1)


class CancelOrderCommand(StructuredCommandBase):
    command: Literal["cancel_order"] = "cancel_order"
    reason: str | None = None


class RequestHandoverCommand(StructuredCommandBase):
    command: Literal["request_human_handover"] = "request_human_handover"
    reason: str = Field(min_length=1)


class StartOrderWorkflowCommand(StructuredCommandBase):
    command: Literal["start_order_workflow"] = "start_order_workflow"
    member_id: str = Field(min_length=1)


COMMAND_MODELS: dict[str, type[StructuredCommandBase]] = {
    "confirm_order": ConfirmOrderCommand,
    "cancel_order": CancelOrderCommand,
    "request_human_handover": RequestHandoverCommand,
    "start_order_workflow": StartOrderWorkflowCommand,
}
