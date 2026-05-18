from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    GEMINI_API_KEY: str
    GROQ_API_KEY: Optional[str] = None
    GOOGLE_CLOUD_PROJECT: str = "bulao-hackathon"
    DEMO_MODE: bool = False
    FIRESTORE_EMULATOR_HOST: Optional[str] = None
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings() # type: ignore
