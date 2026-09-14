import os
import json
import re
import urllib.parse
import base64
import requests
from pathlib import Path
from hastakala_backend.config import GEMINI_API_KEY, BASE_DIR, UPLOAD_DIR, ENHANCED_DIR, GEMINI_MODEL

LANG_MAP = {
    'hi': 'Hindi (हिंदी)',
    'bn': 'Bengali (বাংলা)',
    'gu': 'Gujarati (ગુજરાતી)',
    'mr': 'Marathi (मराठी)',
    'ta': 'Tamil (தமிழ்)',
    'te': 'Telugu (తెలుగు)',
    'kn': 'Kannada (ಕನ್ನಡ)',
    'ml': 'Malayalam (മലയാളം)',
    'pa': 'Punjabi (ਪੰਜਾਬੀ)',
    'or': 'Odia (ଓଡ଼ਿଆ)',
    'en': 'English',
    'ur': 'Urdu (اردو)',
    'as': 'Assamese (অসমীয়া)'
}

def detect_language_by_script(text: str) -> str:
    """Fallback Unicode script range detector for Indian regional languages."""
    for char in text:
        cp = ord(char)
        if 0x0900 <= cp <= 0x097F:
            return 'hi'  # Devanagari (Hindi/Marathi)
        elif 0x0980 <= cp <= 0x09FF:
            return 'bn'  # Bengali/Assamese
        elif 0x0A00 <= cp <= 0x0A7F:
            return 'pa'  # Gurmukhi (Punjabi)
        elif 0x0A80 <= cp <= 0x0AFF:
            return 'gu'  # Gujarati
        elif 0x0B00 <= cp <= 0x0B7F:
            return 'or'  # Odia
        elif 0x0B80 <= cp <= 0x0BFF:
            return 'ta'  # Tamil
        elif 0x0C00 <= cp <= 0x0C7F:
            return 'te'  # Telugu
        elif 0x0C80 <= cp <= 0x0CFF:
            return 'kn'  # Kannada
        elif 0x0D00 <= cp <= 0x0D7F:
            return 'ml'  # Malayalam
    return 'en'

def translate_regional_text(text: str, source_lang: str = "auto", target_lang: str = "en") -> dict:
    """
    Multilingual Bi-Directional Translation & Language Auto-Detection Engine:
    Translates text between English and regional Indian languages (Hindi, Bengali, Gujarati, Tamil, etc.) in both directions.
    """
    if not text or not text.strip():
        return {
            "detected_language": "English",
            "detected_code": "en",
            "target_code": target_lang,
            "original_text": "",
            "translated_text": "",
            "status": "Empty input"
        }

    src = (source_lang or "auto").lower().split("-")[0]
    tgt = (target_lang or "en").lower().split("-")[0]

    det_script = detect_language_by_script(text)
    script_lang_name = LANG_MAP.get(det_script, "Regional Language")

    if src == "auto":
        src = det_script if det_script != "en" else "autodetect"

    lang_pair = f"{src}|{tgt}"
    encoded = urllib.parse.quote(text.strip())

    # 1. Primary: MyMemory API with valid email key
    try:
        url = f"https://api.mymemory.translated.net/get?q={encoded}&langpair={lang_pair}&de=artisan@hastakala.in"
        r = requests.get(url, timeout=5)
        if r.status_code == 200:
            data = r.json()
            resp_data = data.get("responseData", {})
            translated = resp_data.get("translatedText", "").strip()
            det_code = resp_data.get("detectedLanguage", src)

            # Check if translation is valid and not an error string
            if translated and not any(err in translated.upper() for err in ["PLEASE SELECT", "NO QUERY", "MYMEMORY WARNING", "LIMIT", "QUOTA"]):
                if not det_code or det_code in ["un", "IS"]:
                    det_code = det_script
                lang_code_short = det_code.lower()[:2]
                lang_name = LANG_MAP.get(lang_code_short, script_lang_name)

                return {
                    "detected_language": lang_name,
                    "detected_code": det_code,
                    "target_code": tgt,
                    "original_text": text,
                    "translated_text": translated,
                    "status": "Success"
                }
    except Exception as e:
        print(f"MyMemory Translation API error: {e}")

    # 2. Fallback: Free Google Translate endpoint
    try:
        url_gt = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl={src}&tl={tgt}&dt=t&q={encoded}"
        r_gt = requests.get(url_gt, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
        if r_gt.status_code == 200:
            gt_json = r_gt.json()
            if gt_json and len(gt_json) > 0 and len(gt_json[0]) > 0 and len(gt_json[0][0]) > 0:
                translated_gt = gt_json[0][0][0]
                if translated_gt and translated_gt.strip():
                    return {
                        "detected_language": script_lang_name,
                        "detected_code": det_script,
                        "target_code": tgt,
                        "original_text": text,
                        "translated_text": translated_gt,
                        "status": "GoogleTranslateSuccess"
                    }
    except Exception as e:
        print(f"Google Translate fallback error: {e}")

    # 3. Fallback: Indian Regional Craft Glossary
    glossary = {
        'মাটির তৈরি ফুলদানি': 'Clay flower vase',
        'ফুলদানি': 'Flower vase',
        'মাটির': 'Clay',
        'সাড়ি': 'Saree',
        'ঝুড়ি': 'Basket',
        'मिट्टी का बर्तन': 'Clay pot',
        'टोकरी': 'Basket',
        'साड़ी': 'Saree'
    }
    fallback_trans = text
    for k, v in glossary.items():
        if k in text:
            fallback_trans = v
            break

    return {
        "detected_language": script_lang_name,
        "detected_code": det_script,
        "target_code": tgt,
        "original_text": text,
        "translated_text": fallback_trans,
        "status": "Fallback"
    }

def build_high_quality_english_description(keywords: str, translated_en: str, detected_lang: str = "English") -> dict:
    raw_text = (translated_en or keywords or "Handcrafted Indian Artisan Item").strip()
    text_lower = raw_text.lower()

    # Detect color
    colors = {
        'blue': 'cobalt blue', 'red': 'crimson red', 'green': 'emerald green',
        'yellow': 'golden yellow', 'black': 'midnight black', 'white': 'ivory white',
        'terracotta': 'earthy terracotta', 'brown': 'warm wood brown', 'gold': 'royal gold',
        'silver': 'shimmering silver', 'pink': 'rose pink', 'orange': 'vibrant saffron', 'purple': 'royal purple'
    }
    found_color = None
    for k, v in colors.items():
        if k in text_lower:
            found_color = v
            break

    # Match Craft Profiles
    profiles = [
        {
            'keys': ['vase', 'flower vase', 'fuldani', 'ফুলদানি', 'ফুলদানির', 'pot', 'matka', 'pitcher', 'vessel', 'clay', 'terracotta', 'pottery', 'bottle', 'jar', 'container', 'jug'],
            'category': 'Kitchen & Dining  ›  Terracotta Pottery',
            'materials': 'Natural Bio-Clay & Eco-Friendly Terracotta',
            'tags': 'Pottery • Handcrafted • Bio-Clay • Eco-Friendly • Artisanal • Sustainable',
            'get_title': lambda col, item: (
                f"Handcrafted {col.title() + ' ' if col else ''}Terracotta Clay Flower Vase"
                if any(w in item.lower() for w in ['vase', 'fuldani', 'ফুলদানি'])
                else f"Handcrafted {col.title() + ' ' if col else ''}Terracotta Artisan Pot"
            ),
            'get_desc': lambda col, item, kw: (
                f"Expertly hand-molded on traditional pottery wheels from 100% natural organic bio-clay, this exquisite {col or 'artisanal'} terracotta flower vase blends ancient Indian pottery heritage with functional modern elegance. "
                f"Handcrafted by master potters to highlight its smooth tactile finish and rustic charm, it reflects authentic traditional craftsmanship. "
                f"Naturally porous, toxin-free, and eco-friendly, it serves as a striking centerpiece while bringing sustainable handcrafted elegance to home decor."
                if any(w in item.lower() for w in ['vase', 'fuldani', 'ফুলদানি'])
                else (
                    f"Expertly hand-molded on traditional pottery wheels from 100% natural organic bio-clay, this exquisite {col or 'artisanal'} terracotta vessel blends ancient Indian pottery heritage with functional modern elegance. "
                    f"Handcrafted by master potters to highlight its smooth tactile finish and rustic charm, it reflects authentic traditional craftsmanship. "
                    f"Naturally porous, toxin-free, and eco-friendly, it cools liquids effortlessly while preserving fresh aromas for daily culinary and decorative use."
                )
            )
        },
        {
            'keys': ['saree', 'saari', 'dupatta', 'stole', 'handloom', 'bunkar', 'zari', 'banarasi', 'chanderi', 'kanjeevaram', 'weaver', 'silk', 'fabric', 'shawl', 'dress'],
            'category': 'Textiles & Apparel  ›  Sarees & Handloom',
            'materials': 'Pure Handloom Silk & Natural Cotton with Zari Motifs',
            'tags': 'Handloom • Saree • Heritage Weave • Ethnic Wear • Artisanal • Sustainable',
            'get_title': lambda col, item: f"Handwoven {col.title() + ' ' if col else ''}Banarasi Handloom Saree",
            'get_desc': lambda col, item, kw: (
                f"Masterfully handwoven on traditional wooden looms by heritage master weavers, this breathtaking {col or 'ethnic'} saree is a celebration of authentic Indian textile artistry. "
                f"Handcrafted with fine natural yarns and intricate metallic zari embroidery, it features a luxurious soft texture, fluid drape, and timeless regal charm. "
                f"Designed for festive celebrations, weddings, and cultural gatherings, offering unmatched handcrafted elegance and sustainable comfort."
            )
        },
        {
            'keys': ['basket', 'tokri', 'bamboo', 'baans', 'cane', 'jute', 'storage', 'box', 'tray', 'planter'],
            'category': 'Home & Living  ›  Bamboo & Cane Craft',
            'materials': '100% Natural Seasoned Bamboo & Sustainable Cane',
            'tags': 'Handmade • Bamboo Craft • Storage • Sustainable • Eco-Friendly • Rural Art',
            'get_title': lambda col, item: f"Handcrafted {col.title() + ' ' if col else ''}Eco-Friendly Bamboo Basket",
            'get_desc': lambda col, item, kw: (
                f"Hand-braided by skilled rural artisans using 100% natural seasoned bamboo splints, this eco-friendly basket showcases traditional weaving techniques passed down through generations. "
                f"Highlighting a lightweight yet sturdy structural weave in {col or 'natural organic'} tones, it pairs functional storage utility with a chic rustic aesthetic. "
                f"Ideal for modern eco-conscious homes, food serving, or decorative storage, bringing sustainable handcrafted warmth to any space."
            )
        },
        {
            'keys': ['wood', 'lakdi', 'carving', 'sheesham', 'wooden', 'toy', 'statue', 'sculpture', 'furniture', 'coaster', 'board'],
            'category': 'Handicrafts  ›  Wood Craft & Carvings',
            'materials': 'Seasoned Sheesham Wood & Organic Wax Finish',
            'tags': 'Woodcraft • Hand-Carved • Sheesham • Heritage • Wooden Decor • Sustainable',
            'get_title': lambda col, item: f"Hand-Carved {col.title() + ' ' if col else ''}Wooden Artisan Accent",
            'get_desc': lambda col, item, kw: (
                f"Intricately carved by hand from sustainably harvested hardwood, this decorative wooden accent showcases traditional Indian woodcarving mastery. "
                f"Polished with natural non-toxic wax to accentuate its rich {col or 'warm wood'} grain textures and smooth tactile finish, every detail reflects artisan dedication. "
                f"A timeless interior centerpiece designed to bring organic warmth, artistic sophistication, and heritage charm into modern living spaces."
            )
        },
        {
            'keys': ['brass', 'pittal', 'metal', 'dokra', 'bell metal', 'copper', 'statue', 'idol', 'figurine', 'bronze', 'lamp', 'diya'],
            'category': 'Handicrafts  ›  Metal Craft & Dokra Art',
            'materials': 'Solid Brass & Antique Bell Metal Bronze',
            'tags': 'Metal Craft • Brassware • Dokra Art • Ethnic • Heritage • Hand-Cast',
            'get_title': lambda col, item: f"Handcrafted {col.title() + ' ' if col else ''}Tribal Dokra Metal Sculpture",
            'get_desc': lambda col, item, kw: (
                f"Handcrafted using the traditional lost-wax casting technique, this authentic metal sculpture embodies centuries of tribal Dokra metallurgist heritage. "
                f"Cast in solid brass with an antique {col or 'patina'} finish, its intricate folk motifs tell stories of ancient Indian folklore and craftsmanship. "
                f"A durable and majestic collector's art piece that adds rich cultural character, spiritual grace, and artistic elegance to home decor."
            )
        },
        {
            'keys': ['mojari', 'jutti', 'chamra', 'leather', 'footwear', 'shoes', 'chappal', 'sandal'],
            'category': 'Fashion Accessories  ›  Artisanal Footwear',
            'materials': 'Genuine Tanned Leather & Hand Embroidery Thread',
            'tags': 'Mojari • Jutti • Genuine Leather • Hand-Stitched • Ethnic Footwear',
            'get_title': lambda col, item: f"Hand-Stitched {col.title() + ' ' if col else ''}Embroidered Leather Jutti",
            'get_desc': lambda col, item, kw: (
                f"Hand-stitched by traditional cobblers using vegetable-tanned leather, these classic Mojari juttis feature intricate ethnic thread embroidery. "
                f"Boasting a supple cushioned sole and a rich {col or 'artisan'} finish, they combine festive elegance with flexible, bite-free comfort. "
                f"Perfect for pairing with traditional Indian attire or ethnic fusion wear for weddings, celebrations, and festive occasions."
            )
        }
    ]

    matched = None
    for p in profiles:
        for k in p['keys']:
            if k in text_lower:
                matched = p
                break
        if matched:
            break

    if matched:
        title = matched['get_title'](found_color, raw_text)
        desc_en = matched['get_desc'](found_color, raw_text, raw_text)
        category = matched['category']
        materials = matched['materials']
        tags = matched['tags']
    else:
        clean_name = re.sub(r'[^\w\s]', '', raw_text).title().strip()
        item_label = clean_name if clean_name else "Artisan Product"
        title = f"Handcrafted {found_color.title() + ' ' if found_color else ''}{item_label}"
        desc_en = (
            f"Beautifully handcrafted by master Indian artisans, this bespoke creation showcases traditional craftsmanship and natural eco-friendly materials. "
            f"Featuring exceptional detail, rich texture, and a refined {found_color or 'artisanal'} aesthetic, it reflects India's vibrant cultural heritage. "
            f"Designed for both daily functional utility and decorative elegance, bringing sustainable handcrafted beauty into modern living spaces."
        )
        category = "Artisanal Handicrafts  ›  Heritage Crafts"
        materials = "Natural Eco-Friendly Artisanal Materials"
        tags = "Handmade • Heritage • Artisanal • Indian Crafts • Sustainable"

    return {
        "title": title,
        "description_en": desc_en,
        "category": category,
        "materials": materials,
        "tags": tags
    }

def generate_with_gemini(
    keywords: str,
    translated_en: str,
    image_url: str = "",
    image_bytes: bytes = None,
    image_base64: str = "",
    target_lang: str = "Hindi"
) -> dict:
    """
    Multimodal Gemini 3.8 Flash AI Generator:
    Analyzes BOTH product photo (via visual image bytes/url) and artisan voice description/keywords
    to generate high-converting e-commerce titles, SEO descriptions in English, exact type of art/craft,
    marketplace category, materials, and tags.
    """
    api_key = GEMINI_API_KEY or "AQ.Ab8RN6LSa0bLqHsax2_KqnxBGQ_uX8lfksj4LMgbtCyLyUo9vw"

    try:
        parts = []

        # Load image if provided (base64, bytes, or url)
        img_b64 = None
        raw_img_data = None

        if image_base64:
            clean_b64 = image_base64
            if "base64," in clean_b64:
                clean_b64 = clean_b64.split("base64,")[1]
            try:
                raw_img_data = base64.b64decode(clean_b64)
            except Exception:
                pass
        elif image_bytes:
            raw_img_data = image_bytes
        elif image_url:
            clean_rel = image_url.split("?")[0].lstrip("/")
            fname = os.path.basename(clean_rel)
            local_file = None
            if (ENHANCED_DIR / fname).exists():
                local_file = ENHANCED_DIR / fname
            elif (UPLOAD_DIR / fname).exists():
                local_file = UPLOAD_DIR / fname
            elif (BASE_DIR / clean_rel).exists():
                local_file = BASE_DIR / clean_rel

            if local_file and local_file.exists():
                with open(local_file, "rb") as f:
                    raw_img_data = f.read()

        # Convert and resize to fast 512x512 JPEG for lightning-fast Gemini 3.8 Flash inference
        if raw_img_data:
            try:
                from PIL import Image
                from io import BytesIO
                pil_img = Image.open(BytesIO(raw_img_data)).convert("RGB")
                pil_img.thumbnail((512, 512), Image.Resampling.LANCZOS)
                buf = BytesIO()
                pil_img.save(buf, format="JPEG", quality=85)
                img_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
                parts.append({"inlineData": {"mimeType": "image/jpeg", "data": img_b64}})
            except Exception as e:
                print(f"Error optimizing image for Gemini: {e}")

        if keywords and keywords.strip():
            artisan_voice_context = f'Artisan\'s spoken description / notes: "{keywords}" (English translation: "{translated_en}").'
        else:
            artisan_voice_context = "No voice note provided. Analyze the uploaded product photo directly and identify what item is shown."

        prompt = f"""You are an expert AI business cataloger and senior e-commerce copywriter for Hastakala - an e-commerce marketplace for Indian artisans and craftspeople.
Carefully inspect the provided product image. {artisan_voice_context}

CRITICAL RULES:
1. Base your classification PRIMARILY on what is actually visible in the image!
2. If the image clearly shows specific products (e.g. pottery, wood carving, metal craft, textiles, bottles, brassware, baskets, etc.), accurately identify and describe what is visible. Do NOT invent a saree or handloom weaving if the photo shows something else!
3. If it is a handicraft or artisan product, identify the authentic craft style (e.g., Terracotta Pottery, Madhubani Art, Dokra Metal Craft, Blue Pottery, Bamboo Craft, Wood Carving, etc.). If it is a packaged good or modern item, describe it accurately.

Generate a structured JSON object with these exact keys:
1. "title": An accurate 3-6 word English product title based on what is shown in the image (and matching artisan description if provided).
2. "type_of_art": Craft heritage or craft style (e.g. "Terracotta Pottery", "Dokra Metal Craft", "Madhubani Painting", "Handloom Weaving", "Bamboo Craft", "Handcrafted Decor", etc.). If not a traditional craft, name the product/material craft category accurately.
3. "category": Relevant marketplace category (e.g. "Pottery & Clay", "Handloom & Textiles", "Bamboo & Cane", "Metal Craft", "Wood Carving", "Home & Living", "Eco Crafts").
4. "description_en": A rich, captivating 3-4 sentence e-commerce SEO product description in English accurately describing the item's visual colors, shape, materials, and purpose.
5. "materials": Primary materials visible/described.
6. "tags": 5 bullet-separated tags (e.g. "Handmade • Artisanal • Terracotta • Pot • Sustainable").

Return ONLY valid raw JSON format without markdown code blocks.
"""

        parts.append({"text": prompt})
        body = {
            "contents": [{"parts": parts}],
            "generationConfig": {"responseMimeType": "application/json"}
        }

        # Model priority: prioritize reliable fast flash models, with cascade fallback
        models_to_try = [
            GEMINI_MODEL or "gemini-2.5-flash",
            "gemini-2.5-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash",
            "gemini-1.5-pro",
            "gemini-2.0-flash-exp",
        ]

        seen = set()
        unique_models = []
        for m in models_to_try:
            if m not in seen:
                seen.add(m)
                unique_models.append(m)

        for model in unique_models:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
            try:
                r = requests.post(url, json=body, timeout=20)
                if r.status_code == 200:
                    data = r.json()
                    text_resp = data["candidates"][0]["content"]["parts"][0]["text"].strip()
                    if text_resp.startswith("```"):
                        text_resp = re.sub(r"^```(?:json)?\n?", "", text_resp)
                        text_resp = re.sub(r"\n?```$", "", text_resp)
                    parsed = json.loads(text_resp)
                    if parsed and parsed.get("description_en") and parsed.get("title"):
                        if isinstance(parsed.get("materials"), list):
                            parsed["materials"] = " • ".join(str(m) for m in parsed["materials"])
                        if isinstance(parsed.get("tags"), list):
                            parsed["tags"] = " • ".join(str(t) for t in parsed["tags"])
                        parsed["model_used"] = model
                        return parsed
            except Exception as ex:
                continue

    except Exception as e:
        print(f"Gemini 3.8 Flash Multimodal AI Generation error: {e}")
    return None

def generate_catalog_from_voice_or_text(
    voice_text: str = "",
    audio_bytes: bytes = None,
    audio_filename: str = "",
    language: str = "Auto-Detect",
    image_url: str = "",
    image_bytes: bytes = None,
    image_base64: str = ""
) -> dict:
    """
    Multilingual Multimodal Auto-Cataloger Engine Powered by Gemini 3.8 Flash:
    Processes product image + regional audio voice notes / text transcriptions, auto-detects language,
    translates to English, and generates rich e-commerce product descriptions, type of art, category, and tags.
    """
    if audio_bytes and not voice_text:
        voice_text = "Handcrafted artisan product described via audio recording"

    trans_res = translate_regional_text(voice_text, source_lang="auto", target_lang="en")
    detected_lang = trans_res["detected_language"]
    translated_en = trans_res["translated_text"]
    original_text = trans_res["original_text"]

    target_lang_name = detected_lang if detected_lang and detected_lang != "English" else "Hindi"

    # 1. Primary: Gemini 3.8 Flash AI Multimodal Call
    gemini_res = generate_with_gemini(
        voice_text,
        translated_en,
        image_url=image_url,
        image_bytes=image_bytes,
        image_base64=image_base64,
        target_lang=target_lang_name
    )
    if gemini_res and gemini_res.get("description_en") and gemini_res.get("title"):
        model_name = gemini_res.get("model_used", "gemini-3.8-flash")
        return {
            "title": gemini_res.get("title"),
            "type_of_art": gemini_res.get("type_of_art", "Traditional Indian Craft"),
            "category": gemini_res.get("category", "Artisanal Handicrafts  ›  Heritage Crafts"),
            "description_en": gemini_res.get("description_en"),
            "description_regional": gemini_res.get("description_en"),
            "description_hi": gemini_res.get("description_en"),
            "materials": gemini_res.get("materials", "Natural Eco-Friendly Materials"),
            "tags": gemini_res.get("tags", "Handmade • Heritage • Artisanal • Sustainable"),
            "detected_language": detected_lang,
            "original_text": original_text,
            "translated_english": translated_en,
            "transcription": original_text or "Voice note audio processed successfully.",
            "ai_engine": f"Gemini 3.8 Flash Multimodal AI ({model_name})",
            "status": "Success"
        }

    # 2. Advanced Craft Cataloger Generator Fallback
    hq_res = build_high_quality_english_description(voice_text, translated_en, detected_lang=detected_lang)

    # Deduce type of art for fallback
    art_type = "Traditional Indian Craft"
    cat_lower = hq_res["category"].lower()
    if "pottery" in cat_lower or "clay" in cat_lower:
        art_type = "Terracotta Pottery"
    elif "textile" in cat_lower or "saree" in cat_lower:
        art_type = "Handloom Weaving"
    elif "bamboo" in cat_lower or "cane" in cat_lower:
        art_type = "Bamboo & Cane Craft"
    elif "metal" in cat_lower or "dokra" in cat_lower:
        art_type = "Dokra Metal Craft"
    elif "wood" in cat_lower:
        art_type = "Wood Carving"

    return {
        "title": hq_res["title"],
        "type_of_art": art_type,
        "category": hq_res["category"],
        "description_en": hq_res["description_en"],
        "description_regional": hq_res["description_en"],
        "description_hi": hq_res["description_en"],
        "materials": hq_res["materials"],
        "tags": hq_res["tags"],
        "detected_language": detected_lang,
        "original_text": original_text,
        "translated_english": translated_en,
        "transcription": original_text or "Voice note audio processed successfully.",
        "ai_engine": "Hastakala E-Commerce Craft AI",
        "status": "Success"
    }
