from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "FANTASTAR"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql://fantastar:fantastar@localhost:5432/fantastar"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    JWT_SECRET: str = "cambiami-in-produzione"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440

    # API Keys
    FOOTBALL_DATA_ORG_KEY: str = ""
    THESPORTSDB_KEY: str = "3"
    BZZOIRO_KEY: str = ""

    # Serie A
    SERIE_A_SEASON: str = "2025"

    # Media (path per download stemmi/foto; in Docker /app/media)
    MEDIA_ROOT: str = ""

    # Firebase (recupero password OTP SMS)
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"

    # Asta: countdown iniziale e reset a ogni rilancio (Task 08B)
    AUCTION_BID_EXTEND_SECONDS: int = 30
    AUCTION_RESET_SECONDS: int = 15  # Se remaining < questo, reset a 15s

    class Config:
        env_file = ".env"

settings = Settings()
