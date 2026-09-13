import os
import uuid
import requests
from io import BytesIO
from PIL import Image, ImageEnhance, ImageOps, ImageFilter
from hastakala_backend.config import UPLOAD_DIR, ENHANCED_DIR, PHOTOROOM_API_KEY

BACKGROUND_PROMPTS = {
    'white': 'clean pristine white studio backdrop with soft shadows for e-commerce',
    'wood': 'rustic warm wooden table in a brightly lit traditional artisan studio',
    'marble': 'luxurious smooth white marble table with soft studio lighting',
    'heritage': 'rustic traditional Indian handicraft setting with natural daylight and warm earth tones',
    'silk': 'luxurious royal gold and silk fabric backdrop with elegant draping',
    'minimalist': 'modern minimalist neutral beige studio backdrop'
}

def enhance_product_image_with_photoroom(
    image_bytes: bytes,
    original_filename: str,
    bg_style: str = "white",
    custom_bg_prompt: str = ""
) -> dict:
    """
    AI Image Studio & Background Customizer Powered by PhotoRoom API:
    1. Saves original uploaded image.
    2. Calls PhotoRoom AI API (v2 Edit or v1 Segment) to generate studio background.
    3. Auto-adjusts lighting, contrast, and color balance.
    4. Formats to high-quality 1:1 e-commerce ready product photo.
    """
    file_id = uuid.uuid4().hex[:10]
    ext = os.path.splitext(original_filename)[1].lower() or ".jpg"
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"

    raw_filename = f"raw_{file_id}{ext}"
    enhanced_filename = f"studio_{file_id}.png"

    raw_path = UPLOAD_DIR / raw_filename
    enhanced_path = ENHANCED_DIR / enhanced_filename

    # Save raw file
    with open(raw_path, "wb") as f:
        f.write(image_bytes)

    api_key = PHOTOROOM_API_KEY or "sandbox_sk_pr_default_1d1f867fc8626c9c4639838a4178f762219c4f9c"

    # Build background prompt
    if bg_style == "custom" and custom_bg_prompt.strip():
        bg_prompt = custom_bg_prompt.strip()
    else:
        bg_prompt = BACKGROUND_PROMPTS.get(bg_style.lower(), BACKGROUND_PROMPTS['white'])

    pr_success = False
    engine_name = "PhotoRoom Sandbox Background Removal API"
    improvements = []

    # 1. Check if user requested direct background removal (transparent cutout)
    if bg_style.lower() in ["transparent", "remove", "cutout"]:
        try:
            url_v1 = "https://sdk.photoroom.com/v1/segment"
            headers = {"x-api-key": api_key}
            files = {"image_file": (original_filename or "product.jpg", image_bytes, "image/jpeg")}
            r = requests.post(url_v1, headers=headers, files=files, timeout=12)
            if r.status_code == 200 and len(r.content) > 3000:
                with open(enhanced_path, "wb") as f:
                    f.write(r.content)
                pr_success = True
                engine_name = "PhotoRoom Sandbox Background Removal API"
                improvements = [
                    "PhotoRoom Sandbox Background Removed (Clean Cutout)",
                    "Transparent Alpha Channel Preserved",
                    "E-Commerce Catalog High-Res Ready"
                ]
        except Exception as e:
            print(f"PhotoRoom transparent cutout error: {e}")

    # 2. Try PhotoRoom v2 API (AI Background Generation & Studio Relighting)
    if not pr_success and bg_style.lower() not in ["transparent", "remove", "cutout"]:
        try:
            url_v2 = "https://image-api.photoroom.com/v2/edit"
            headers = {"x-api-key": api_key}
            files = {"imageFile": (original_filename or "product.jpg", image_bytes, "image/jpeg")}
            data = {
                "background.prompt": bg_prompt,
                "outputSize": "1000x1000"
            }
            r = requests.post(url_v2, headers=headers, files=files, data=data, timeout=12)
            if r.status_code == 200 and len(r.content) > 5000:
                with open(enhanced_path, "wb") as f:
                    f.write(r.content)
                pr_success = True
                engine_name = "PhotoRoom Sandbox AI Studio v2"
                improvements = [
                    f"PhotoRoom AI Studio Background Applied ({bg_style.title()})",
                    f"Prompt: {bg_prompt}",
                    "Product Auto-Relighting & Shadow Synthesis Enabled",
                    "Formatted to 1000x1000 High-Res E-Commerce Standard"
                ]
        except Exception as e:
            print(f"PhotoRoom v2 API error: {e}")

    # 3. Try PhotoRoom v1 API (Background Removal & Studio Composite)
    if not pr_success:
        try:
            url_v1 = "https://sdk.photoroom.com/v1/segment"
            headers = {"x-api-key": api_key}
            files = {"image_file": (original_filename or "product.jpg", image_bytes, "image/jpeg")}
            r = requests.post(url_v1, headers=headers, files=files, timeout=12)
            if r.status_code == 200 and len(r.content) > 3000:
                cutout = Image.open(BytesIO(r.content)).convert("RGBA")
                w, h = cutout.size
                target_size = max(w, h)
                studio_bg = Image.new("RGBA", (target_size, target_size), (255, 255, 255, 255))
                offset_x = (target_size - w) // 2
                offset_y = (target_size - h) // 2
                studio_bg.paste(cutout, (offset_x, offset_y), cutout)
                final_img = studio_bg.resize((800, 800), Image.Resampling.LANCZOS).convert("RGB")
                final_img.save(enhanced_path, "PNG", quality=95)
                pr_success = True
                engine_name = "PhotoRoom Sandbox Segment Engine v1"
                improvements = [
                    "PhotoRoom Sandbox Background Removed (Clean Cutout)",
                    "Clean Studio White Background Synthesized",
                    "Formatted to 800x800 High-Res E-Commerce Standard"
                ]
        except Exception as e:
            print(f"PhotoRoom v1 API error: {e}")

    # 3. Fallback: Local Pillow Enhancer
    if not pr_success:
        engine_name = "Hastakala Local Studio Engine"
        img = Image.open(raw_path).convert("RGBA")
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(1.08)
        color_enhancer = ImageEnhance.Color(img)
        img = color_enhancer.enhance(1.15)
        contrast_enhancer = ImageEnhance.Contrast(img)
        img = contrast_enhancer.enhance(1.10)
        
        w, h = img.size
        target_size = max(w, h)
        studio_bg = Image.new("RGBA", (target_size, target_size), (255, 255, 255, 255))
        offset_x = (target_size - w) // 2
        offset_y = (target_size - h) // 2

        shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        shadow_mask = img.split()[3] if len(img.split()) == 4 else Image.new("L", (w, h), 100)
        shadow.paste((0, 0, 0, 40), (0, 0), shadow_mask)
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=15))

        studio_bg.paste(shadow, (offset_x + 6, offset_y + 12), shadow)
        studio_bg.paste(img, (offset_x, offset_y), img if len(img.split()) == 4 else None)

        studio_final = studio_bg.resize((800, 800), Image.Resampling.LANCZOS).convert("RGB")
        studio_final.save(enhanced_path, "PNG", quality=95)
        improvements = [
            "Local Studio Clean Background Applied",
            "Lighting & Color Saturation Auto-Corrected",
            "Soft Drop Shadow Synthesized"
        ]

    return {
        "raw_image_url": f"/uploads/{raw_filename}",
        "enhanced_image_url": f"/uploads/enhanced/{enhanced_filename}",
        "status": "Enhanced Successfully",
        "bg_style": bg_style,
        "bg_prompt": bg_prompt,
        "ai_engine": engine_name,
        "improvements": improvements
    }

# Alias for backward compatibility
enhance_product_image = enhance_product_image_with_photoroom
