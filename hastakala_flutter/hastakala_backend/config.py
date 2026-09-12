import os
import tempfile
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

IS_VERCEL = os.getenv("VERCEL") == "1" or "AWS_LAMBDA_FUNCTION_NAME" in os.environ

if IS_VERCEL:
    TEMP_DIR = Path(tempfile.gettempdir())
    UPLOAD_DIR = TEMP_DIR / "uploads"
    ENHANCED_DIR = TEMP_DIR / "uploads" / "enhanced"
    AUDIO_DIR = TEMP_DIR / "uploads" / "audio"
    DB_PATH = TEMP_DIR / "hastakala.db"
else:
    UPLOAD_DIR = BASE_DIR / "uploads"
    ENHANCED_DIR = BASE_DIR / "uploads" / "enhanced"
    AUDIO_DIR = BASE_DIR / "uploads" / "audio"
    DB_PATH = BASE_DIR / "hastakala.db"

try:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    ENHANCED_DIR.mkdir(parents=True, exist_ok=True)
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
except Exception:
    pass

# MongoDB Database Configuration
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb+srv://pinturay2010_db_user:jgIBYlgVRdIRuS8W@cluster0.d7y3jzy.mongodb.net/hastakala_db?retryWrites=true&w=majority")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "hastakala_db")


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AQ.Ab8RN6JceOZYN62DyoZidXBQfWNY8dSHbZ_jLHOBN5Wfzkuj0w")
PHOTOROOM_API_KEY = os.getenv("PHOTOROOM_API_KEY", "sk_pr_default_5d473f437eaf270cf71ab63fa1dfdb58a74c877c")

HOST = "0.0.0.0"
PORT = 8000

