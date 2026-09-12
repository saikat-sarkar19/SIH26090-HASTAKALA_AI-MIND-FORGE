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
    client = pymongo.MongoClient(clean_uri, serverSelectionTimeoutMS=5000)
    # Ping database server
    client.admin.command('ping')

    db = client[MONGODB_DB_NAME]
    _mongo_client = client
    _mongo_db = db
    _db_type = "MongoDB"
    _current_mongodb_uri = clean_uri

    _seed_mongodb()
    return True

def _seed_mongodb():
    global _mongo_db
    if _mongo_db is None:
        return

    now_str = datetime.now().isoformat()

    # 1. Buyers
    if _mongo_db.buyers.count_documents({}) == 0:
        seed_buyers = [
            {"id": 1, "organization_name": "GeM Government Portal", "buyer_type": "Government Marketplace", "target_category": "Handloom, Handicrafts, Bamboo", "min_order_qty": 50, "contact_email": "gem_orders@gov.in", "phone": "+91 11 2345 6789", "verified": 1, "location": "New Delhi"},
            {"id": 2, "organization_name": "Tribes India Craftsvilla", "buyer_type": "Cooperative Federation", "target_category": "Handwoven Textiles, Terracotta", "min_order_qty": 20, "contact_email": "procurement@tribesindia.com", "phone": "+91 11 9876 5432", "verified": 1, "location": "New Delhi"},
            {"id": 3, "organization_name": "FabIndia B2B Handicrafts", "buyer_type": "Corporate Wholesale Buyer", "target_category": "Home Decor, Baskets, Wood Craft", "min_order_qty": 100, "contact_email": "b2b@fabindia.com", "phone": "+91 22 4433 2211", "verified": 1, "location": "Mumbai"},
            {"id": 4, "organization_name": "Surajkund Artisans Collective", "buyer_type": "Fair Organizers & Exporters", "target_category": "Sarees, Pottery, Metal Craft", "min_order_qty": 15, "contact_email": "buyers@surajkund.org", "phone": "+91 129 251 1234", "verified": 1, "location": "Haryana"}
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
                "location": "Varanasi, UP",
                "created_at": now_str
            }},
            upsert=True
        )


    # 3. Products
    if _mongo_db.products.count_documents({}) == 0:
        sample_products = [
            {"id": 1, "artisan_id": 1, "title": "Handwoven Banarasi Cotton Saree",
             "description_en": "Exquisite handloom cotton saree woven with traditional Zari motifs. Soft, breathable, and ideal for festive occasions.",
             "description_hi": "पारंपरिक ज़री रूपांकनों के साथ बुनी गई उत्कृष्ट हथकरघा सूती साड़ी। नरम, हवादार और उत्सव के अवसरों के लिए आदर्श।",
             "category": "Textiles  ›  Sarees", "materials": "100% Pure Cotton, Zari Thread", "tags": "Handloom • Saree • Traditional • Banarasi",
             "price_retail": 1499.0, "price_wholesale": 1150.0, "min_price": 950.0, "material_cost": 450.0, "labor_cost": 350.0, "production_days": 4,
             "raw_image_url": "/uploads/sample_saree.jpg", "enhanced_image_url": "/uploads/enhanced/sample_saree.jpg", "status": "Published", "created_at": now_str},
            {"id": 2, "artisan_id": 1, "title": "Eco-Friendly Handwoven Bamboo Basket",
             "description_en": "Durable and stylish bamboo storage basket handcrafted by rural artisans using natural bamboo strips.",
             "description_hi": "प्राकृतिक बांस की पट्टियों का उपयोग करके ग्रामीण कारीगरों द्वारा हस्तनिर्मित टिकाऊ और स्टाइलिश बांस टोकरी।",
             "category": "Home Decor  ›  Baskets", "materials": "Natural Bamboo", "tags": "Handmade • Eco-friendly • Bamboo • Storage",
             "price_retail": 799.0, "price_wholesale": 580.0, "min_price": 450.0, "material_cost": 180.0, "labor_cost": 150.0, "production_days": 2,
             "raw_image_url": "/uploads/sample_basket.jpg", "enhanced_image_url": "/uploads/enhanced/sample_basket.jpg", "status": "Published", "created_at": now_str},
            {"id": 3, "artisan_id": 1, "title": "Traditional Terracotta Clay Water Pot",
             "description_en": "Natural cooling clay water pitcher with hand-carved ethnic patterns, chemical-free and sustainable.",
             "description_hi": "हाथ से नक्काशीदार पारंपरिक मिट्टी का मटका, प्राकृतिक रूप से शीतल जल प्रदान करता है।",
             "category": "Kitchen & Dining  ›  Pottery", "materials": "Natural Clay", "tags": "Pottery • Terracotta • Clay • Eco",
             "price_retail": 899.0, "price_wholesale": 650.0, "min_price": 500.0, "material_cost": 200.0, "labor_cost": 220.0, "production_days": 3,
             "raw_image_url": "/uploads/sample_pot.jpg", "enhanced_image_url": "/uploads/enhanced/sample_pot.jpg", "status": "Published", "created_at": now_str}
        ]
        _mongo_db.products.insert_many(sample_products)

    # 4. Enquiries
    if _mongo_db.enquiries.count_documents({}) == 0:
        sample_enquiries = [
            {"id": 1, "product_id": 1, "buyer_name": "Tribes India Federation", "buyer_type": "Cooperative Federation", "message": "We wish to place a bulk order of 25 sarees for the Shilp Samagam exhibition.", "order_quantity": 25, "offer_price": 1100.0, "status": "New Lead", "created_at": now_str},
            {"id": 2, "product_id": 2, "buyer_name": "GeM E-Marketplace Procurement", "buyer_type": "Government Marketplace", "message": "Urgent requirement of 100 eco-friendly bamboo baskets for government office gifting.", "order_quantity": 100, "offer_price": 550.0, "status": "Offer Received", "created_at": now_str},
            {"id": 3, "product_id": 1, "buyer_name": "FabIndia Retail Outlet", "buyer_type": "Corporate Wholesale Buyer", "message": "Inquiry for seasonal collection order of 50 handloom sarees.", "order_quantity": 50, "offer_price": 1150.0, "status": "Under Review", "created_at": now_str}
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

    # SQLite Fallback Init
    _db_type = "SQLite"
    conn = get_sqlite_conn()
    cursor = conn.cursor()
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
        location TEXT DEFAULT 'Varanasi, Uttar Pradesh',
        profile_picture TEXT DEFAULT '',
        created_at TEXT NOT NULL
    );
    """)

    cursor.execute("PRAGMA table_info(artisans)")
    existing_cols = [r[1] for r in cursor.fetchall()]
    col_definitions = [
        ("username", "TEXT"),
        ("password", "TEXT"),
        ("gender", "TEXT DEFAULT 'Male'"),
        ("craft_type", "TEXT DEFAULT 'Handloom & Handicrafts'"),
        ("location", "TEXT DEFAULT 'India'"),
        ("profile_picture", "TEXT DEFAULT ''"),
    ]
    for col_name, col_type in col_definitions:
        if col_name not in existing_cols:
            try:
                cursor.execute(f"ALTER TABLE artisans ADD COLUMN {col_name} {col_type}")
                conn.commit()
            except Exception as e:
                print(f"Migration note for {col_name}: {e}")
    conn.commit()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artisan_id INTEGER DEFAULT 1,
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
        raw_image_url TEXT,
        enhanced_image_url TEXT,
        status TEXT DEFAULT 'Published',
        created_at TEXT NOT NULL
    );
    """)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS buyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        organization_name TEXT NOT NULL,
        buyer_type TEXT NOT NULL,
        target_category TEXT NOT NULL,
        min_order_qty INTEGER DEFAULT 10,
        contact_email TEXT,
        phone TEXT,
        verified INTEGER DEFAULT 1,
        location TEXT
    );
    """)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS enquiries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        buyer_name TEXT NOT NULL,
        buyer_type TEXT NOT NULL,
        message TEXT NOT NULL,
        order_quantity INTEGER NOT NULL,
        offer_price REAL NOT NULL,
        status TEXT DEFAULT 'New Lead',
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
    );
    """)

    cursor.execute("SELECT COUNT(*) as cnt FROM buyers")
    if cursor.fetchone()['cnt'] == 0:
        seed_buyers = [
            ("GeM Government Portal", "Government Marketplace", "Handloom, Handicrafts, Bamboo", 50, "gem_orders@gov.in", "+91 11 2345 6789", 1, "New Delhi"),
            ("Tribes India Craftsvilla", "Cooperative Federation", "Handwoven Textiles, Terracotta", 20, "procurement@tribesindia.com", "+91 11 9876 5432", 1, "New Delhi"),
            ("FabIndia B2B Handicrafts", "Corporate Wholesale Buyer", "Home Decor, Baskets, Wood Craft", 100, "b2b@fabindia.com", "+91 22 4433 2211", 1, "Mumbai"),
            ("Surajkund Artisans Collective", "Fair Organizers & Exporters", "Sarees, Pottery, Metal Craft", 15, "buyers@surajkund.org", "+91 129 251 1234", 1, "Haryana")
        ]
        cursor.executemany("""
        INSERT INTO buyers (organization_name, buyer_type, target_category, min_order_qty, contact_email, phone, verified, location)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, seed_buyers)

    cursor.execute("SELECT COUNT(*) as cnt FROM artisans WHERE username = 'ramesh_artisan'")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        cursor.execute("""
        INSERT OR REPLACE INTO artisans (id, name, username, password, phone, gender, craft_type, language, location, profile_picture, created_at)
        VALUES (1, 'Ramesh Kumar', 'ramesh_artisan', 'password123', '9876543210', 'Male', 'Master Weaver & Bamboo Craftsman', 'Hindi', 'Varanasi, UP', '', ?)
        """, (now_str,))


    cursor.execute("SELECT COUNT(*) as cnt FROM products")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        sample_products = [
            (1, "Handwoven Banarasi Cotton Saree", 
             "Exquisite handloom cotton saree woven with traditional Zari motifs. Soft, breathable, and ideal for festive occasions.",
             "पारंपरिक ज़री रूपांकनों के साथ बुनी गई उत्कृष्ट हथकरघा सूती साड़ी। नरम, हवादार और उत्सव के अवसरों के लिए आदर्श।",
             "Textiles  ›  Sarees", "100% Pure Cotton, Zari Thread", "Handloom • Saree • Traditional • Banarasi",
             1499.0, 1150.0, 950.0, 450.0, 350.0, 4,
             "/uploads/sample_saree.jpg", "/uploads/enhanced/sample_saree.jpg", "Published", now_str),
            (1, "Eco-Friendly Handwoven Bamboo Basket",
             "Durable and stylish bamboo storage basket handcrafted by rural artisans using natural bamboo strips.",
             "प्राकृतिक बांस की पट्टियों का उपयोग करके ग्रामीण कारीगरों द्वारा हस्तनिर्मित टिकाऊ और स्टाइलिश बांस टोकरी।",
             "Home Decor  ›  Baskets", "Natural Bamboo", "Handmade • Eco-friendly • Bamboo • Storage",
             799.0, 580.0, 450.0, 180.0, 150.0, 2,
             "/uploads/sample_basket.jpg", "/uploads/enhanced/sample_basket.jpg", "Published", now_str),
            (1, "Traditional Terracotta Clay Water Pot",
             "Natural cooling clay water pitcher with hand-carved ethnic patterns, chemical-free and sustainable.",
             "हाथ से नक्काशीदार पारंपरिक मिट्टी का मटका, प्राकृतिक रूप से शीतल जल प्रदान करता है।",
             "Kitchen & Dining  ›  Pottery", "Natural Clay", "Pottery • Terracotta • Clay • Eco",
             899.0, 650.0, 500.0, 200.0, 220.0, 3,
             "/uploads/sample_pot.jpg", "/uploads/enhanced/sample_pot.jpg", "Published", now_str)
        ]
        cursor.executemany("""
        INSERT INTO products (artisan_id, title, description_en, description_hi, category, materials, tags, price_retail, price_wholesale, min_price, material_cost, labor_cost, production_days, raw_image_url, enhanced_image_url, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, sample_products)

        cursor.execute("SELECT id FROM products LIMIT 2")
        pids = [r['id'] for r in cursor.fetchall()]
        sample_enquiries = [
            (pids[0], "Tribes India Federation", "Cooperative Federation", "We wish to place a bulk order of 25 sarees for the Shilp Samagam exhibition.", 25, 1100.0, "New Lead", now_str),
            (pids[1], "GeM E-Marketplace Procurement", "Government Marketplace", "Urgent requirement of 100 eco-friendly bamboo baskets for government office gifting.", 100, 550.0, "Offer Received", now_str),
            (pids[0], "FabIndia Retail Outlet", "Corporate Wholesale Buyer", "Inquiry for seasonal collection order of 50 handloom sarees.", 50, 1150.0, "Under Review", now_str)
        ]
        cursor.executemany("""
        INSERT INTO enquiries (product_id, buyer_name, buyer_type, message, order_quantity, offer_price, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
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
    if artisan_id == 1 or artisan_username == "ramesh_artisan":
        return [
            {
                "id": 101,
                "company_name": "FabIndia Retail Outlet",
                "product_title": "Handwoven Banarasi Cotton Sarees",
                "quantity_due": 25,
                "dispatch_by": "Sept 16, 2026",
                "status": "Ready to Ship",
                "order_value": 28750.0
            },
            {
                "id": 102,
                "company_name": "Tribes India B2B Hub",
                "product_title": "Handcrafted Eco Bamboo Storage Baskets",
                "quantity_due": 50,
                "dispatch_by": "Sept 18, 2026",
                "status": "Packing Complete",
                "order_value": 29000.0
            }
        ]
    return []

def db_get_all_products(artisan_id: int = None, artisan_username: str = None) -> list:
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
        items = list(_mongo_db.products.find(query, {"_id": 0}).sort("id", -1))
        return items
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        if artisan_username or artisan_id is not None:
            cursor.execute(
                "SELECT * FROM products WHERE artisan_username = ? OR artisan_id = ? ORDER BY id DESC",
                (artisan_username or "", artisan_id if artisan_id is not None else -1)
            )
        else:
            cursor.execute("SELECT * FROM products ORDER BY id DESC")
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

def db_get_product_by_id(product_id: int) -> dict:
    if _db_type == "MongoDB" and _mongo_db is not None:
        item = _mongo_db.products.find_one({"id": product_id}, {"_id": 0})
        return item
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM products WHERE id = ?", (product_id,))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

def db_create_product(product_data: dict) -> int:
    now_str = datetime.now().isoformat()
    art_id = product_data.get("artisan_id", 1)
    art_username = (product_data.get("artisan_username") or "").strip()

    if _db_type == "MongoDB" and _mongo_db is not None:
        highest = _mongo_db.products.find_one({}, sort=[("id", -1)])
        next_id = (highest["id"] + 1) if highest and "id" in highest else 1
        
        doc = {
            "id": next_id,
            "artisan_id": art_id,
            "artisan_username": art_username,
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
            "raw_image_url": product_data.get("raw_image_url", ""),
            "enhanced_image_url": product_data.get("enhanced_image_url", ""),
            "status": "Published",
            "created_at": now_str
        }
        _mongo_db.products.insert_one(doc)
        return next_id
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO products (artisan_id, artisan_username, title, description_en, description_hi, category, materials, tags, price_retail, price_wholesale, min_price, material_cost, labor_cost, production_days, raw_image_url, enhanced_image_url, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            art_id, art_username, product_data["title"], product_data["description_en"], product_data["description_hi"],
            product_data["category"], product_data["materials"], product_data["tags"],
            product_data["price_retail"], product_data["price_wholesale"], product_data["min_price"],
            product_data["material_cost"], product_data["labor_cost"], product_data.get("production_days", 2),
            product_data.get("raw_image_url", ""), product_data.get("enhanced_image_url", ""),
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
        items = list(_mongo_db.buyers.find(query, {"_id": 0}).sort("id", 1))
        return items
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        if category_filter:
            cursor.execute("SELECT * FROM buyers WHERE target_category LIKE ?", (f"%{category_filter}%",))
        else:
            cursor.execute("SELECT * FROM buyers ORDER BY id ASC")
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

def db_get_product_enquiries(product_id: int = None) -> list:
    if _db_type == "MongoDB" and _mongo_db is not None:
        query = {}
        if product_id:
            query = {"product_id": product_id}
        items = list(_mongo_db.enquiries.find(query, {"_id": 0}).sort("id", -1))
        
        for item in items:
            if "product_title" not in item and "product_id" in item:
                prod = _mongo_db.products.find_one({"id": item["product_id"]})
                if prod:
                    item["product_title"] = prod.get("title", "")
        return items
    else:
        conn = get_sqlite_conn()
        cursor = conn.cursor()
        if product_id:
            cursor.execute("SELECT * FROM enquiries WHERE product_id = ? ORDER BY id DESC", (product_id,))
        else:
            cursor.execute("SELECT e.*, p.title as product_title FROM enquiries e JOIN products p ON e.product_id = p.id ORDER BY e.id DESC")
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

def db_register_artisan(artisan_data: dict) -> dict:
    now_str = datetime.now().isoformat()
    username = (artisan_data.get("username") or "").strip()
    phone = (artisan_data.get("phone") or "").strip()
    password = artisan_data.get("password") or ""
    full_name = (artisan_data.get("full_name") or artisan_data.get("name") or "").strip()
    gender = artisan_data.get("gender") or "Male"
    craft_type = artisan_data.get("craft_type") or "Handloom & Handicrafts"
    address = (artisan_data.get("address") or artisan_data.get("location") or "").strip() or "India"

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


