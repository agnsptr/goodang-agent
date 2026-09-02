import pytest

from app.agents.callbacks import CommandValidationError, validate_structured_command
from app.agents.prompts import PromptNotFoundError, load_system_prompt


def test_validate_structured_command_confirm():
    cmd = validate_structured_command(
        {"command": "confirm_order", "order_id": "ORD-1", "confirmation_keyword": "ya"}
    )
    assert cmd["command"] == "confirm_order"
    assert cmd["confirmation_keyword"] == "YA"


def test_validate_structured_command_rejects_invalid_keyword():
    with pytest.raises(CommandValidationError):
        validate_structured_command(
            {
                "command": "confirm_order",
                "order_id": "ORD-1",
                "confirmation_keyword": "maybe",
            }
        )


def test_validate_structured_command_rejects_non_string_command():
    with pytest.raises(CommandValidationError):
        validate_structured_command(
            {"command": 123, "order_id": "ORD-1", "confirmation_keyword": "ya"}
        )


def test_validate_structured_command_rejects_extra_fields():
    with pytest.raises(CommandValidationError):
        validate_structured_command(
            {
                "command": "confirm_order",
                "order_id": "ORD-1",
                "confirmation_keyword": "ya",
                "injected": True,
            }
        )


def test_load_system_prompt_v1():
    text = load_system_prompt("v1.0.0")
    assert "Class D" in text


def test_load_system_prompt_missing_version():
    with pytest.raises(PromptNotFoundError):
        load_system_prompt("v99.99.99")
