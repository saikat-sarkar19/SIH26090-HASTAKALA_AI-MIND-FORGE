from hastakala_backend.database import get_db_connection

def get_verified_buyers(category_filter: str = "") -> list:
    conn = get_db_connection()
    cursor = conn.cursor()
    if category_filter:
        cursor.execute("SELECT * FROM buyers WHERE target_category LIKE ?", (f"%{category_filter}%",))
    else:
        cursor.execute("SELECT * FROM buyers ORDER BY id ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def get_product_enquiries(product_id: int = None) -> list:
    conn = get_db_connection()
    cursor = conn.cursor()
    if product_id:
        cursor.execute("SELECT * FROM enquiries WHERE product_id = ? ORDER BY id DESC", (product_id,))
    else:
        cursor.execute("SELECT e.*, p.title as product_title FROM enquiries e JOIN products p ON e.product_id = p.id ORDER BY e.id DESC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]
