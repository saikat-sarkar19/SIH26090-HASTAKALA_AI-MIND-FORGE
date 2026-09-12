from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import json
import os

from hastakala_backend.config import UPLOAD_DIR, ENHANCED_DIR, AUDIO_DIR, HOST, PORT
from hastakala_backend.database import init_db, get_db_connection
from hastakala_backend.services.image_service import enhance_product_image
from hastakala_backend.services.catalog_service import generate_catalog_from_voice_or_text
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
    language: Optional[str] = "Hindi"

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

class AssistantRequest(BaseModel):
    query: str
    language: Optional[str] = "Hindi"


# --- Routes ---

@app.get("/")
def root():
    return {
        "status": "online",
        "app": "Hastakala AI Business Manager Backend",
        "version": "1.0.0",
        "documentation": "/docs"
    }

@app.get("/api/dashboard/stats")
def get_dashboard_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) as total_products FROM products")
    total_products = cursor.fetchone()["total_products"]

    cursor.execute("SELECT COUNT(*) as total_enquiries FROM enquiries")
    total_enquiries = cursor.fetchone()["total_enquiries"]

    cursor.execute("SELECT COUNT(*) as total_buyers FROM buyers")
    total_buyers = cursor.fetchone()["total_buyers"]
    conn.close()

    return {
        "total_products": total_products,
        "total_enquiries": total_enquiries,
        "total_buyers": total_buyers,
        "ai_opportunity": {
            "title": "Your handloom products are trending",
            "subtitle": "Add 2 more designs this week to attract more GeM & Shilp Samagam buyers.",
            "recommendation": "High demand detected for Handwoven Sarees and Bamboo Craft."
        }
    }

@app.post("/api/image/enhance")
async def enhance_image_endpoint(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    contents = await file.read()
    result = enhance_product_image(contents, file.filename)
    return result

@app.post("/api/catalog/generate")
def generate_catalog_endpoint(req: CatalogRequest):
    result = generate_catalog_from_voice_or_text(
        voice_text=req.voice_text,
        language=req.language
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
def get_products():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.post("/api/products")
def create_product(product: ProductCreate):
    conn = get_db_connection()
    cursor = conn.cursor()
    now_str = datetime.now().isoformat()
    cursor.execute("""
    INSERT INTO products (artisan_id, title, description_en, description_hi, category, materials, tags, price_retail, price_wholesale, min_price, material_cost, labor_cost, production_days, raw_image_url, enhanced_image_url, status, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1, product.title, product.description_en, product.description_hi,
        product.category, product.materials, product.tags,
        product.price_retail, product.price_wholesale, product.min_price,
        product.material_cost, product.labor_cost, product.production_days or 2,
        product.raw_image_url or "", product.enhanced_image_url or "",
        "Published", now_str
    ))
    conn.commit()
    new_id = cursor.lastrowid
    conn.close()

    return {"status": "success", "id": new_id, "message": "Product published successfully"}

@app.get("/api/products/{product_id}")
def get_product_detail(product_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Product not found")
    return dict(row)

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM products WHERE id = ?", (product_id,))
    conn.commit()
    conn.close()
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("hastakala_backend.main:app", host=HOST, port=PORT, reload=True)
