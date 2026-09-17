def calculate_dynamic_pricing(
    category: str,
    materials: str,
    raw_material_cost: float = 0.0,
    labor_hours: float = 8.0,
    labor_rate_per_hour: float = 100.0,
    custom_margin_pct: float = 25.0
) -> dict:
    """
    Dynamic Pricing Assistant Engine:
    Analyzes material inputs, artisan labor hours, category benchmarks, and market demand to suggest
    competitive retail & wholesale prices with itemized cost transparency.
    """
    cat_lower = category.lower()
    
    # Category baseline estimation if raw_material_cost is not provided
    if raw_material_cost <= 0:
        if "saree" in cat_lower or "textiles" in cat_lower:
            raw_material_cost = 450.0
            labor_hours = 16.0
        elif "basket" in cat_lower or "bamboo" in cat_lower:
            raw_material_cost = 180.0
            labor_hours = 8.0
        elif "pottery" in cat_lower or "clay" in cat_lower or "terracotta" in cat_lower:
            raw_material_cost = 200.0
            labor_hours = 10.0
        elif "wood" in cat_lower:
            raw_material_cost = 350.0
            labor_hours = 12.0
        else:
            raw_material_cost = 250.0
            labor_hours = 10.0

    base_labor_cost = labor_hours * labor_rate_per_hour
    total_cost_price = raw_material_cost + base_labor_cost

    # Craft Uniqueness Premium (Handicrafts have higher value than mass factory goods)
    craft_margin = total_cost_price * (custom_margin_pct / 100.0)
    
    # Wholesale Price (B2B bulk orders: 1.35x total cost price)
    price_wholesale = round(total_cost_price * 1.35, -1) # rounded to nearest 10

    # Retail Price (D2C e-commerce: 1.75x total cost price)
    price_retail = round(total_cost_price * 1.75, -1)

    # Minimum Fair Price Floor (Break-even + basic wage protection)
    min_price = round(total_cost_price * 1.15, -1)

    # Market Price Range Comparison
    market_min = round(price_wholesale * 0.95, -1)
    market_max = round(price_retail * 1.20, -1)

    return {
        "price_retail": price_retail,
        "price_wholesale": price_wholesale,
        "min_price": min_price,
        "market_range": f"₹{int(market_min):,} – ₹{int(market_max):,}",
        "cost_breakdown": {
            "raw_material_cost": raw_material_cost,
            "labor_cost": base_labor_cost,
            "labor_hours": labor_hours,
            "craft_margin": craft_margin,
            "total_production_cost": total_cost_price
        },
        "pricing_advice": [
            f"Based on ₹{int(raw_material_cost)} material cost and {int(labor_hours)} hours of labor.",
            f"Suggested Retail Price: ₹{int(price_retail):,} yields a healthy artisan profit margin.",
            f"Bulk B2B Wholesale Price: ₹{int(price_wholesale):,} protects your profit on large volume orders (10+ units).",
            "Listing this product on Government E-Marketplace (GeM) can connect you to government buyers."
        ]
    }
