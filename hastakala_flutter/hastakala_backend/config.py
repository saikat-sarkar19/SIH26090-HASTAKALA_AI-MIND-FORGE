import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
ENHANCED_DIR = BASE_DIR / "uploads" / "enhanced"
AUDIO_DIR = BASE_DIR / "uploads" / "audio"

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
ENHANCED_DIR.mkdir(parents=True, exist_ok=True)
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

DB_PATH = BASE_DIR / "hastakala.db"

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AQ.Ab8RN6JceOZYN62DyoZidXBQfWNY8dSHbZ_jLHOBN5Wfzkuj0w")

HOST = "0.0.0.0"
PORT = 8000
