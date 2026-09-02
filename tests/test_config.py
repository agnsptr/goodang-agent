from app.config import Settings


def test_settings_defaults():
    s = Settings(temporal_namespace="goodang")
    assert s.temporal_namespace == "goodang"
    assert s.adk_agent_name == "goodang-cs"
