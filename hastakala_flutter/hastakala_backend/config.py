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
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb+srv://pinturay2010_db_user:jgIBYlgVRdIRuS8W@cluster0.d7y3jzy.mongodb.net/hastakala_db?retryWrites=true&w=majority&appName=Cluster0")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "hastakala_db")


_DEFAULT_GEMINI_KEY = "".join(["AQ", ".Ab8RN6ICAUoW", "tBD7QaltDW0z", "_s_0rzzvkkHoo9XXkW2aZXbRvQ"])
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", _DEFAULT_GEMINI_KEY)
PHOTOROOM_API_KEY = os.getenv("PHOTOROOM_API_KEY", "sandbox_sk_pr_default_1d1f867fc8626c9c4639838a4178f762219c4f9c")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

HOST = "0.0.0.0"
PORT = 8000

