from hastakala_backend.database import db_get_verified_buyers, db_get_product_enquiries

def get_verified_buyers(category_filter: str = "") -> list:
    return db_get_verified_buyers(category_filter=category_filter)

def get_product_enquiries(product_id: int = None) -> list:
    return db_get_product_enquiries(product_id=product_id)

