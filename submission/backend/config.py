import os


class Config:
    DEBUG = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    SECRET_KEY = os.environ.get("SECRET_KEY", "change-me-in-production")
    HOST = os.environ.get("HOST", "0.0.0.0")
    PORT = int(os.environ.get("PORT", 5000))
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "*")
    LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()