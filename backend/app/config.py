"""Configurações da aplicação carregadas via variáveis de ambiente."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    backend_host: str = "0.0.0.0"
    backend_port: int = 8000
    sqlite_db_path: str = "./data/dtblocks.db"

    max_participants_per_session: int = 5
    field_lock_lease_seconds: int = 30
    batch_flush_interval_ms: int = 1500

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
