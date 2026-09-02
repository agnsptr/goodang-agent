from app.config import Settings


def test_settings_defaults():
    s = Settings()
    assert s.temporal_namespace == "goodang"
