from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    API_KEY: str = ""
    GOOGLE_MAPS_API_KEY: str = ""
    DIGITALOCEAN_BASE_URL: str = "https://inference.do-ai.run/v1"
    DIGITALOCEAN_MODEL: str = "openai/gpt-5-nano"
    GOOGLE_CLOUD_PROJECT: str = "bulao-hackathon"
    DEMO_MODE: bool = False
    FIRESTORE_EMULATOR_HOST: Optional[str] = None
    LOG_LEVEL: str = "INFO"
    # AWS-specific
    AWS_REGION: str = "us-east-1"
    PORT: int = 8080

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings() # type: ignore
