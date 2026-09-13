import 'package:flutter/material.dart';
import 'package:hastakala/services/api_service.dart';

class ArtisanEnquiriesPage extends StatefulWidget {
  final Map<String, dynamic>? artisanSession;

  const ArtisanEnquiriesPage({super.key, this.artisanSession});

  @override
  State<ArtisanEnquiriesPage> createState() => _ArtisanEnquiriesPageState();
}

class _ArtisanEnquiriesPageState extends State<ArtisanEnquiriesPage> {
  List<dynamic> enquiries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  Future<void> _loadEnquiries() async {
    setState(() => loading = true);
    final artisanUsername = widget.artisanSession?['username'] ?? 'ramesh_artisan';
    final int? artisanId = widget.artisanSession?['id'] is int
        ? widget.artisanSession!['id'] as int
        : int.tryParse(widget.artisanSession?['id']?.toString() ?? '');

    final list = await ApiService.getEnquiries(
      artisanId: artisanId,
      artisanUsername: artisanUsername,
    );

    if (mounted) {
      setState(() {
        enquiries = list;
        loading = false;
      });
    }
  }

  Future<void> _updateStatus(int enquiryId, String newStatus) async {
    final success = await ApiService.updateEnquiryStatus(enquiryId, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lead status updated to: $newStatus')),
      );
      _loadEnquiries();
    }
  }

  void _showContactBuyerModal(Map<String, dynamic> enq) {
    final buyerName = enq['buyer_name'] ?? 'Buyer';
    final businessName = enq['business_name'] ?? buyerName;
    final phone = enq['buyer_phone'] ?? '9876543210';
    final email = enq['buyer_email'] ?? '';
    final qty = enq['order_quantity'] ?? 50;
    final prodTitle = enq['product_title'] ?? 'Craft';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF7A0B2E),
                  child: Icon(Icons.handshake_outlined, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7A0B2E))),
                      Text('Contact: $buyerName • 📍 ${enq['buyer_location'] ?? 'India'}', style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phone Number:', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                      SelectableText(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C282E))),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Email Address:', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                        SelectableText(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C282E))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enquiry For:', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                      Text('$qty pcs ($prodTitle)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7A0B2E))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3C9A68),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dialing $businessName ($phone)... 📞')),
                      );
                    },
                    icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                    label: const Text('Call Buyer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening WhatsApp chat with $businessName... 💬')),
                      );
                    },
                    icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new lead':
        return Colors.blue.shade700;
      case 'offer received':
      case 'contacted':
        return const Color(0xFFD8A54A);
      case 'quoted':
      case 'under review':
        return Colors.purple.shade700;
      case 'accepted':
      case 'completed':
        return const Color(0xFF3C9A68);
      default:
        return const Color(0xFF7A0B2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Received B2B Enquiries 📩', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7A0B2E)),
            onPressed: _loadEnquiries,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEnquiries,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7A0B2E)))
            : enquiries.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No enquiries received yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'When corporate buyers, retailers, or GeM procure your craft, their direct enquiries will appear here for you to call.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF7D7478)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: enquiries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, idx) {
                      final enq = enquiries[idx];
                      final status = enq['status'] ?? 'New Lead';
                      final statusColor = _getStatusColor(status);
                      final qty = enq['order_quantity'] ?? 50;
                      final price = enq['offer_price']?.toInt() ?? 450;
                      final totalVal = qty * price;
                      final prodTitle = enq['product_title'] ?? 'Artisan Craft';

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          enq['business_name'] ?? enq['buyer_name'] ?? 'Wholesale Buyer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7A0B2E)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${enq['buyer_type'] ?? 'Buyer'} • 📍 ${enq['buyer_location'] ?? 'India'}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) => _updateStatus(enq['id'], val),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'New Lead', child: Text('Mark as New Lead')),
                                      const PopupMenuItem(value: 'Contacted', child: Text('Mark as Contacted')),
                                      const PopupMenuItem(value: 'Under Review', child: Text('Mark as Under Review')),
                                      const PopupMenuItem(value: 'Accepted', child: Text('Mark as Accepted')),
                                      const PopupMenuItem(value: 'Completed', child: Text('Mark as Completed')),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            status,
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                          const Icon(Icons.arrow_drop_down, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Product & Order Details
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Craft: $prodTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Qty: $qty pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7A0B2E))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Quoted Rate: ₹$price/pc', style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                                        Text('Total Order: ₹$totalVal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3C9A68))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Customization requested
                              if (enq['custom_size'] == 1 || enq['custom_design'] == 1 || enq['custom_packaging'] == 1) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (enq['custom_size'] == 1) _tagPill('Custom Size Req.'),
                                    if (enq['custom_design'] == 1) _tagPill('Custom Design Req.'),
                                    if (enq['custom_packaging'] == 1) _tagPill('Custom Packaging Req.'),
                                  ],
                                ),
                              ],
                              if ((enq['custom_notes'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Specs: "${enq['custom_notes']}"',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF7A0B2E), fontStyle: FontStyle.italic),
                                ),
                              ],
                              if ((enq['message'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Buyer Note: "${enq['message']}"',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF2C282E)),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Action Row
                              Row(
                                children: [
                                  Text(
                                    'Received: ${enq['created_at']?.toString().split('T').first ?? 'Today'}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                                  ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF7A0B2E),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _showContactBuyerModal(enq),
                                    icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                                    label: const Text('Contact Buyer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _tagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD8A54A).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
    );
  }
}
