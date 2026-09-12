import sqlite3
import json
from datetime import datetime
from hastakala_backend.config import DB_PATH

def get_db_connection():
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    # Artisans table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS artisans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        craft_type TEXT DEFAULT 'Handloom & Handicrafts',
        language TEXT DEFAULT 'English',
        location TEXT DEFAULT 'Varanasi, Uttar Pradesh',
        created_at TEXT NOT NULL
    );
    """)

    # Products table
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

    # Buyers table
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

    # Enquiries table
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

    # Seed default buyer leads if empty
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

    # Seed initial artisan if empty
    cursor.execute("SELECT COUNT(*) as cnt FROM artisans")
    if cursor.fetchone()['cnt'] == 0:
        now_str = datetime.now().isoformat()
        cursor.execute("""
        INSERT INTO artisans (name, phone, craft_type, language, location, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """, ("Ramesh Kumar", "9876543210", "Master Weaver & Bamboo Craftsman", "Hindi", "Varanasi, UP", now_str))

    # Seed sample initial products if empty
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

        # Seed sample enquiries
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

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
