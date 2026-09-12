from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import json
import os

from hastakala_backend.config import UPLOAD_DIR, ENHANCED_DIR, AUDIO_DIR, HOST, PORT
from hastakala_backend.database import (
    init_db, get_db_info, connect_mongodb,
    db_get_dashboard_stats, db_get_all_products, db_get_product_by_id,
    db_create_product, db_delete_product, db_register_artisan, db_login_artisan, db_update_artisan_profile,
    db_get_due_orders
)
from hastakala_backend.services.image_service import enhance_product_image
from hastakala_backend.services.catalog_service import generate_catalog_from_voice_or_text, translate_regional_text
from hastakala_backend.services.pricing_service import calculate_dynamic_pricing
from hastakala_backend.services.assistant_service import chat_with_assistant
from hastakala_backend.services.buyer_service import get_verified_buyers, get_product_enquiries

# Initialize Database
init_db()

app = FastAPI(
    title="Hastakala AI Backend API",
    description="Backend architecture for Hastakala - AI-Powered Business Manager for Traditional Artisans",
    version="1.0.0"
)

# Enable CORS for Flutter mobile & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Static Directories for serving uploaded and enhanced images
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


# --- Models ---
class CatalogRequest(BaseModel):
    voice_text: Optional[str] = ""
    language: Optional[str] = "Auto-Detect"
    image_url: Optional[str] = ""

class TranslateRequest(BaseModel):
    text: str
    source_lang: Optional[str] = "auto"
    target_lang: Optional[str] = "en"

class PricingRequest(BaseModel):
    category: str
    materials: Optional[str] = ""
    raw_material_cost: Optional[float] = 0.0
    labor_hours: Optional[float] = 8.0
    labor_rate_per_hour: Optional[float] = 100.0
    custom_margin_pct: Optional[float] = 25.0

class ProductCreate(BaseModel):
    title: str
    description_en: str
    description_hi: str
    category: str
    materials: str
    tags: str
    price_retail: float
    price_wholesale: float
    min_price: float
    material_cost: float
    labor_cost: float
    production_days: Optional[int] = 2
    raw_image_url: Optional[str] = ""
    enhanced_image_url: Optional[str] = ""
    artisan_id: Optional[int] = None
    artisan_username: Optional[str] = None

class AssistantRequest(BaseModel):
    query: str
    language: Optional[str] = "Hindi"

class MongoConnectRequest(BaseModel):
    mongodb_uri: str

class RegisterRequest(BaseModel):
    full_name: str
    username: str
    phone: str
    gender: Optional[str] = "Male"
    craft_type: Optional[str] = "Handloom & Handicrafts"
    address: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

class ProfileUpdateRequest(BaseModel):
    username: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    gender: Optional[str] = None
    craft_type: Optional[str] = None
    location: Optional[str] = None
    profile_picture: Optional[str] = None


# --- Routes ---

@app.get("/")
def root():
    return {
        "status": "online",
        "app": "Hastakala AI Business Manager Backend",
        "database": get_db_info(),
        "version": "1.0.0",
        "documentation": "/docs"
    }

@app.post("/api/auth/register")
def register_artisan_endpoint(req: RegisterRequest):
    try:
        artisan = db_register_artisan(req.model_dump())
        return {"status": "success", "artisan": artisan, "message": "Account created successfully!"}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@app.post("/api/auth/login")
def login_artisan_endpoint(req: LoginRequest):
    artisan = db_login_artisan(req.username, req.password)
    if not artisan:
        raise HTTPException(status_code=401, detail="Invalid username or password. Please check your credentials.")
    return {"status": "success", "artisan": artisan, "message": "Login successful!"}

@app.post("/api/auth/update_profile")
def update_artisan_profile_endpoint(req: ProfileUpdateRequest):
    try:
        updated_artisan = db_update_artisan_profile(req.model_dump())
        return {"status": "success", "artisan": updated_artisan, "message": "Profile updated successfully!"}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")

@app.get("/api/database/status")
def database_status():
    return get_db_info()

@app.post("/api/database/connect")
def connect_database(req: MongoConnectRequest):
    try:
        connect_mongodb(req.mongodb_uri)
        info = get_db_info()
        return {"status": "success", "message": "Successfully connected to MongoDB", "info": info}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to connect to MongoDB: {str(e)}")

@app.get("/api/dashboard/stats")
def get_dashboard_stats():
    stats = db_get_dashboard_stats()
    return {
        "total_products": stats["total_products"],
        "total_enquiries": stats["total_enquiries"],
        "total_buyers": stats["total_buyers"],
        "db_type": get_db_info()["db_type"],
        "ai_opportunity": {
            "title": "Your handloom products are trending",
            "subtitle": "Add 2 more designs this week to attract more GeM & Shilp Samagam buyers.",
            "recommendation": "High demand detected for Handwoven Sarees and Bamboo Craft."
        }
    }

@app.post("/api/image/enhance")
async def enhance_image_endpoint(
    file: UploadFile = File(...),
    bg_style: Optional[str] = Form("white"),
    bg_prompt: Optional[str] = Form("")
):
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    contents = await file.read()
    result = enhance_product_image(contents, file.filename, bg_style=bg_style or "white", custom_bg_prompt=bg_prompt or "")
    return result

@app.post("/api/translate")
def translate_endpoint(req: TranslateRequest):
    return translate_regional_text(req.text, source_lang=req.source_lang or "auto", target_lang=req.target_lang or "en")

@app.post("/api/catalog/generate")
def generate_catalog_endpoint(req: CatalogRequest):
    result = generate_catalog_from_voice_or_text(
        voice_text=req.voice_text,
        language=req.language,
        image_url=req.image_url or ""
    )
    return result

@app.post("/api/catalog/generate_audio")
async def generate_catalog_audio_endpoint(file: UploadFile = File(...), language: Optional[str] = Form("Hindi")):
    contents = await file.read()
    result = generate_catalog_from_voice_or_text(
        audio_bytes=contents,
        audio_filename=file.filename,
        language=language
    )
    return result

@app.post("/api/pricing/calculate")
def calculate_pricing_endpoint(req: PricingRequest):
    result = calculate_dynamic_pricing(
        category=req.category,
        materials=req.materials,
        raw_material_cost=req.raw_material_cost,
        labor_hours=req.labor_hours,
        labor_rate_per_hour=req.labor_rate_per_hour,
        custom_margin_pct=req.custom_margin_pct
    )
    return result

@app.get("/api/products")
def get_products(
    artisan_id: Optional[int] = Query(None),
    artisan_username: Optional[str] = Query(None)
):
    return db_get_all_products(artisan_id=artisan_id, artisan_username=artisan_username)

@app.post("/api/products")
def create_product(product: ProductCreate):
    new_id = db_create_product(product.model_dump())
    return {"status": "success", "id": new_id, "message": "Product published successfully"}

@app.get("/api/products/{product_id}")
def get_product_detail(product_id: int):
    prod = db_get_product_by_id(product_id)
    if not prod:
        raise HTTPException(status_code=404, detail="Product not found")
    return prod

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    success = db_delete_product(product_id)
    if not success:
        raise HTTPException(status_code=404, detail="Product not found or delete failed")
    return {"status": "success", "message": "Product deleted"}

@app.post("/api/assistant/chat")
def chat_assistant_endpoint(req: AssistantRequest):
    return chat_with_assistant(query=req.query, language=req.language or "Hindi")

@app.get("/api/buyers")
def list_buyers(category: Optional[str] = Query(None)):
    return get_verified_buyers(category_filter=category or "")

@app.get("/api/enquiries")
def list_enquiries(product_id: Optional[int] = Query(None)):
    return get_product_enquiries(product_id=product_id)

@app.get("/api/orders")
def get_due_orders(
    artisan_id: Optional[int] = Query(None),
    artisan_username: Optional[str] = Query(None)
):
    return db_get_due_orders(artisan_id=artisan_id, artisan_username=artisan_username)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("hastakala_backend.main:app", host=HOST, port=PORT, reload=True)

