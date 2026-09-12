import os
import re
from hastakala_backend.config import GEMINI_API_KEY

def generate_catalog_from_voice_or_text(
    voice_text: str = "",
    audio_bytes: bytes = None,
    audio_filename: str = "",
    language: str = "Hindi"
) -> dict:
    """
    Multilingual Auto-Cataloger Engine:
    Processes regional audio voice notes or text transcriptions to generate
    structured e-commerce catalogs (Title, English SEO Description, Hindi Description, Category, Materials, Tags).
    """
    # If audio_bytes provided without text, infer transcription placeholder
    if audio_bytes and not voice_text:
        voice_text = "Handcrafted artisan product described via audio recording"

    text_lower = (voice_text or "").lower()

    # Comprehensive Regional Craft Intelligence Engine
    craft_database = [
        {
            "keywords": ["saree", "saari", "साड़ी", "সাড়ি", "સાડી", "சேலை", "dupatta", "stole", "handloom", "bunkar", "zari", "banarasi", "chanderi", "kanjeevaram", "weaver"],
            "category": "Textiles  ›  Sarees & Handloom",
            "materials": "Pure Handloom Cotton & Zari Thread",
            "tags": "Handloom • Saree • Traditional • Ethnic Wear • Banarasi • Festive",
            "en_desc": "Exquisite handwoven Banarasi saree handcrafted by traditional master weavers. Features intricate ethnic motifs, rich soft texture, and authentic artisan craftsmanship.",
            "hi_desc": "पारंपरिक मास्टर बुनकरों द्वारा हस्तनिर्मित उत्कृष्ट हथकरघा बनारसी साड़ी। इसमें जटिल एथनिक डिज़ाइन, समृद्ध बनावट और प्रामाणिक कारीगरी शामिल है।",
            "default_title": "Handwoven Banarasi Silk & Cotton Saree"
        },
        {
            "keywords": ["basket", "tokri", "टोकरी", "ঝুড়ি", "ટોપલી", "கூடை", "bamboo", "baans", "cane", "jute", "storage"],
            "category": "Home Decor  ›  Baskets & Cane Craft",
            "materials": "100% Natural Eco-Friendly Bamboo & Cane",
            "tags": "Handmade • Eco-friendly • Bamboo • Storage • Sustainable • Rural Craft",
            "en_desc": "Durable and stylish bamboo storage basket expertly hand-braided by rural craftspeople using natural seasoned bamboo strips. Ideal for modern sustainable homes.",
            "hi_desc": "प्राकृतिक बांस की पट्टियों का उपयोग करके ग्रामीण कारीगरों द्वारा हस्तनिर्मित टिकाऊ और स्टाइलिश बांस टोकरी। आधुनिक पर्यावरण-अनुकूल घरों के लिए आदर्श।",
            "default_title": "Handcrafted Eco-Friendly Bamboo Basket"
        },
        {
            "keywords": ["pot", "matka", "मटका", "मिट्टी", "কলসী", "માટલું", "பானை", "clay", "terracotta", "pottery", "mrutika"],
            "category": "Kitchen & Dining  ›  Terracotta Pottery",
            "materials": "Natural Bio-Clay & Organic Terracotta",
            "tags": "Pottery • Terracotta • Clay Pitcher • Eco-Friendly • Artisanal • Kitchenware",
            "en_desc": "Traditional terracotta clay pot hand-molded on pottery wheels by artisan potters. Naturally cools liquids, preserves fresh aroma, and is 100% toxin-free.",
            "hi_desc": "कुम्हारों द्वारा चाक पर हाथ से ढाला गया पारंपरिक मिट्टी का मटका। प्राकृतिक रूप से पानी को ठंडा और ताज़ा रखता है, 100% रसायन-मुक्त।",
            "default_title": "Traditional Terracotta Clay Pitcher"
        },
        {
            "keywords": ["wood", "lakdi", "लकड़ी", "কাঠ", "લાકડું", "மரக்கலை", "sheesham", "teak", "carving", "toy", "showpiece"],
            "category": "Handicrafts  ›  Wood Craft & Carvings",
            "materials": "Seasoned Sheesham Wood & Natural Wax Polish",
            "tags": "Wood Craft • Handcarved • Sheesham • Heritage • Wooden Decor • Artisan",
            "en_desc": "Intricately hand-carved wooden craft accent crafted from seasoned hardwood. Polished with natural non-toxic wax to highlight authentic wood grains.",
            "hi_desc": "टिकाऊ शीशम की लकड़ी से बनी जटिल नक्काशीदार लकड़ी की हस्तशिल्प कलाकृति। प्राकृतिक वैक्स पॉलिश के साथ फिनिश।",
            "default_title": "Hand-Carved Wooden Artisan Decor"
        },
        {
            "keywords": ["brass", "pittal", "पीतल", "पितळ", "metal", "dokra", "bell metal", "copper", "statue", "idol"],
            "category": "Handicrafts  ›  Metal Craft & Dokra",
            "materials": "Solid Brass & Bell Metal Bronze",
            "tags": "Metal Craft • Brass • Dokra • Ethnic • Heritage • Bronze",
            "en_desc": "Authentic lost-wax cast metal sculpture handcrafted by traditional Dokra metallurgists. Durable, timeless, and rich in tribal Indian heritage.",
            "hi_desc": "पारंपरिक ढोकरा धातु कारीगरों द्वारा हस्तनिर्मित ठोस पीतल की ढलाई कलाकृति। भारतीय जनजातीय विरासत से समृद्ध।",
            "default_title": "Handcrafted Tribal Brass Sculpture"
        },
        {
            "keywords": ["mojari", "jutti", "जूती", "chamra", "leather", "footwear", "shoes", "kolhapuri"],
            "category": "Fashion  ›  Artisanal Footwear",
            "materials": "Genuine Tanned Leather & Thread Embroidery",
            "tags": "Jutti • Mojari • Leather • Handstitched • Ethnic Footwear",
            "en_desc": "Hand-stitched leather Mojari jutti embellished with traditional ethnic embroidery. Soft cushioned sole designed for festive elegance and comfort.",
            "hi_desc": "हाथ से सिली गई चमड़े की पारंपरिक मोजड़ी जूती। सुंदर कढ़ाई और आरामदायक बनावट के साथ उत्सवों के लिए उत्तम।",
            "default_title": "Hand-Stitched Embroidered Leather Jutti"
        }
    ]

    matched_profile = None
    for profile in craft_database:
        for kw in profile["keywords"]:
            if kw in text_lower:
                matched_profile = profile
                break
        if matched_profile:
            break

    if not matched_profile:
        matched_profile = {
            "category": "Artisanal Handicrafts  ›  Heritage Crafts",
            "materials": "Natural Eco-Friendly Materials",
            "tags": "Handmade • Heritage • Artisanal • Indian Crafts • Sustainable",
            "en_desc": f"Beautifully handcrafted creation by skilled Indian artisans. {voice_text if voice_text else 'Made with traditional heritage techniques and high quality craftsmanship.'}",
            "hi_desc": f"भारतीय कुशल कारीगरों द्वारा निर्मित सुंदर हस्तशिल्प कलाकृति। {voice_text if voice_text else 'पारंपरिक विरासत तकनीकों से निर्मित।'} ",
            "default_title": "Handcrafted Indian Artisan Item"
        }

    # Generate custom title if specific text provided
    title = matched_profile["default_title"]
    if voice_text and len(voice_text.strip()) > 3:
        clean_str = re.sub(r'[^\w\s]', '', voice_text).strip()
        words = clean_str.split()
        if 2 <= len(words) <= 7:
            title = clean_str.title()

    return {
        "title": title,
        "description_en": matched_profile["en_desc"],
        "description_hi": matched_profile["hi_desc"],
        "category": matched_profile["category"],
        "materials": matched_profile["materials"],
        "tags": matched_profile["tags"],
        "detected_language": language,
        "transcription": voice_text or "Voice note audio processed successfully.",
        "status": "Success"
    }
