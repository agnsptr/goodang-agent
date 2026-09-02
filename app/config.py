"""Application settings — docs/13 §7 environment contract."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str = ""
    supabase_anon_key: str = ""
    temporal_address: str = "127.0.0.1:7233"
    temporal_namespace: str = "goodang"
    adk_model_id: str = "gemini-2.0-flash"
    adk_prompt_version: str = "v1.0.0"
    adk_agent_name: str = "goodang-cs"
    app_layer_url: str = "http://127.0.0.1:8000"


settings = Settings()
