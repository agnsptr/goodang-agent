"""Shared Pydantic types — docs/0 §10."""
from pydantic import BaseModel


class ToolResult(BaseModel):
    outcome: str
    error_code: str | None = None
