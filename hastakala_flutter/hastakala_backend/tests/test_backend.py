import unittest
import io
import os
from PIL import Image
from fastapi.testclient import TestClient

from hastakala_backend.main import app
from hastakala_backend.services.image_service import enhance_product_image
from hastakala_backend.services.catalog_service import generate_catalog_from_voice_or_text
from hastakala_backend.services.pricing_service import calculate_dynamic_pricing
from hastakala_backend.services.assistant_service import chat_with_assistant

class TestHastakalaBackend(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_root_endpoint(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("Hastakala", response.json()["app"])

    def test_dashboard_stats(self):
        response = self.client.get("/api/dashboard/stats")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("total_products", data)
        self.assertIn("total_enquiries", data)
        self.assertIn("total_buyers", data)

    def test_database_status_endpoint(self):
        response = self.client.get("/api/database/status")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("db_type", data)
        self.assertIn("is_mongodb", data)


    def test_image_enhance(self):
        # Create dummy image in memory
        img = Image.new("RGB", (300, 300), color="red")
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        buf.seek(0)

        response = self.client.post(
            "/api/image/enhance",
            files={"file": ("test_craft.jpg", buf, "image/jpeg")}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("enhanced_image_url", data)
        self.assertIn("raw_image_url", data)

    def test_catalog_generate(self):
        payload = {
            "voice_text": "This is a handwoven bamboo basket for home decor",
            "language": "English"
        }
        response = self.client.post("/api/catalog/generate", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("title", data)
        self.assertIn("description_en", data)
        self.assertIn("description_hi", data)

    def test_pricing_calculate(self):
        payload = {
            "category": "Textiles › Sarees",
            "materials": "Pure Cotton",
            "raw_material_cost": 400.0,
            "labor_hours": 10.0,
            "labor_rate_per_hour": 100.0
        }
        response = self.client.post("/api/pricing/calculate", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertGreater(data["price_retail"], data["price_wholesale"])
        self.assertGreater(data["price_wholesale"], data["min_price"])

    def test_products_crud(self):
        # Get list
        res_get = self.client.get("/api/products")
        self.assertEqual(res_get.status_code, 200)

        # Create product
        new_prod = {
            "title": "Test Banarasi Dupatta",
            "description_en": "Handwoven silk dupatta",
            "description_hi": "हथकरघा रेशमी दुपट्टा",
            "category": "Textiles",
            "materials": "Silk",
            "tags": "Handloom • Silk",
            "price_retail": 1200.0,
            "price_wholesale": 900.0,
            "min_price": 750.0,
            "material_cost": 350.0,
            "labor_cost": 300.0,
            "production_days": 2,
            "raw_image_url": "/uploads/raw_test.jpg",
            "enhanced_image_url": "/uploads/enhanced/studio_test.png"
        }
        res_post = self.client.post("/api/products", json=new_prod)
        self.assertEqual(res_post.status_code, 200)
        pid = res_post.json()["id"]

        # Detail
        res_detail = self.client.get(f"/api/products/{pid}")
        self.assertEqual(res_detail.status_code, 200)
        self.assertEqual(res_detail.json()["title"], "Test Banarasi Dupatta")

        # Delete
        res_del = self.client.delete(f"/api/products/{pid}")
        self.assertEqual(res_del.status_code, 200)

    def test_assistant_chat(self):
        res = self.client.post("/api/assistant/chat", json={"query": "How to set price for saree?"})
        self.assertEqual(res.status_code, 200)
        self.assertIn("reply", res.json())

    def test_auth_flow(self):
        import time
        # 1. Login with demo user
        res_login = self.client.post("/api/auth/login", json={"username": "ramesh_artisan", "password": "password123"})
        self.assertEqual(res_login.status_code, 200)
        self.assertEqual(res_login.json()["status"], "success")

        # 2. Register new user with unique username & phone
        ts = int(time.time() * 1000)
        uname = f"sunita_{ts}"
        phone_num = f"98{str(ts)[-8:]}"
        new_user = {
            "full_name": "Sunita Devi",
            "username": uname,
            "phone": phone_num,
            "gender": "Female",
            "craft_type": "Terracotta Pottery & Bio-Clay",
            "address": "Gorakhpur, UP",
            "password": "mypassword123"
        }
        res_reg = self.client.post("/api/auth/register", json=new_user)
        self.assertEqual(res_reg.status_code, 200)
        self.assertEqual(res_reg.json()["status"], "success")

        # 3. Login with newly registered user
        res_login_new = self.client.post("/api/auth/login", json={"username": uname, "password": "mypassword123"})
        self.assertEqual(res_login_new.status_code, 200)
        self.assertEqual(res_login_new.json()["artisan"]["name"], "Sunita Devi")

        # 4. Update profile details & profile picture
        update_payload = {
            "username": uname,
            "full_name": "Sunita Devi Master Potter",
            "phone": phone_num,
            "gender": "Female",
            "craft_type": "Terracotta Pottery & Bio-Clay",
            "location": "Varanasi, UP",
            "profile_picture": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
        }
        res_upd = self.client.post("/api/auth/update_profile", json=update_payload)
        self.assertEqual(res_upd.status_code, 200)
        self.assertEqual(res_upd.json()["artisan"]["name"], "Sunita Devi Master Potter")
        self.assertTrue(res_upd.json()["artisan"]["profile_picture"].startswith("data:image"))

    def test_product_artisan_filtering(self):
        # Create product for artisan A
        prod_a = {
            "title": "Artisan A Product",
            "description_en": "Desc A",
            "description_hi": "विवरण ए",
            "category": "Handicraft",
            "materials": "Wood",
            "tags": "Wood",
            "price_retail": 500.0,
            "price_wholesale": 350.0,
            "min_price": 250.0,
            "material_cost": 100.0,
            "labor_cost": 150.0,
            "production_days": 1,
            "artisan_id": 9901,
            "artisan_username": "artisan_filter_a"
        }
        res_a = self.client.post("/api/products", json=prod_a)
        self.assertEqual(res_a.status_code, 200)
        id_a = res_a.json()["id"]

        # Create product for artisan B
        prod_b = {
            "title": "Artisan B Product",
            "description_en": "Desc B",
            "description_hi": "विवरण बी",
            "category": "Pottery",
            "materials": "Clay",
            "tags": "Clay",
            "price_retail": 800.0,
            "price_wholesale": 600.0,
            "min_price": 400.0,
            "material_cost": 200.0,
            "labor_cost": 200.0,
            "production_days": 2,
            "artisan_id": 9902,
            "artisan_username": "artisan_filter_b"
        }
        res_b = self.client.post("/api/products", json=prod_b)
        self.assertEqual(res_b.status_code, 200)
        id_b = res_b.json()["id"]

        try:
            # Query for artisan A
            res_query_a = self.client.get("/api/products?artisan_username=artisan_filter_a")
            self.assertEqual(res_query_a.status_code, 200)
            items_a = res_query_a.json()
            titles_a = [item["title"] for item in items_a]
            self.assertIn("Artisan A Product", titles_a)
            self.assertNotIn("Artisan B Product", titles_a)

            # Query for artisan B by ID
            res_query_b = self.client.get("/api/products?artisan_id=9902")
            self.assertEqual(res_query_b.status_code, 200)
            items_b = res_query_b.json()
            titles_b = [item["title"] for item in items_b]
            self.assertIn("Artisan B Product", titles_b)
            self.assertNotIn("Artisan A Product", titles_b)
        finally:
            self.client.delete(f"/api/products/{id_a}")
            self.client.delete(f"/api/products/{id_b}")

if __name__ == "__main__":
    unittest.main()

