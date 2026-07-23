from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Analytics Service"
    database_url: str = "postgresql://localhost/analytics_db"
    redis_url: str = "redis://localhost:6379"
    secret_key: str = "super-secret-analytics-key"

    class Config:
        env_file = ".env"

settings = Settings()
