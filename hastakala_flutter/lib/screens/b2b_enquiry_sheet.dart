import 'package:flutter/material.dart';
import 'package:hastakala/services/api_service.dart';

class B2BEnquirySheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? buyerSession;
  final VoidCallback? onEnquirySent;

  const B2BEnquirySheet({
    super.key,
    required this.product,
    this.buyerSession,
    this.onEnquirySent,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> product,
    Map<String, dynamic>? buyerSession,
    VoidCallback? onEnquirySent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: B2BEnquirySheet(
          product: product,
          buyerSession: buyerSession,
          onEnquirySent: onEnquirySent,
        ),
      ),
    );
  }

  @override
  State<B2BEnquirySheet> createState() => _B2BEnquirySheetState();
}

class _B2BEnquirySheetState extends State<B2BEnquirySheet> {
  late TextEditingController qtyCtrl;
  late TextEditingController businessNameCtrl;
  late TextEditingController contactPersonCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController messageCtrl;
  late TextEditingController customNotesCtrl;

  bool customSize = false;
  bool customDesign = false;
  bool customPackaging = true;
  bool isSubmitting = false;

  late int moq;
  late int availableQty;
  late double basePrice;

  @override
  void initState() {
    super.initState();
    moq = int.tryParse(widget.product['moq']?.toString() ?? '50') ?? 50;
    availableQty = int.tryParse(widget.product['available_qty']?.toString() ?? '500') ?? 500;
    basePrice = (widget.product['price_wholesale'] is num)
        ? (widget.product['price_wholesale'] as num).toDouble()
        : (widget.product['price_retail'] is num)
            ? (widget.product['price_retail'] as num).toDouble()
            : 450.0;

    final session = widget.buyerSession;
    qtyCtrl = TextEditingController(text: moq.toString());
    businessNameCtrl = TextEditingController(text: session?['organization_name'] ?? session?['business_name'] ?? '');
    contactPersonCtrl = TextEditingController(text: session?['contact_person'] ?? session?['name'] ?? '');
    phoneCtrl = TextEditingController(text: session?['phone'] ?? '');
    emailCtrl = TextEditingController(text: session?['contact_email'] ?? session?['email'] ?? '');
    locationCtrl = TextEditingController(text: session?['location'] ?? 'India');
    messageCtrl = TextEditingController();
    customNotesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    qtyCtrl.dispose();
    businessNameCtrl.dispose();
    contactPersonCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    locationCtrl.dispose();
    messageCtrl.dispose();
    customNotesCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getMatchingTier(int quantity) {
    final rawTiers = widget.product['bulk_pricing'];
    if (rawTiers is! List || rawTiers.isEmpty) return null;

    for (final t in rawTiers) {
      if (t is Map) {
        int? minQ = t['min_qty'] != null ? int.tryParse(t['min_qty'].toString()) : null;
        int? maxQ = t['max_qty'] != null ? int.tryParse(t['max_qty'].toString()) : null;

        if (minQ == null && t['range'] != null) {
          final rangeStr = t['range'].toString();
          final parts = rangeStr.replaceAll(RegExp(r'[^0-9–\-]'), '').split(RegExp(r'[–\-]'));
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            minQ = int.tryParse(parts[0]);
          }
          if (parts.length > 1 && parts[1].isNotEmpty) {
            maxQ = int.tryParse(parts[1]);
          }
        }

        if (minQ != null) {
          if (maxQ != null && quantity >= minQ && quantity <= maxQ) {
            return Map<String, dynamic>.from(t);
          } else if (maxQ == null && quantity >= minQ) {
            return Map<String, dynamic>.from(t);
          }
        }
      }
    }

    // Fallback: reverse iterate to match highest tier threshold
    for (int i = rawTiers.length - 1; i >= 0; i--) {
      final t = rawTiers[i];
      if (t is Map) {
        int? minQ = t['min_qty'] != null ? int.tryParse(t['min_qty'].toString()) : null;
        if (minQ != null && quantity >= minQ) {
          return Map<String, dynamic>.from(t);
        }
      }
    }

    if (rawTiers.first is Map) {
      return Map<String, dynamic>.from(rawTiers.first);
    }
    return null;
  }

  double _calculateEffectiveUnitPrice(int quantity) {
    final tier = _getMatchingTier(quantity);
    if (tier != null && tier['price'] != null) {
      final p = double.tryParse(tier['price'].toString());
      if (p != null) return p;
    }
    return basePrice;
  }

  Future<void> _submitEnquiry() async {
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    final businessName = businessNameCtrl.text.trim();
    final contactPerson = contactPersonCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid order quantity.')),
      );
      return;
    }

    if (qty < moq) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum Order Quantity (MOQ) is $moq pieces. Please increase your quantity.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    if (businessName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your Business Name and Contact Phone.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final unitPrice = _calculateEffectiveUnitPrice(qty);
    final targetPrice = unitPrice;

    final enquiryData = {
      'product_id': widget.product['id'],
      'buyer_id': widget.buyerSession?['id'] ?? 0,
      'buyer_name': contactPerson.isNotEmpty ? contactPerson : businessName,
      'business_name': businessName,
      'buyer_type': widget.buyerSession?['buyer_type'] ?? 'Wholesale Buyer',
      'buyer_phone': phone,
      'buyer_email': emailCtrl.text.trim(),
      'buyer_location': locationCtrl.text.trim(),
      'order_quantity': qty,
      'offer_price': unitPrice,
      'target_price': targetPrice,
      'custom_size': customSize,
      'custom_design': customDesign,
      'custom_packaging': customPackaging,
      'custom_notes': customNotesCtrl.text.trim(),
      'message': messageCtrl.text.trim().isNotEmpty
          ? messageCtrl.text.trim()
          : 'Requesting quote for $qty units of ${widget.product['title']}.',
      'artisan_id': widget.product['artisan_id'] ?? 1,
      'artisan_username': widget.product['artisan_username'] ?? 'ramesh_artisan',
    };

    final res = await ApiService.createEnquiry(enquiryData);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (res != null && res['status'] == 'success') {
      Navigator.pop(context); // close sheet
      if (widget.onEnquirySent != null) widget.onEnquirySent!();
      _showSuccessDialog(qty, unitPrice);
    } else {
      final err = res?['detail'] ?? 'Failed to send enquiry. Please check your network connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade800),
      );
    }
  }

  void _showSuccessDialog(int qty, double unitPrice) {
    final artisanName = widget.product['artisan_name'] ?? 'Artisan';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3C9A68).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF3C9A68)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enquiry Sent to Artisan! 📩',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your business enquiry for $qty pieces of "${widget.product['title']}" has been delivered to $artisanName.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF2C282E), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8A54A).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Rate:', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                      Text('₹${unitPrice.toInt()}/piece', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Approx. Order Value:', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                      Text('₹${(unitPrice * qty).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3C9A68))),
                    ],
                  ),
                  const Divider(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF3C9A68)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No payment required. The artisan will contact you directly via phone or WhatsApp.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A0B2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQty = int.tryParse(qtyCtrl.text) ?? moq;
    final isBelowMoq = currentQty < moq;
    final matchingTier = _getMatchingTier(currentQty);
    final effectivePrice = _calculateEffectiveUnitPrice(currentQty);
    final approxTotal = effectivePrice * currentQty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded, color: Color(0xFF7A0B2E), size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Send Business Enquiry 📩',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF7D7478)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Product Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8A54A).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A0B2E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF7A0B2E), size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product['title'] ?? 'Artisan Craft',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.product['category'] ?? ''} • ${widget.product['artisan_name'] ?? 'Artisan'}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7A0B2E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('MOQ: $moq pcs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                                ),
                                const SizedBox(width: 8),
                                Text('Available: $availableQty', style: const TextStyle(fontSize: 11, color: Color(0xFF3C9A68), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Step 1: Order Quantity & Live Tier Price
                const Text('Step 1: Enter Required Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7A0B2E))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        final val = int.tryParse(qtyCtrl.text) ?? moq;
                        if (val > 5) {
                          setState(() => qtyCtrl.text = (val - 10).clamp(1, 10000).toString());
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          suffixText: 'pieces',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isBelowMoq ? Colors.red : const Color(0xFF7A0B2E)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isBelowMoq ? Colors.red : Colors.grey.shade400),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF7A0B2E)),
                      onPressed: () {
                        final val = int.tryParse(qtyCtrl.text) ?? moq;
                        setState(() => qtyCtrl.text = (val + 10).toString());
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                if (isBelowMoq) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Minimum Order Quantity is $moq pieces.',
                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Live Pricing Quote Preview Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C9A68).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3C9A68).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Wholesale Tier Rate:', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                              if (matchingTier != null && matchingTier['discount'] != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3C9A68),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    matchingTier['discount'].toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('₹${effectivePrice.toInt()} / piece', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3C9A68))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Est. Total Volume:', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                          Text('₹${approxTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7A0B2E))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 2: Customization Options
                const Text('Step 2: Customization Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7A0B2E))),
                const SizedBox(height: 6),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Custom Size / Dimensions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Specify exact length, width, or diameter', style: TextStyle(fontSize: 11)),
                          value: customSize,
                          activeColor: const Color(0xFF7A0B2E),
                          onChanged: (v) => setState(() => customSize = v ?? false),
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Custom Design / Pattern / Colors', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Artisan can weave or mold custom motifs', style: TextStyle(fontSize: 11)),
                          value: customDesign,
                          activeColor: const Color(0xFF7A0B2E),
                          onChanged: (v) => setState(() => customDesign = v ?? false),
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Custom Eco Packaging & Brand Tag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Add your company logo tag or natural jute wrap', style: TextStyle(fontSize: 11)),
                          value: customPackaging,
                          activeColor: const Color(0xFF7A0B2E),
                          onChanged: (v) => setState(() => customPackaging = v ?? false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customNotesCtrl,
                  decoration: InputDecoration(
                    hintText: 'Any special specifications (e.g. 12x12 inch basket, indigo dye)...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Step 3: Business Details
                const Text('Step 3: Buyer & Business Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7A0B2E))),
                const SizedBox(height: 8),
                TextField(
                  controller: businessNameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF7A0B2E), size: 20),
                    labelText: 'Business / Company Name *',
                    hintText: 'e.g. FabIndia, Ethnic Retailer, Heritage Boutique',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: contactPersonCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7A0B2E), size: 20),
                          labelText: 'Contact Person *',
                          hintText: 'Your name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7A0B2E), size: 20),
                          labelText: 'Phone / WhatsApp *',
                          hintText: '10 digits',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7A0B2E), size: 20),
                          labelText: 'Email Address',
                          hintText: 'buyer@business.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: locationCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF7A0B2E), size: 20),
                          labelText: 'Delivery Location',
                          hintText: 'e.g. Mumbai, Maharashtra',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.comment_outlined, color: Color(0xFF7A0B2E), size: 20),
                    labelText: 'Message for Artisan (Optional)',
                    hintText: 'Delivery deadline, quality requirements, packaging notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A0B2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: (isSubmitting || isBelowMoq) ? null : _submitEnquiry,
                    icon: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(isBelowMoq ? Icons.lock_outline : Icons.send_rounded, color: Colors.white),
                    label: Text(
                      isSubmitting
                          ? 'Sending Enquiry...'
                          : isBelowMoq
                              ? '⚠️ Minimum Order is $moq Pieces'
                              : '📩 Send Business Enquiry',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'No payment required. The artisan will contact you directly.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
