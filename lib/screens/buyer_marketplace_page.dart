import 'package:flutter/material.dart';
import 'package:hastakala/services/api_service.dart';
import 'package:hastakala/services/speech_service.dart';
import 'package:hastakala/screens/b2b_enquiry_sheet.dart';

class BuyerMarketplacePage extends StatefulWidget {
  final Map<String, dynamic>? buyerSession;
  final VoidCallback? onSwitchToArtisan;

  const BuyerMarketplacePage({
    super.key,
    this.buyerSession,
    this.onSwitchToArtisan,
  });

  @override
  State<BuyerMarketplacePage> createState() => _BuyerMarketplacePageState();
}

class _BuyerMarketplacePageState extends State<BuyerMarketplacePage> {
  final TextEditingController searchCtrl = TextEditingController();
  List<dynamic> allProducts = [];
  List<dynamic> recommendations = [];
  bool loading = true;
  String selectedCategory = 'All';
  bool isListening = false;
  String voiceLanguage = 'hi-IN';

  final List<String> categories = [
    'All',
    'Bamboo & Cane',
    'Handloom & Textiles',
    'Pottery & Clay',
    'Metal Craft',
    'Wood Carving',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    if (isListening) SpeechService.stopListening();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final prods = await ApiService.getProducts(
      category: selectedCategory == 'All' ? null : selectedCategory,
      search: searchCtrl.text.trim().isNotEmpty ? searchCtrl.text.trim() : null,
    );
    final recs = await ApiService.getRecommendations(
      category: selectedCategory == 'All' ? null : selectedCategory,
      limit: 3,
    );

    if (mounted) {
      setState(() {
        allProducts = prods;
        recommendations = recs;
        loading = false;
      });
    }
  }

  void _toggleVoiceSearch() {
    if (isListening) {
      SpeechService.stopListening();
      setState(() => isListening = false);
      return;
    }

    setState(() => isListening = true);
    final success = SpeechService.startListening(
      languageCode: voiceLanguage,
      onResult: (text) {
        if (mounted) {
          setState(() {
            searchCtrl.text = text;
          });
          _loadData();
        }
      },
      onEnd: () {
        if (mounted) setState(() => isListening = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() => isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input notice: $err'), duration: const Duration(seconds: 2)),
          );
        }
      },
    );

    if (!success && mounted) {
      setState(() => isListening = false);
    }
  }

  void _showProductDetailModal(Map<String, dynamic> p) {
    final moq = p['moq'] ?? 50;
    final available = p['available_qty'] ?? 500;
    final capacity = p['monthly_capacity'] ?? 1000;
    final artisanName = p['artisan_name'] ?? 'Master Artisan';
    final location = p['artisan_location'] ?? 'West Bengal';
    final rawPricing = p['bulk_pricing'];
    final tiers = (rawPricing is List) ? rawPricing : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag Indicator
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Product Image
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD8A54A), width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => ApiService.showImagePreviewDialog(context, p['enhanced_image_url'] ?? p['raw_image_url']),
                            child: ApiService.buildProductImage(
                              p['enhanced_image_url'] ?? p['raw_image_url'],
                              fit: BoxFit.cover,
                              fallback: _imagePlaceholder(),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7A0B2E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('B2B Certified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Category
                    Text(
                      p['title'] ?? 'Artisan Craft',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p['category'] ?? 'Craft'} • 📍 $location',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7D7478), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),

                    // Artisan Info Pill
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF7A0B2E),
                            radius: 20,
                            child: Icon(Icons.person, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(artisanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const Text('Direct Rural Artisan Producer', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C9A68).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Direct Price', style: TextStyle(color: Color(0xFF3C9A68), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MOQ & Key Specifications Highlight Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A0B2E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7A0B2E).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.rule_folder_outlined, color: Color(0xFF7A0B2E), size: 20),
                              const SizedBox(width: 8),
                              const Text('Minimum Order Quantity (MOQ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                '$moq pieces',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _specColumn('Available Stock', '$available units', Icons.inventory_2_outlined),
                              _specColumn('Monthly Capacity', '$capacity pcs', Icons.precision_manufacturing_outlined),
                              _specColumn('Production Lead', p['production_time'] ?? '3–5 days', Icons.schedule_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bulk Pricing Tiers Table
                    const Text('B2B Bulk Pricing Tiers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: tiers.isNotEmpty
                            ? tiers.map<Widget>((t) {
                                final isDiscount = (t['discount'] ?? '').toString().contains('%');
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        t['range'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Row(
                                        children: [
                                          if (t['discount'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: isDiscount ? const Color(0xFF3C9A68).withValues(alpha: 0.12) : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                t['discount'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDiscount ? const Color(0xFF3C9A68) : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            '₹${t['price']?.toInt() ?? 0} / piece',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7A0B2E)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                            : [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('Standard Wholesale: ₹${p['price_wholesale']?.toInt() ?? 450} / piece'),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Customization Available
                    const Text('Customization Options', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _customBadge('Custom Size', p['custom_size'] == 1),
                        const SizedBox(width: 8),
                        _customBadge('Custom Design', p['custom_design'] == 1),
                        const SizedBox(width: 8),
                        _customBadge('Custom Packaging', p['custom_packaging'] == 1),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Description & Materials
                    const Text('Product Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                    const SizedBox(height: 6),
                    Text(
                      p['description_en'] ?? 'Handcrafted traditional artisan product.',
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF2C282E)),
                    ),
                    if (p['description_hi'] != null && (p['description_hi'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        p['description_hi'],
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF7D7478)),
                      ),
                    ],
                    if (p['type_of_art'] != null && p['type_of_art'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF7A0B2E)),
                          const SizedBox(width: 6),
                          Text('Art Form: ${p['type_of_art']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7A0B2E))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('Materials: ${p['materials'] ?? 'Natural & Organic'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7D7478))),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Sticky Bottom CTA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A0B2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      B2BEnquirySheet.show(
                        context,
                        product: p,
                        buyerSession: widget.buyerSession,
                        onEnquirySent: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enquiry sent! The artisan will contact you directly.')),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      '📩 Send Business Enquiry',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specColumn(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7A0B2E)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C282E))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7D7478))),
      ],
    );
  }

  Widget _customBadge(String text, bool enabled) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF3C9A68).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? const Color(0xFF3C9A68).withValues(alpha: 0.3) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(enabled ? '✅' : '❌', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: enabled ? const Color(0xFF3C9A68) : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE9DED3),
      child: const Center(
        child: Icon(Icons.palette_outlined, size: 48, color: Color(0xFF7A0B2E)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyerName = widget.buyerSession?['organization_name'] ?? widget.buyerSession?['contact_person'] ?? 'Business Buyer';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A0B2E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hastakala B2B Marketplace 🏛️', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Welcome, $buyerName', style: const TextStyle(color: Color(0xFFFFE4B5), fontSize: 11)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search & Voice Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(Icons.search, color: Color(0xFF7A0B2E)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onSubmitted: (_) => _loadData(),
                      decoration: const InputDecoration(
                        hintText: 'Search craft, artisan, location, MOQ...',
                        hintStyle: TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        searchCtrl.clear();
                        _loadData();
                      },
                    ),
                  // Voice Search Mic Button
                  IconButton(
                    tooltip: 'Voice Search (Hindi / English)',
                    onPressed: _toggleVoiceSearch,
                    icon: CircleAvatar(
                      radius: 17,
                      backgroundColor: isListening ? Colors.red : const Color(0xFF7A0B2E),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            if (isListening) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.graphic_eq, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎙️ Listening... Speak craft name in Hindi or English (e.g. "Bamboo Basket", "Banarasi Saree")',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSelected = cat == selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = cat);
                      _loadData();
                    },
                    selectedColor: const Color(0xFF7A0B2E),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2C282E),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // AI Recommendations Section
            if (recommendations.isNotEmpty && searchCtrl.text.isEmpty && selectedCategory == 'All') ...[
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD8A54A), size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Recommended for Bulk Sourcing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                  ),
                  const Spacer(),
                  Text('${recommendations.length} High Capacity', style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final r = recommendations[i];
                    return _recommendationCard(r);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Main Product Catalog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Artisan Product Catalog',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                ),
                Text(
                  '${allProducts.length} listings',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Catalog Cards List
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF7A0B2E))))
            else if (allProducts.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No artisan products match your filter', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7D7478))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        searchCtrl.clear();
                        setState(() => selectedCategory = 'All');
                        _loadData();
                      },
                      child: const Text('Reset Filters', style: TextStyle(color: Color(0xFF7A0B2E))),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allProducts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, idx) => _b2bProductCard(allProducts[idx]),
              ),
          ],
        ),
      ),
    );
  }

  // AI Recommendation Mini Card
  Widget _recommendationCard(Map<String, dynamic> r) {
    return GestureDetector(
      onTap: () => _showProductDetailModal(r),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8A54A).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD8A54A).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              clipBehavior: Clip.antiAlias,
              child: ApiService.buildProductImage(
                r['enhanced_image_url'] ?? r['raw_image_url'],
                fit: BoxFit.cover,
                fallback: _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C9A68).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('✨ AI Recommended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3C9A68))),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r['title'] ?? 'Craft',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text('₹${r['price_wholesale']?.toInt() ?? 450} / piece', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E), fontSize: 13)),
                  Text('MOQ: ${r['moq'] ?? 50} pcs', style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                  Text('Cap: ${r['monthly_capacity'] ?? 1000}/mo', style: const TextStyle(fontSize: 11, color: Color(0xFF3C9A68), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // B2B Product Catalog Card (Matches the exact requirements)
  Widget _b2bProductCard(Map<String, dynamic> p) {
    final moq = p['moq'] ?? 50;
    final available = p['available_qty'] ?? 500;
    final wholesalePrice = p['price_wholesale']?.toInt() ?? p['price_retail']?.toInt() ?? 450;
    final artisanLocation = p['artisan_location'] ?? 'West Bengal';
    final artisanName = p['artisan_name'] ?? 'Ramesh Kumar';
    final hasBulk = p['bulk_available'] == 1;
    final hasCustom = (p['custom_size'] == 1 || p['custom_design'] == 1 || p['custom_packaging'] == 1);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showProductDetailModal(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ApiService.buildProductImage(
                      p['enhanced_image_url'] ?? p['raw_image_url'],
                      fit: BoxFit.cover,
                      fallback: _imagePlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Core Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'] ?? 'Handmade Craft',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C282E)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p['category'] ?? 'Artisan Craft',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478)),
                        ),
                        const SizedBox(height: 6),
                        // Price / Unit
                        Row(
                          children: [
                            Text(
                              '₹$wholesalePrice',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                            ),
                            const Text(
                              ' / piece',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7D7478)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // MOQ & Available
                        Row(
                          children: [
                            Text(
                              'MOQ: $moq',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7A0B2E)),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Available: $available',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF3C9A68)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // B2B Flags & Location Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text('Bulk order: ${hasBulk ? "✅" : "❌"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Text('Customization: ${hasCustom ? "✅" : "❌"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.location_on, size: 12, color: Color(0xFF7A0B2E)),
                    const SizedBox(width: 2),
                    Text(artisanLocation, style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Artisan: $artisanName • Capacity: ${p['monthly_capacity'] ?? 1000}/mo',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
              ),
              const SizedBox(height: 10),

              // CTA Button: Send Business Enquiry
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7A0B2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    B2BEnquirySheet.show(
                      context,
                      product: p,
                      buyerSession: widget.buyerSession,
                      onEnquirySent: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enquiry sent! The artisan will contact you directly.')),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('SEND ENQUIRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
