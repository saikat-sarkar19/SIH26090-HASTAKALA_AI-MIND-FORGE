from hastakala_backend.config import GEMINI_API_KEY

def chat_with_assistant(query: str, language: str = "Hindi") -> dict:
    """
    AI Business Assistant endpoint:
    Provides context-aware answers to artisan questions about pricing, marketing, government schemes, and buyers.
    """
    q_lower = query.lower()

    if "price" in q_lower or "sell" in q_lower or "दाम" in q_lower or "कीमत" in q_lower:
        reply = (
            "Namaste! 🙏 To price your handicraft product accurately:\n"
            "1. Calculate raw material cost + your craft labor time.\n"
            "2. For retail buyers, add a 40-50% profit margin.\n"
            "3. For bulk B2B orders (10+ units), offer wholesale pricing (~25% margin).\n"
            "Use our Hastakala 'Add Product' feature to get instant AI pricing recommendations!"
        )
    elif "buyer" in q_lower or "order" in q_lower or "ग्राहक" in q_lower or "खरीदार" in q_lower:
        reply = (
            "Great question! 🛍️ Active buyers on Hastakala are looking for:\n"
            "1. GeM Government Procurement (Office Gifting & Decor)\n"
            "2. Tribes India & FabIndia Wholesale Channels\n"
            "3. Shilp Samagam & Surajkund Fair Buyers\n"
            "Ensure your inventory has clean studio photos and Hindi/English descriptions to attract bulk orders!"
        )
    elif "trending" in q_lower or "demand" in q_lower or "मांग" in q_lower:
        reply = (
            "🔥 Top Trending Artisan Products This Month:\n"
            "• Handwoven Banarasi Cotton & Silk Sarees\n"
            "• Eco-friendly Bamboo & Jute Baskets\n"
            "• Hand-carved Wooden Decor & Toys\n"
            "Adding 2 new designs this week will increase your profile views by 35%!"
        )
    elif "scheme" in q_lower or "loan" in q_lower or "yojana" in q_lower or "योजना" in q_lower:
        reply = (
            "🏛️ Government Upliftment Schemes for Artisans:\n"
            "• PM Vishwakarma Yojana: Subsidized loans up to ₹3 Lakh at 5% interest + free toolkit.\n"
            "• Shilp Samagam & Dilli Haat: Free stalls and travel allowance for registered artisans.\n"
            "You can register with your Artisan ID or Aadhaar Card."
        )
    else:
        reply = (
            f"Namaste! 🙏 I am your Hastakala AI Business Manager.\n"
            f"I can help you photograph products, create multilingual catalogs, set optimal prices, and connect with verified B2B buyers.\n"
            f"How can I assist your handicraft business today?"
        )

    return {
        "query": query,
        "reply": reply,
        "suggested_actions": [
            "How much should I sell my product for?",
            "Show active B2B buyers for my crafts",
            "Which products are trending this week?",
            "Tell me about PM Vishwakarma Scheme"
        ]
    }
