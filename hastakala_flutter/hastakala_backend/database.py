import sqlite3
import json
import os
from datetime import datetime
from hastakala_backend.config import DB_PATH, MONGODB_URI, MONGODB_DB_NAME

try:
    import pymongo
    HAS_PYMONGO = True
except ImportError:
    HAS_PYMONGO = False

try:
    import certifi
    HAS_CERTIFI = True
except ImportError:
    HAS_CERTIFI = False

_mongo_client = None
_mongo_db = None
_db_type = "SQLite"
_current_mongodb_uri = MONGODB_URI

def get_db_type() -> str:
    global _db_type
    return _db_type

def get_db_info() -> dict:
    global _db_type, _current_mongodb_uri
    sanitized_uri = ""
    if _current_mongodb_uri:
        if "@" in _current_mongodb_uri:
            prefix = _current_mongodb_uri.split("@")[0]
            suffix = _current_mongodb_uri.split("@")[1]
            if ":" in prefix:
                user = prefix.split(":")[0]
                sanitized_uri = user + ":****@" + suffix
            else:
                sanitized_uri = "****@" + suffix
        else:
            sanitized_uri = _current_mongodb_uri
    return {
        "db_type": _db_type,
        "mongodb_uri": sanitized_uri,
        "is_mongodb": _db_type == "MongoDB",
        "database_name": MONGODB_DB_NAME if _db_type == "MongoDB" else str(DB_PATH.name)
    }

def get_sqlite_conn():
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn

def connect_mongodb(uri: str):
    global _mongo_client, _mongo_db, _db_type, _current_mongodb_uri
    if not HAS_PYMONGO:
        raise Exception("pymongo package is missing")
    if not uri or not uri.strip():
        raise Exception("MongoDB URI cannot be empty")

    clean_uri = uri.strip()
    kwargs = {"serverSelectionTimeoutMS": 6000}
    if HAS_CERTIFI:
        kwargs["tlsCAFile"] = certifi.where()
    client = pymongo.MongoClient(clean_uri, **kwargs)
    # Ping database server
    client.admin.command('ping')

    db = client[MONGODB_DB_NAME]
    _mongo_client = client
    _mongo_db = db
    _db_type = "MongoDB"
    _current_mongodb_uri = clean_uri

    _seed_mongodb()
    return True

def _format_product(p: dict) -> dict:
    if not p:
        return p
    res = dict(p)
    res["moq"] = int(res.get("moq") or 50)
    res["available_qty"] = int(res.get("available_qty") or 500)
    res["bulk_available"] = 1 if res.get("bulk_available") in (1, True, "1", "true") else 1
    res["custom_size"] = 1 if res.get("custom_size") in (1, True, "1", "true") else 1
    res["custom_design"] = 1 if res.get("custom_design") in (1, True, "1", "true") else 1
    res["custom_packaging"] = 1 if res.get("custom_packaging") in (1, True, "1", "true") else 1
    res["monthly_capacity"] = int(res.get("monthly_capacity") or 1000)
    
    prod_days = res.get("production_days", 3)
    if not res.get("production_time"):
        res["production_time"] = f"{prod_days}–{prod_days + 2} days"
    
    if not res.get("artisan_name"):
        res["artisan_name"] = "Ramesh Kumar"
    if not res.get("artisan_location"):
        res["artisan_location"] = "West Bengal"

    # Format bulk pricing tiers
    bp = res.get("bulk_pricing")
    if isinstance(bp, str) and bp.strip():
        try:
            res["bulk_pricing"] = json.loads(bp)
        except Exception:
            res["bulk_pricing"] = []
    
    if not isinstance(res.get("bulk_pricing"), list) or not res.get("bulk_pricing"):
        retail = float(res.get("price_retail", 500.0))
        wholesale = float(res.get("price_wholesale", 450.0))
        min_p = float(res.get("min_price", 400.0))
        res["bulk_pricing"] = [
            {"tier": "Tier 1", "range": "1–49 pieces", "price": round(retail, 2), "discount": "Standard Retail"},
            {"tier": "Tier 2", "range": "50–99 pieces", "price": round(wholesale, 2), "discount": "10% Bulk Discount"},
            {"tier": "Tier 3", "range": "100+ pieces", "price": round(min_p, 2), "discount": "20% Wholesale Discount"}
        ]
    return res

def _seed_mongodb():
    global _mongo_db
    if _mongo_db is None:
        return

    now_str = datetime.now().isoformat()

    # 1. Buyers
    if _mongo_db.buyers.count_documents({}) == 0:
        seed_buyers = [
            {
                "id": 1,
                "organization_name": "FabIndia B2B Procurement",
                "contact_person": "Sunita Verma",
                "username": "fabindia_buyer",
                "password": "password123",
                "buyer_type": "Corporate Wholesale Buyer",
                "target_category": "Home Decor, Baskets, Textiles",
                "min_order_qty": 50,
                "contact_email": "b2b@fabindia.com",
                "phone": "+91 98200 11223",
                "verified": 1,
                "location": "Mumbai, Maharashtra",
                "created_at": now_str
            },
            {
                "id": 2,
                "organization_name": "GeM Government Marketplace",
                "contact_person": "Rajesh Sharma",
                "username": "gem_buyer",
                "password": "password123",
                "buyer_type": "Government Procurement",
                "target_category": "Handloom, Office Gifting, Bamboo",
                "min_order_qty": 100,
                "contact_email": "procurement@gem.gov.in",
                "phone": "+91 11 2345 6789",
                "verified": 1,
                "location": "New Delhi",
                "created_at": now_str
            },
            {
                "id": 3,
                "organization_name": "Tribes India Craftsvilla",
                "contact_person": "Amit Patel",
                "username": "tribes_buyer",
                "password": "password123",
                "buyer_type": "Cooperative Federation",
                "target_category": "Handwoven Textiles, Terracotta",
                "min_order_qty": 20,
                "contact_email": "orders@tribesindia.com",
                "phone": "+91 11 9876 5432",
                "verified": 1,
                "location": "New Delhi",
                "created_at": now_str
            }
        ]
        _mongo_db.buyers.insert_many(seed_buyers)

    # 2. Artisans
    if _mongo_db.artisans.count_documents({"username": "ramesh_artisan"}) == 0:
        _mongo_db.artisans.update_one(
            {"id": 1},
            {"$set": {
                "id": 1,
                "name": "Ramesh Kumar",
                "username": "ramesh_artisan",
                "password": "password123",
                "phone": "9876543210",
                "gender": "Male",
                "craft_type": "Master Weaver & Bamboo Craftsman",
                "language": "Hindi",
                "location": "West Bengal",
                "created_at": now_str
            }},
            upsert=True
        )

    # 3. Products with B2B Fields
    if _mongo_db.products.count_documents({}) == 0:
        sample_products = [
            {
                "id": 1,
                "artisan_id": 1,
                "artisan_username": "ramesh_artisan",
                "artisan_name": "Ramesh Kumar",
                "artisan_location": "West Bengal",
                "title": "Handmade Bamboo Storage Basket",
                "description_en": "Traditional eco-friendly bamboo basket woven from sustainable river cane. Sturdy, moisture-resistant, and ideal for bulk retail or premium corporate packaging.",
                "description_hi": "प्राकृतिक नदी के बेंत से बुनी गई पारंपरिक पर्यावरण-अनुकूल बांस की टोकरी। मजबूत, नमी प्रतिरोधी और थोक खुदरा या प्रीमियम उपहार के लिए आदर्श।",
                "category": "Bamboo & Cane  ›  Baskets",
                "materials": "100% Organic Bamboo & Cane",
                "tags": "Handmade • Eco-Friendly • Bamboo • B2B Bulk",
                "price_retail": 500.0,
                "price_wholesale": 450.0,
                "min_price": 400.0,
                "material_cost": 160.0,
                "labor_cost": 140.0,
                "production_days": 2,
                "moq": 50,
                "available_qty": 500,
                "bulk_available": 1,
                "custom_size": 1,
                "custom_design": 1,
                "custom_packaging": 1,
                "monthly_capacity": 1000,
                "production_time": "3–5 days",
                "raw_image_url": "/uploads/sample_basket.jpg",
                "enhanced_image_url": "/uploads/enhanced/sample_basket.jpg",
                "status": "Published",
                "created_at": now_str
            },
            {
                "id": 2,
                "artisan_id": 1,
                "artisan_username": "ramesh_artisan",
                "artisan_name": "Ramesh Kumar",
                "artisan_location": "Varanasi, Uttar Pradesh",
                "title": "Handwoven Banarasi Cotton Saree",
                "description_en": "Exquisite handloom cotton saree with intricate floral Zari border. Breathable weave perfect for retail boutiques and export collections.",
                "description_hi": "पारंपरिक ज़री बॉर्डर के साथ बुनी गई उत्कृष्ट हथकरघा सूती साड़ी। बुटीक और निर्यात संग्रह के लिए उत्तम।",
                "category": "Handloom  ›  Sarees & Textiles",
                "materials": "Pure Cotton & Silver Zari",
                "tags": "Handloom • Saree • Traditional • Banarasi",
                "price_retail": 1499.0,
                "price_wholesale": 1150.0,
                "min_price": 950.0,
                "material_cost": 450.0,
                "labor_cost": 350.0,
                "production_days": 4,
                "moq": 20,
                "available_qty": 250,
                "bulk_available": 1,
                "custom_size": 1,
                "custom_design": 1,
                "custom_packaging": 1,
                "monthly_capacity": 300,
                "production_time": "5–7 days",
                "raw_image_url": "/uploads/sample_saree.jpg",
                "enhanced_image_url": "/uploads/enhanced/sample_saree.jpg",
                "status": "Published",
                "created_at": now_str
            },
            {
                "id": 3,
                "artisan_id": 1,
                "artisan_username": "ramesh_artisan",
                "artisan_name": "Shambhu Pal",
                "artisan_location": "Bankura, West Bengal",
                "title": "Traditional Terracotta Clay Water Pitcher",
                "description_en": "Natural cooling terracotta clay water jug with hand-carved ethnic motifs. 100% chemical-free, biodegradable, and food safe.",
                "description_hi": "हाथ से नक्काशीदार पारंपरिक मिट्टी का मटका, प्राकृतिक रूप से शीतल जल प्रदान करता है।",
                "category": "Pottery  ›  Terracotta & Clay",
                "materials": "Natural Bankura River Clay",
                "tags": "Pottery • Terracotta • Clay • Sustainable",
                "price_retail": 650.0,
                "price_wholesale": 500.0,
                "min_price": 420.0,
                "material_cost": 150.0,
                "labor_cost": 150.0,
                "production_days": 3,
                "moq": 30,
                "available_qty": 400,
                "bulk_available": 1,
                "custom_size": 1,
                "custom_design": 1,
                "custom_packaging": 1,
                "monthly_capacity": 800,
                "production_time": "4–6 days",
                "raw_image_url": "/uploads/sample_pot.jpg",
                "enhanced_image_url": "/uploads/enhanced/sample_pot.jpg",
                "status": "Published",
                "created_at": now_str
            },
            {
                "id": 4,
                "artisan_id": 1,
                "artisan_username": "ramesh_artisan",
                "artisan_name": "Sukhram Baghel",
                "artisan_location": "Bastar, Chhattisgarh",
                "title": "Dokra Bell Metal Tribal Figurine",
                "description_en": "Ancient lost-wax cast bell metal artifact handcrafted by Bastar tribal artisans. Highly sought after by luxury hotels, collectors, and corporate gifting.",
                "description_hi": "बस्तर के जनजातीय कारीगरों द्वारा हस्तनिर्मित प्राचीन खोई-मोम ढलाई डोकरा धातु मूर्ति।",
                "category": "Metal Craft  ›  Dokra Brass",
                "materials": "Brass & Bell Metal Alloy",
                "tags": "Dokra • Brass • Tribal • Heritage",
                "price_retail": 1200.0,
                "price_wholesale": 950.0,
                "min_price": 820.0,
                "material_cost": 320.0,
                "labor_cost": 350.0,
                "production_days": 5,
                "moq": 15,
                "available_qty": 150,
                "bulk_available": 1,
                "custom_size": 1,
                "custom_design": 1,
                "custom_packaging": 1,
                "monthly_capacity": 250,
                "production_time": "7–10 days",
                "raw_image_url": "/uploads/sample_dokra.jpg",
                "enhanced_image_url": "/uploads/enhanced/sample_dokra.jpg",
                "status": "Published",
                "created_at": now_str
            }
        ]
        _mongo_db.products.insert_many(sample_products)

    # 4. Enquiries
    if _mongo_db.enquiries.count_documents({}) == 0:
        sample_enquiries = [
            {
                "id": 1,
                "product_id": 1,
                "product_title": "Handmade Bamboo Storage Basket",
                "buyer_id": 1,
                "buyer_name": "Sunita Verma",
                "business_name": "FabIndia B2B Procurement",
                "buyer_type": "Corporate Wholesale Buyer",
                "buyer_phone": "+91 98200 11223",
                "buyer_email": "b2b@fabindia.com",
                "buyer_location": "Mumbai, Maharashtra",
                "order_quantity": 100,
                "offer_price": 450.0,
                "target_price": 450.0,
                "custom_size": 1,
                "custom_design": 1,
                "custom_packaging": 1,
                "custom_notes": "Requires brand tag with natural twine packaging",
                "message": "We wish to order 100 units for our upcoming Diwali festive packaging collection.",
                "artisan_id": 1,
                "artisan_username": "ramesh_artisan",
                "status": "New Lead",
                "created_at": now_str
            }
        ]
        _mongo_db.enquiries.insert_many(sample_enquiries)

def init_db(mongodb_uri: str = None):
    global _db_type
    target_uri = mongodb_uri or MONGODB_URI
    if target_uri:
        try:
            connect_mongodb(target_uri)
            print(f"Connected to MongoDB successfully ({MONGODB_DB_NAME}).")
            return
        except Exception as e:
            print(f"MongoDB connection attempt failed: {e}. Falling back to SQLite.")

    # SQLite Setup
    _db_type = "SQLite"
    conn = get_sqlite_conn()
    cursor = conn.cursor()

    # Artisans Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS artisans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT UNIQUE,
        password TEXT,
        phone TEXT NOT NULL,
        gender TEXT DEFAULT 'Male',
        craft_type TEXT DEFAULT 'Handloom & Handicrafts',
        language TEXT DEFAULT 'English',
        location TEXT DEFAULT 'West Bengal',
        profile_picture TEXT DEFAULT '',
        created_at TEXT NOT NULL
    );
    """)

    # Products Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artisan_id INTEGER DEFAULT 1,
        artisan_username TEXT DEFAULT '',
        artisan_name TEXT DEFAULT 'Ramesh Kumar',
        artisan_location TEXT DEFAULT 'West Bengal',
        title TEXT NOT NULL,
        description_en TEXT NOT NULL,
        description_hi TEXT NOT NULL,
        category TEXT NOT NULL,
        materials TEXT NOT NULL,
        tags TEXT NOT NULL,
        price_retail REAL NOT NULL,
        price_wholesale REAL NOT NULL,
        min_price REAL NOT NULL,
        material_cost REAL NOT NULL,
        labor_cost REAL NOT NULL,
        production_days INTEGER DEFAULT 2,
        moq INTEGER DEFAULT 50,
        available_qty INTEGER DEFAULT 500,
        bulk_available INTEGER DEFAULT 1,
        custom_size INTEGER DEFAULT 1,
        custom_design INTEGER DEFAULT 1,
        custom_packaging INTEGER DEFAULT 1,
        monthly_capacity INTEGER DEFAULT 1000,
        production_time TEXT DEFAULT '3–5 days',
        bulk_pricing TEXT DEFAULT '',
        raw_image_url TEXT,
        enhanced_image_url TEXT,
        status TEXT DEFAULT 'Published',
        created_at TEXT NOT NULL
    );
    """)

    # Buyers Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS buyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        organization_name TEXT NOT NULL,
        contact_person TEXT DEFAULT '',
        username TEXT UNIQUE,
        password TEXT,
        buyer_type TEXT NOT NULL,
        target_category TEXT NOT NULL,
        min_order_qty INTEGER DEFAULT 25,
        contact_email TEXT,
        phone TEXT,
        verified INTEGER DEFAULT 1,
        location TEXT,
        created_at TEXT
    );
    """)

    # Enquiries Table (Heart of B2B Marketplace)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS enquiries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        buyer_id INTEGER DEFAULT 0,
        buyer_name TEXT NOT NULL,
        business_name TEXT NOT NULL,
        buyer_type TEXT DEFAULT 'Wholesale Buyer',
        buyer_phone TEXT DEFAULT '',
        buyer_email TEXT DEFAULT '',
        buyer_location TEXT DEFAULT 'India',
        message TEXT NOT NULL,
        order_quantity INTEGER NOT NULL,
        offer_price REAL NOT NULL,
        target_price REAL DEFAULT 0.0,
        custom_size INTEGER DEFAULT 0,
        custom_design INTEGER DEFAULT 0,
        custom_packaging INTEGER DEFAULT 0,
        custom_notes TEXT DEFAULT '',
        artisan_id INTEGER DEFAULT 1,
        artisan_username TEXT DEFAULT 'ramesh_artisan',
        status TEXT DEFAULT 'New Lead',
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
    );
    """)

    # Dynamic SQLite Migrations for any new columns
    def _migrate_table(table: str, col_defs: list):
        cursor.execute(f"PRAGMA table_info({table})")
        cols = [r[1] for r in cursor.fetchall()]
        for col_name, col_type in col_defs:
            if col_name not in cols:
                try:
                    cursor.execute(f"ALTER TABLE {table} ADD COLUMN {col_name} {col_type}")
                    conn.commit()
                except Exception as e:
                    print(f"Migration note for {table}.{col_name}: {e}")

    _migrate_table("artisans", [
        ("username", "TEXT"),
        ("password", "TEXT"),
        ("gender", "TEXT DEFAULT 'Male'"),
        ("craft_type", "TEXT DEFAULT 'Handloom & Handicrafts'"),
        ("location", "TEXT DEFAULT 'West Bengal'"),
        ("profile_picture", "TEXT DEFAULT ''"),
    ])

    _migrate_table("products", [
        ("artisan_username", "TEXT DEFAULT ''"),
        ("artisan_name", "TEXT DEFAULT 'Ramesh Kumar'"),
        ("artisan_location", "TEXT DEFAULT 'West Bengal'"),
        ("moq", "INTEGER DEFAULT 50"),
        ("available_qty", "INTEGER DEFAULT 500"),
        ("bulk_available", "INTEGER DEFAULT 1"),
        ("custom_size", "INTEGER DEFAULT 1"),
        ("custom_design", "INTEGER DEFAULT 1"),
        ("custom_packaging", "INTEGER DEFAULT 1"),
        ("monthly_capacity", "INTEGER DEFAULT 1000"),
        ("production_time", "TEXT DEFAULT '3–5 days'"),
        ("bulk_pricing", "TEXT DEFAULT ''"),
    ])

    _migrate_table("buyers", [
        ("contact_person", "TEXT DEFAULT ''"),
        ("username", "TEXT"),
        ("password", "TEXT"),
        ("created_at", "TEXT"),
    ])

    _migrate_table("enquiries", [
        ("buyer_id", "INTEGER DEFAULT 0"),
        ("business_name", "TEXT DEFAULT ''"),
        ("buyer_phone", "TEXT DEFAULT ''"),
        ("buyer_email", "TEXT DEFAULT ''"),
        ("buyer_location", "TEXT DEFAULT 'India'"),
        ("target_price", "REAL DEFAULT 0.0"),
        ("custom_size", "INTEGER DEFAULT 0"),
        ("custom_design", "INTEGER DEFAULT 0"),
        ("custom_packaging", "INTEGER DEFAULT 0"),
        ("custom_notes", "TEXT DEFAULT ''"),
        ("artisan_id", "INTEGER DEFAULT 1"),
        ("artisan_username", "TEXT DEFAULT 'ramesh_artisan'"),
    ])

    # Seed Default Buyers
    cursor.execute("SELECT COUNT(*) as cnt FROM buyers WHERE username = 'fabindia_buyer'")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        seed_buyers = [
            ("FabIndia B2B Procurement", "Sunita Verma", "fabindia_buyer", "password123", "Corporate Wholesale Buyer", "Home Decor, Baskets, Textiles", 50, "b2b@fabindia.com", "+91 98200 11223", 1, "Mumbai, Maharashtra", now_str),
            ("GeM Government Marketplace", "Rajesh Sharma", "gem_buyer", "password123", "Government Procurement", "Handloom, Office Gifting, Bamboo", 100, "procurement@gem.gov.in", "+91 11 2345 6789", 1, "New Delhi", now_str),
            ("Tribes India Craftsvilla", "Amit Patel", "tribes_buyer", "password123", "Cooperative Federation", "Handwoven Textiles, Terracotta", 20, "orders@tribesindia.com", "+91 11 9876 5432", 1, "New Delhi", now_str),
            ("Surajkund Heritage Exporters", "Pooja Roy", "surajkund_buyer", "password123", "Fair Organizers & Exporters", "Sarees, Pottery, Metal Craft", 25, "export@surajkund.org", "+91 129 251 1234", 1, "Haryana", now_str)
        ]
        cursor.executemany("""
        INSERT INTO buyers (organization_name, contact_person, username, password, buyer_type, target_category, min_order_qty, contact_email, phone, verified, location, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, seed_buyers)

    # Seed Default Artisan
    cursor.execute("SELECT COUNT(*) as cnt FROM artisans WHERE username = 'ramesh_artisan'")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        cursor.execute("""
        INSERT OR REPLACE INTO artisans (id, name, username, password, phone, gender, craft_type, language, location, profile_picture, created_at)
        VALUES (1, 'Ramesh Kumar', 'ramesh_artisan', 'password123', '9876543210', 'Male', 'Master Weaver & Bamboo Craftsman', 'Hindi', 'West Bengal', '', ?)
        """, (now_str,))

    # Seed Default Products
    cursor.execute("SELECT COUNT(*) as cnt FROM products")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        sample_products = [
            (
                1, "ramesh_artisan", "Ramesh Kumar", "West Bengal",
                "Handmade Bamboo Storage Basket",
                "Traditional eco-friendly bamboo basket woven from sustainable river cane. Sturdy, moisture-resistant, and ideal for bulk retail or premium corporate packaging.",
                "प्राकृतिक नदी के बेंत से बुनी गई पारंपरिक पर्यावरण-अनुकूल बांस की टोकरी। मजबूत, नमी प्रतिरोधी और थोक खुदरा या प्रीमियम उपहार के लिए आदर्श।",
                "Bamboo & Cane  ›  Baskets", "Natural Bamboo & Cane", "Handmade • Eco-Friendly • Bamboo • B2B Bulk",
                500.0, 450.0, 400.0, 160.0, 140.0, 2,
                50, 500, 1, 1, 1, 1, 1000, "3–5 days",
                json.dumps([
                    {"tier": "Tier 1", "range": "1–49 pieces", "price": 500.0, "discount": "Standard Price"},
                    {"tier": "Tier 2", "range": "50–99 pieces", "price": 450.0, "discount": "10% Bulk Off"},
                    {"tier": "Tier 3", "range": "100+ pieces", "price": 400.0, "discount": "20% Wholesale Off"}
                ]),
                "/uploads/sample_basket.jpg", "/uploads/enhanced/sample_basket.jpg", "Published", now_str
            ),
            (
                1, "ramesh_artisan", "Ramesh Kumar", "Varanasi, Uttar Pradesh",
                "Handwoven Banarasi Cotton Saree",
                "Exquisite handloom cotton saree with intricate floral Zari border. Breathable weave perfect for retail boutiques and export collections.",
                "पारंपरिक ज़री बॉर्डर के साथ बुनी गई उत्कृष्ट हथकरघा सूती साड़ी। बुटीक और निर्यात संग्रह के लिए उत्तम।",
                "Handloom  ›  Sarees & Textiles", "100% Pure Cotton & Zari Thread", "Handloom • Saree • Traditional • Banarasi",
                1499.0, 1150.0, 950.0, 450.0, 350.0, 4,
                20, 250, 1, 1, 1, 1, 300, "5–7 days",
                json.dumps([
                    {"tier": "Tier 1", "range": "1–19 pieces", "price": 1499.0, "discount": "Retail"},
                    {"tier": "Tier 2", "range": "20–49 pieces", "price": 1150.0, "discount": "Wholesale"},
                    {"tier": "Tier 3", "range": "50+ pieces", "price": 950.0, "discount": "Master Order"}
                ]),
                "/uploads/sample_saree.jpg", "/uploads/enhanced/sample_saree.jpg", "Published", now_str
            ),
            (
                1, "ramesh_artisan", "Shambhu Pal", "Bankura, West Bengal",
                "Traditional Terracotta Clay Water Pitcher",
                "Natural cooling terracotta clay water jug with hand-carved ethnic motifs. 100% chemical-free, biodegradable, and food safe.",
                "हाथ से नक्काशीदार पारंपरिक मिट्टी का मटका, प्राकृतिक रूप से शीतल जल प्रदान करता है।",
                "Pottery  ›  Terracotta & Clay", "Natural Bankura River Clay", "Pottery • Terracotta • Clay • Sustainable",
                650.0, 500.0, 420.0, 150.0, 150.0, 3,
                30, 400, 1, 1, 1, 1, 800, "4–6 days",
                json.dumps([
                    {"tier": "Tier 1", "range": "1–29 pieces", "price": 650.0, "discount": "Standard"},
                    {"tier": "Tier 2", "range": "30–99 pieces", "price": 500.0, "discount": "Wholesale"},
                    {"tier": "Tier 3", "range": "100+ pieces", "price": 420.0, "discount": "Bulk Exporter"}
                ]),
                "/uploads/sample_pot.jpg", "/uploads/enhanced/sample_pot.jpg", "Published", now_str
            ),
            (
                1, "ramesh_artisan", "Sukhram Baghel", "Bastar, Chhattisgarh",
                "Dokra Bell Metal Tribal Figurine",
                "Ancient lost-wax cast bell metal artifact handcrafted by Bastar tribal artisans. Highly sought after by luxury hotels, collectors, and corporate gifting.",
                "बस्तर के जनजातीय कारीगरों द्वारा हस्तनिर्मित प्राचीन खोई-मोम ढलाई डोकरा धातु मूर्ति।",
                "Metal Craft  ›  Dokra Brass", "Brass & Bell Metal Alloy", "Dokra • Brass • Tribal • Heritage",
                1200.0, 950.0, 820.0, 320.0, 350.0, 5,
                15, 150, 1, 1, 1, 1, 250, "7–10 days",
                json.dumps([
                    {"tier": "Tier 1", "range": "1–14 pieces", "price": 1200.0, "discount": "Single Piece"},
                    {"tier": "Tier 2", "range": "15–49 pieces", "price": 950.0, "discount": "B2B Order"},
                    {"tier": "Tier 3", "range": "50+ pieces", "price": 820.0, "discount": "Corporate Order"}
                ]),
                "/uploads/sample_dokra.jpg", "/uploads/enhanced/sample_dokra.jpg", "Published", now_str
            )
        ]
        cursor.executemany("""
        INSERT INTO products (
            artisan_id, artisan_username, artisan_name, artisan_location,
            title, description_en, description_hi, category, materials, tags,
            price_retail, price_wholesale, min_price, material_cost, labor_cost,
            production_days, moq, available_qty, bulk_available, custom_size,
            custom_design, custom_packaging, monthly_capacity, production_time,
            bulk_pricing, raw_image_url, enhanced_image_url, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, sample_products)

        cursor.execute("SELECT id FROM products LIMIT 2")
        pids = [r['id'] for r in cursor.fetchall()]
        sample_enquiries = [
            (
                pids[0], 1, "Sunita Verma", "FabIndia B2B Procurement", "Corporate Wholesale Buyer",
                "+91 98200 11223", "b2b@fabindia.com", "Mumbai, Maharashtra",
                "We wish to order 100 units for our upcoming Diwali festive packaging collection.",
                100, 450.0, 450.0, 1, 1, 1, "Requires custom brand tag with natural twine packaging",
                1, "ramesh_artisan", "New Lead", now_str
            ),
            (
                pids[1] if len(pids) > 1 else pids[0], 2, "Rajesh Sharma", "GeM Government Marketplace", "Government Procurement",
                "+91 11 2345 6789", "procurement@gem.gov.in", "New Delhi",
                "Urgent requirement of 50 handloom cotton sarees for state event gifting.",
                50, 1100.0, 1100.0, 0, 1, 1, "Official GeM procurement tender delivery to Vigyan Bhawan",
                1, "ramesh_artisan", "Offer Received", now_str
            )
        ]
        cursor.executemany("""
        INSERT INTO enquiries (
            product_id, buyer_id, buyer_name, business_name, buyer_type,
            buyer_phone, buyer_email, buyer_location, message, order_quantity,
            offer_price, target_price, custom_size, custom_design, custom_packaging,
            custom_notes, artisan_id, artisan_username, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, sample_enquiries)

    conn.commit()
    conn.close()

# --- Database Operations Abstraction Layer ---

def db_get_dashboard_stats() -> dict:
    if _db_type == "MongoDB" and _mongo_db is not None:
        total_products = _mongo_db.products.count_documents({})
        total_enquiries = _mongo_db.enquiries.count_documents({})
        total_buyers = _mongo_db.buyers.count_documents({})
        return {
            "total_products": total_products,
            "total_enquiries": total_enquiries,
            "total_buyers": total_buyers
        }
    else:
        conn = get_sqlite_conn()
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
            "total_buyers": total_buyers
        }

def db_get_due_orders(artisan_id: int = None, artisan_username: str = None) -> list:
    if artisan_id == 1 or artisan_username in ("ramesh_artisan", "guest"):
        return [
            {
                "id": 101,
                "company_name": "FabIndia B2B Procurement",
                "product_title": "Handmade Bamboo Storage Basket",
                "quantity_due": 100,
                "dispatch_by": "Sept 18, 2026",
                "status": "Ready to Ship",
                "order_value": 45000.0
            },
            {
                "id": 102,
                "company_name": "Tribes India Federation",
                "product_title": "Handwoven Banarasi Cotton Saree",
                "quantity_due": 20,
                "dispatch_by": "Sept 22, 2026",
                "status": "In Production",
                "order_value": 23000.0
            }
        ]
    return []

def db_get_all_products(artisan_id: int = None, artisan_username: str = None, category: str = None, search: str = None) -> list:
    if _db_type == "MongoDB" and _mongo_db is not None:
        query = {}
        if artisan_username or artisan_id is not None:
            or_conds = []
            if artisan_username:
                or_conds.append({"artisan_username": artisan_username})
            if artisan_id is not None:
                or_conds.append({"artisan_id": artisan_id})
            if or_conds:
                query["$or"] = or_conds
        if category and category.lower() != "all":
            query["category"] = {"$regex": category, "$options": "i"}
        if search and search.strip():
            s = search.strip()
            query["$or"] = [
                {"title": {"$regex": s, "$options": "i"}},
                {"materials": {"$regex": s, "$options": "i"}},
                {"tags": {"$regex": s, "$options": "i"}},
                {"category": {"$regex": s, "$options": "i"}},
                {"artisan_location": {"$regex": s, "$options": "i"}},
                {"artisan_name": {"$regex": s, "$options": "i"}}
            ]
        items = list(_mongo_db.products.find(query, {"_id": 0}).sort("id", -1))
        return [_format_product(p) for p in items]
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        conditions = []
        params = []

        if artisan_username or artisan_id is not None:
            conditions.append("(artisan_username = ? OR artisan_id = ?)")
            params.extend([artisan_username or "", artisan_id if artisan_id is not None else -1])

        if category and category.lower() != "all":
            conditions.append("category LIKE ?")
            params.append(f"%{category}%")

        if search and search.strip():
            s = f"%{search.strip()}%"
            conditions.append("(title LIKE ? OR materials LIKE ? OR tags LIKE ? OR category LIKE ? OR artisan_location LIKE ? OR artisan_name LIKE ?)")
            params.extend([s, s, s, s, s, s])

        where_clause = " WHERE " + " AND ".join(conditions) if conditions else ""
        cursor.execute(f"SELECT * FROM products{where_clause} ORDER BY id DESC", params)
        rows = cursor.fetchall()
        conn.close()
        return [_format_product(dict(r)) for r in rows]

def db_get_product_by_id(product_id: int) -> dict:
    if _db_type == "MongoDB" and _mongo_db is not None:
        item = _mongo_db.products.find_one({"id": product_id}, {"_id": 0})
        return _format_product(item) if item else None
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM products WHERE id = ?", (product_id,))
        row = cursor.fetchone()
        conn.close()
        return _format_product(dict(row)) if row else None

def db_create_product(product_data: dict) -> int:
    now_str = datetime.now().isoformat()
    art_id = product_data.get("artisan_id", 1)
    art_username = (product_data.get("artisan_username") or "ramesh_artisan").strip()
    art_name = (product_data.get("artisan_name") or "Ramesh Kumar").strip()
    art_loc = (product_data.get("artisan_location") or "West Bengal").strip()

    moq = int(product_data.get("moq") or 50)
    avail_qty = int(product_data.get("available_qty") or 500)
    bulk_avail = 1 if product_data.get("bulk_available") in (1, True, "1", "true") else 1
    custom_sz = 1 if product_data.get("custom_size") in (1, True, "1", "true") else 1
    custom_ds = 1 if product_data.get("custom_design") in (1, True, "1", "true") else 1
    custom_pk = 1 if product_data.get("custom_packaging") in (1, True, "1", "true") else 1
    monthly_cap = int(product_data.get("monthly_capacity") or 1000)
    prod_time = product_data.get("production_time") or "3–5 days"
    bulk_pricing = product_data.get("bulk_pricing") or ""
    if isinstance(bulk_pricing, (list, dict)):
        bulk_pricing = json.dumps(bulk_pricing)

    if _db_type == "MongoDB" and _mongo_db is not None:
        highest = _mongo_db.products.find_one({}, sort=[("id", -1)])
        next_id = (highest["id"] + 1) if highest and "id" in highest else 1
        
        doc = {
            "id": next_id,
            "artisan_id": art_id,
            "artisan_username": art_username,
            "artisan_name": art_name,
            "artisan_location": art_loc,
            "title": product_data["title"],
            "description_en": product_data["description_en"],
            "description_hi": product_data["description_hi"],
            "category": product_data["category"],
            "materials": product_data["materials"],
            "tags": product_data["tags"],
            "price_retail": product_data["price_retail"],
            "price_wholesale": product_data["price_wholesale"],
            "min_price": product_data["min_price"],
            "material_cost": product_data["material_cost"],
            "labor_cost": product_data["labor_cost"],
            "production_days": product_data.get("production_days", 2),
            "moq": moq,
            "available_qty": avail_qty,
            "bulk_available": bulk_avail,
            "custom_size": custom_sz,
            "custom_design": custom_ds,
            "custom_packaging": custom_pk,
            "monthly_capacity": monthly_cap,
            "production_time": prod_time,
            "bulk_pricing": bulk_pricing,
            "raw_image_url": product_data.get("raw_image_url", ""),
            "enhanced_image_url": product_data.get("enhanced_image_url", ""),
            "type_of_art": product_data.get("type_of_art", "Traditional Indian Craft"),
            "status": "Published",
            "created_at": now_str
        }
        _mongo_db.products.insert_one(doc)
        return next_id
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO products (
            artisan_id, artisan_username, artisan_name, artisan_location,
            title, description_en, description_hi, category, materials, tags,
            price_retail, price_wholesale, min_price, material_cost, labor_cost,
            production_days, moq, available_qty, bulk_available, custom_size,
            custom_design, custom_packaging, monthly_capacity, production_time,
            bulk_pricing, raw_image_url, enhanced_image_url, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            art_id, art_username, art_name, art_loc,
            product_data["title"], product_data["description_en"], product_data["description_hi"],
            product_data["category"], product_data["materials"], product_data["tags"],
            product_data["price_retail"], product_data["price_wholesale"], product_data["min_price"],
            product_data["material_cost"], product_data["labor_cost"],
            product_data.get("production_days", 2),
            moq, avail_qty, bulk_avail, custom_sz, custom_ds, custom_pk, monthly_cap, prod_time,
            bulk_pricing, product_data.get("raw_image_url", ""), product_data.get("enhanced_image_url", ""),
            "Published", now_str
        ))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return new_id

def db_delete_product(product_id: int) -> bool:
    if _db_type == "MongoDB" and _mongo_db is not None:
        res = _mongo_db.products.delete_one({"id": product_id})
        return res.deleted_count > 0
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM products WHERE id = ?", (product_id,))
        conn.commit()
        conn.close()
        return True

def db_get_verified_buyers(category_filter: str = "") -> list:
    if _db_type == "MongoDB" and _mongo_db is not None:
        query = {}
        if category_filter:
            query = {"target_category": {"$regex": category_filter, "$options": "i"}}
        items = list(_mongo_db.buyers.find(query, {"_id": 0, "password": 0}).sort("id", 1))
        return items
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        if category_filter:
            cursor.execute("SELECT id, organization_name, contact_person, username, buyer_type, target_category, min_order_qty, contact_email, phone, verified, location, created_at FROM buyers WHERE target_category LIKE ? ORDER BY id ASC", (f"%{category_filter}%",))
        else:
            cursor.execute("SELECT id, organization_name, contact_person, username, buyer_type, target_category, min_order_qty, contact_email, phone, verified, location, created_at FROM buyers ORDER BY id ASC")
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

# --- Buyer Registration & Login ---

def db_register_buyer(buyer_data: dict) -> dict:
    now_str = datetime.now().isoformat()
    org_name = (buyer_data.get("organization_name") or buyer_data.get("business_name") or "").strip()
    contact_person = (buyer_data.get("contact_person") or buyer_data.get("name") or "").strip()
    username = (buyer_data.get("username") or org_name.lower().replace(" ", "_")).strip()
    password = buyer_data.get("password") or "password123"
    phone = (buyer_data.get("phone") or "").strip()
    email = (buyer_data.get("contact_email") or buyer_data.get("email") or "").strip()
    buyer_type = buyer_data.get("buyer_type") or "Wholesale Buyer"
    location = (buyer_data.get("location") or "India").strip()
    target_category = buyer_data.get("target_category") or "Handicrafts & Handlooms"
    min_order_qty = int(buyer_data.get("min_order_qty") or 25)

    if not org_name:
        raise ValueError("Business / Organization name is required.")
    if not username:
        raise ValueError("Username is required.")

    if _db_type == "MongoDB" and _mongo_db is not None:
        existing = _mongo_db.buyers.find_one({"$or": [{"username": username}, {"contact_email": email}, {"phone": phone}]})
        if existing:
            if existing.get("username") == username:
                raise ValueError("Buyer username already taken. Please pick another.")
            if email and existing.get("contact_email") == email:
                raise ValueError("Email already registered. Please log in.")
        
        highest = _mongo_db.buyers.find_one({}, sort=[("id", -1)])
        next_id = (highest["id"] + 1) if highest and "id" in highest else 1
        doc = {
            "id": next_id,
            "organization_name": org_name,
            "contact_person": contact_person,
            "username": username,
            "password": password,
            "buyer_type": buyer_type,
            "target_category": target_category,
            "min_order_qty": min_order_qty,
            "contact_email": email,
            "phone": phone,
            "verified": 1,
            "location": location,
            "created_at": now_str
        }
        _mongo_db.buyers.insert_one(doc)
        doc.pop("_id", None)
        doc.pop("password", None)
        return doc
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM buyers WHERE username = ? OR (phone != '' AND phone = ?) OR (contact_email != '' AND contact_email = ?)", (username, phone, email))
        existing = cursor.fetchone()
        if existing:
            conn.close()
            raise ValueError("Buyer username, phone, or email is already registered.")

        cursor.execute("""
        INSERT INTO buyers (organization_name, contact_person, username, password, buyer_type, target_category, min_order_qty, contact_email, phone, verified, location, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (org_name, contact_person, username, password, buyer_type, target_category, min_order_qty, email, phone, 1, location, now_str))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return {
            "id": new_id,
            "organization_name": org_name,
            "contact_person": contact_person,
            "username": username,
            "buyer_type": buyer_type,
            "target_category": target_category,
            "min_order_qty": min_order_qty,
            "contact_email": email,
            "phone": phone,
            "verified": 1,
            "location": location,
            "created_at": now_str
        }

def db_login_buyer(username_input: str, password_input: str) -> dict:
    uname = (username_input or "").strip()
    pwd = (password_input or "").strip()

    if _db_type == "MongoDB" and _mongo_db is not None:
        user = _mongo_db.buyers.find_one({"$or": [{"username": uname}, {"contact_email": uname}, {"phone": uname}]})
        if not user:
            return None
        if user.get("password") == pwd:
            d = dict(user)
            d.pop("_id", None)
            d.pop("password", None)
            return d
        return None
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM buyers WHERE username = ? OR contact_email = ? OR phone = ?", (uname, uname, uname))
        row = cursor.fetchone()
        conn.close()
        if not row:
            return None
        d = dict(row)
        if d.get("password") == pwd:
            d.pop("password", None)
            return d
        return None

# --- B2B Enquiries (The Heart of the Marketplace) ---

def db_create_enquiry(enquiry_data: dict) -> dict:
    now_str = datetime.now().isoformat()
    product_id = int(enquiry_data.get("product_id", 0))
    buyer_name = (enquiry_data.get("buyer_name") or enquiry_data.get("contact_person") or "Business Buyer").strip()
    business_name = (enquiry_data.get("business_name") or enquiry_data.get("organization_name") or buyer_name).strip()
    buyer_type = (enquiry_data.get("buyer_type") or "Wholesale Buyer").strip()
    buyer_phone = (enquiry_data.get("buyer_phone") or enquiry_data.get("phone") or "").strip()
    buyer_email = (enquiry_data.get("buyer_email") or enquiry_data.get("email") or "").strip()
    buyer_location = (enquiry_data.get("buyer_location") or enquiry_data.get("location") or "India").strip()
    buyer_id = int(enquiry_data.get("buyer_id") or 0)
    order_quantity = int(enquiry_data.get("order_quantity") or enquiry_data.get("quantity") or 50)
    offer_price = float(enquiry_data.get("offer_price") or enquiry_data.get("unit_price") or 0.0)
    target_price = float(enquiry_data.get("target_price") or offer_price)
    message = (enquiry_data.get("message") or "").strip()
    custom_size = 1 if enquiry_data.get("custom_size") in (1, True, "1", "true") else 0
    custom_design = 1 if enquiry_data.get("custom_design") in (1, True, "1", "true") else 0
    custom_packaging = 1 if enquiry_data.get("custom_packaging") in (1, True, "1", "true") else 0
    custom_notes = (enquiry_data.get("custom_notes") or "").strip()
    status = enquiry_data.get("status") or "New Lead"

    # Fetch product metadata to populate artisan ID & title
    prod = db_get_product_by_id(product_id)
    artisan_id = prod.get("artisan_id", 1) if prod else 1
    artisan_username = prod.get("artisan_username", "ramesh_artisan") if prod else "ramesh_artisan"
    product_title = prod.get("title", "Artisan Craft") if prod else "Artisan Craft"
    if offer_price <= 0 and prod:
        offer_price = float(prod.get("price_wholesale") or prod.get("price_retail") or 450.0)
        target_price = offer_price

    if _db_type == "MongoDB" and _mongo_db is not None:
        highest = _mongo_db.enquiries.find_one({}, sort=[("id", -1)])
        next_id = (highest["id"] + 1) if highest and "id" in highest else 1
        doc = {
            "id": next_id,
            "product_id": product_id,
            "product_title": product_title,
            "buyer_id": buyer_id,
            "buyer_name": buyer_name,
            "business_name": business_name,
            "buyer_type": buyer_type,
            "buyer_phone": buyer_phone,
            "buyer_email": buyer_email,
            "buyer_location": buyer_location,
            "order_quantity": order_quantity,
            "offer_price": offer_price,
            "target_price": target_price,
            "message": message,
            "custom_size": custom_size,
            "custom_design": custom_design,
            "custom_packaging": custom_packaging,
            "custom_notes": custom_notes,
            "artisan_id": artisan_id,
            "artisan_username": artisan_username,
            "status": status,
            "created_at": now_str
        }
        _mongo_db.enquiries.insert_one(doc)
        doc.pop("_id", None)
        return doc
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO enquiries (
            product_id, buyer_id, buyer_name, business_name, buyer_type,
            buyer_phone, buyer_email, buyer_location, message, order_quantity,
            offer_price, target_price, custom_size, custom_design, custom_packaging,
            custom_notes, artisan_id, artisan_username, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            product_id, buyer_id, buyer_name, business_name, buyer_type,
            buyer_phone, buyer_email, buyer_location, message, order_quantity,
            offer_price, target_price, custom_size, custom_design, custom_packaging,
            custom_notes, artisan_id, artisan_username, status, now_str
        ))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return {
            "id": new_id,
            "product_id": product_id,
            "product_title": product_title,
            "buyer_name": buyer_name,
            "business_name": business_name,
            "buyer_type": buyer_type,
            "buyer_phone": buyer_phone,
            "buyer_email": buyer_email,
            "buyer_location": buyer_location,
            "order_quantity": order_quantity,
            "offer_price": offer_price,
            "target_price": target_price,
            "message": message,
            "custom_size": custom_size,
            "custom_design": custom_design,
            "custom_packaging": custom_packaging,
            "custom_notes": custom_notes,
            "artisan_id": artisan_id,
            "artisan_username": artisan_username,
            "status": status,
            "created_at": now_str
        }

def db_get_product_enquiries(product_id: int = None, artisan_id: int = None, artisan_username: str = None, buyer_id: int = None, buyer_name: str = None) -> list:
    if _db_type == "MongoDB" and _mongo_db is not None:
        query = {}
        if product_id:
            query["product_id"] = product_id
        if artisan_id:
            query["artisan_id"] = artisan_id
        if artisan_username:
            query["artisan_username"] = artisan_username
        if buyer_id:
            query["buyer_id"] = buyer_id
        if buyer_name:
            query["$or"] = [{"buyer_name": buyer_name}, {"business_name": buyer_name}]
        
        items = list(_mongo_db.enquiries.find(query, {"_id": 0}).sort("id", -1))
        for item in items:
            if "product_title" not in item or not item["product_title"]:
                prod = _mongo_db.products.find_one({"id": item.get("product_id")})
                if prod:
                    item["product_title"] = prod.get("title", "Craft")
                    item["product_category"] = prod.get("category", "")
                    item["enhanced_image_url"] = prod.get("enhanced_image_url", "")
                    item["raw_image_url"] = prod.get("raw_image_url", "")
        return items
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        conditions = []
        params = []
        if product_id:
            conditions.append("e.product_id = ?")
            params.append(product_id)
        if artisan_id:
            conditions.append("e.artisan_id = ?")
            params.append(artisan_id)
        if artisan_username:
            conditions.append("e.artisan_username = ?")
            params.append(artisan_username)
        if buyer_id:
            conditions.append("e.buyer_id = ?")
            params.append(buyer_id)
        if buyer_name:
            conditions.append("(e.buyer_name = ? OR e.business_name = ?)")
            params.extend([buyer_name, buyer_name])

        where_clause = " WHERE " + " AND ".join(conditions) if conditions else ""
        query = f"""
        SELECT e.*, p.title as product_title, p.category as product_category,
               p.raw_image_url, p.enhanced_image_url, p.price_retail, p.price_wholesale,
               p.artisan_name as product_artisan_name, p.artisan_location as product_artisan_location
        FROM enquiries e
        LEFT JOIN products p ON e.product_id = p.id
        {where_clause}
        ORDER BY e.id DESC
        """
        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

def db_update_enquiry_status(enquiry_id: int, new_status: str) -> bool:
    if _db_type == "MongoDB" and _mongo_db is not None:
        res = _mongo_db.enquiries.update_one({"id": enquiry_id}, {"$set": {"status": new_status}})
        return res.modified_count > 0
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("UPDATE enquiries SET status = ? WHERE id = ?", (new_status, enquiry_id))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

def db_get_ai_recommendations(category: str = None, limit: int = 4) -> list:
    all_prods = db_get_all_products(category=category)
    # Rank products with high monthly capacity, bulk discount, and verified artisan
    sorted_prods = sorted(all_prods, key=lambda x: (x.get("monthly_capacity", 0), x.get("available_qty", 0)), reverse=True)
    return sorted_prods[:limit]

# --- Artisan Registration & Profile Operations ---

def db_register_artisan(artisan_data: dict) -> dict:
    now_str = datetime.now().isoformat()
    username = (artisan_data.get("username") or "").strip()
    phone = (artisan_data.get("phone") or "").strip()
    password = artisan_data.get("password") or ""
    full_name = (artisan_data.get("full_name") or artisan_data.get("name") or "").strip()
    gender = artisan_data.get("gender") or "Male"
    craft_type = artisan_data.get("craft_type") or "Handloom & Handicrafts"
    address = (artisan_data.get("address") or artisan_data.get("location") or "").strip() or "West Bengal"

    if _db_type == "MongoDB" and _mongo_db is not None:
        existing = _mongo_db.artisans.find_one({
            "$or": [{"username": username}, {"phone": phone}]
        })
        if existing:
            if existing.get("username") == username:
                raise ValueError("Username is already taken. Please choose another username.")
            if existing.get("phone") == phone:
                raise ValueError("Phone number is already registered. Please log in.")

        highest = _mongo_db.artisans.find_one({}, sort=[("id", -1)])
        next_id = (highest["id"] + 1) if highest and "id" in highest else 1

        doc = {
            "id": next_id,
            "name": full_name,
            "username": username,
            "password": password,
            "phone": phone,
            "gender": gender,
            "craft_type": craft_type,
            "language": "English",
            "location": address,
            "profile_picture": (artisan_data.get("profile_picture") or "").strip(),
            "created_at": now_str
        }
        _mongo_db.artisans.insert_one(doc)
        doc_res = dict(doc)
        doc_res.pop("password", None)
        doc_res.pop("_id", None)
        return doc_res
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM artisans WHERE username = ? OR phone = ?", (username, phone))
        existing = cursor.fetchone()
        if existing:
            existing_dict = dict(existing)
            if existing_dict.get("username") == username:
                conn.close()
                raise ValueError("Username is already taken. Please choose another username.")
            if existing_dict.get("phone") == phone:
                conn.close()
                raise ValueError("Phone number is already registered. Please log in.")

        profile_pic_val = (artisan_data.get("profile_picture") or "").strip()
        cursor.execute("""
        INSERT INTO artisans (name, username, password, phone, gender, craft_type, language, location, profile_picture, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (full_name, username, password, phone, gender, craft_type, "English", address, profile_pic_val, now_str))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()

        return {
            "id": new_id,
            "name": full_name,
            "username": username,
            "phone": phone,
            "gender": gender,
            "craft_type": craft_type,
            "location": address,
            "profile_picture": profile_pic_val,
            "created_at": now_str
        }

def db_login_artisan(username_input: str, password_input: str) -> dict:
    uname = (username_input or "").strip()
    pwd = (password_input or "").strip()

    if _db_type == "MongoDB" and _mongo_db is not None:
        user = _mongo_db.artisans.find_one({
            "$or": [{"username": uname}, {"phone": uname}]
        })
        if not user:
            return None
        if user.get("password") == pwd:
            user_dict = dict(user)
            user_dict.pop("password", None)
            user_dict.pop("_id", None)
            user_dict["profile_picture"] = user_dict.get("profile_picture") or ""
            return user_dict
        return None
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM artisans WHERE username = ? OR phone = ?", (uname, uname))
        row = cursor.fetchone()
        conn.close()
        if not row:
            return None
        user_dict = dict(row)
        if user_dict.get("password") == pwd:
            user_dict.pop("password", None)
            user_dict["profile_picture"] = user_dict.get("profile_picture") or ""
            return user_dict
        return None

def db_update_artisan_profile(profile_data: dict) -> dict:
    username = (profile_data.get("username") or "").strip()
    phone = (profile_data.get("phone") or "").strip()
    full_name = (profile_data.get("full_name") or profile_data.get("name") or "").strip()
    gender = (profile_data.get("gender") or "").strip()
    craft_type = (profile_data.get("craft_type") or "").strip()
    location = (profile_data.get("location") or profile_data.get("address") or "").strip()
    profile_picture = profile_data.get("profile_picture")

    if not username and not phone:
        raise ValueError("Username or phone is required to update profile.")

    if _db_type == "MongoDB" and _mongo_db is not None:
        user = None
        if username:
            user = _mongo_db.artisans.find_one({"username": username})
        if not user and phone:
            user = _mongo_db.artisans.find_one({"phone": phone})
        if not user and username:
            user = _mongo_db.artisans.find_one({"phone": username})
        if not user:
            raise ValueError("Artisan record not found for update.")

        update_fields = {}
        if full_name: update_fields["name"] = full_name
        if phone: update_fields["phone"] = phone
        if gender: update_fields["gender"] = gender
        if craft_type: update_fields["craft_type"] = craft_type
        if location: update_fields["location"] = location
        if profile_picture is not None: update_fields["profile_picture"] = profile_picture

        _mongo_db.artisans.update_one(
            {"_id": user["_id"]},
            {"$set": update_fields}
        )
        updated_doc = _mongo_db.artisans.find_one({"_id": user["_id"]}, {"_id": 0, "password": 0})
        updated_doc["profile_picture"] = updated_doc.get("profile_picture") or ""
        return updated_doc
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM artisans WHERE username = ? OR phone = ? OR phone = ?", (username, phone, username))
        row = cursor.fetchone()
        if not row:
            conn.close()
            raise ValueError("Artisan record not found for update.")
        
        user_dict = dict(row)
        art_id = user_dict["id"]

        new_name = full_name or user_dict.get("name")
        new_phone = phone or user_dict.get("phone")
        new_gender = gender or user_dict.get("gender")
        new_craft = craft_type or user_dict.get("craft_type")
        new_loc = location or user_dict.get("location")
        new_pic = profile_picture if profile_picture is not None else user_dict.get("profile_picture", "")

        cursor.execute("""
        UPDATE artisans
        SET name = ?, phone = ?, gender = ?, craft_type = ?, location = ?, profile_picture = ?
        WHERE id = ?
        """, (new_name, new_phone, new_gender, new_craft, new_loc, new_pic, art_id))
        conn.commit()

        cursor.execute("SELECT * FROM artisans WHERE id = ?", (art_id,))
        updated_row = dict(cursor.fetchone())
        conn.close()
        updated_row.pop("password", None)
        updated_row["profile_picture"] = updated_row.get("profile_picture") or ""
        return updated_row

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
