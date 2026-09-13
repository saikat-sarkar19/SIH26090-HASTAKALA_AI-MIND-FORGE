import 'package:flutter/material.dart';
import 'package:hastakala/services/api_service.dart';

class BuyerOrdersPage extends StatefulWidget {
  final Map<String, dynamic>? buyerSession;

  const BuyerOrdersPage({super.key, this.buyerSession});

  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  List<dynamic> enquiries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  Future<void> _loadEnquiries() async {
    setState(() => loading = true);
    final buyerId = widget.buyerSession?['id'];
    final buyerName = widget.buyerSession?['organization_name'] ?? widget.buyerSession?['contact_person'];

    final list = await ApiService.getEnquiries(
      buyerId: buyerId is int ? buyerId : null,
      buyerName: buyerName is String && buyerName.isNotEmpty ? buyerName : null,
    );

    if (mounted) {
      setState(() {
        enquiries = list;
        loading = false;
      });
    }
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
        title: const Text('My B2B Enquiries 📩', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No enquiries sent yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Browse products in the marketplace and send your first business enquiry with customized quantity and requirements.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF7D7478)),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A0B2E)),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.storefront),
                            label: const Text('Browse Products'),
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
                      final approxVal = qty * price;
                      final productTitle = enq['product_title'] ?? 'Artisan Craft';

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
                                          productTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Enquiry #${enq['id']} • ${enq['created_at']?.toString().split('T').first ?? 'Recent'}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Order Quantity', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                                      Text('$qty pieces', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Unit Rate', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                                      Text('₹$price / pc', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7A0B2E))),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Approx. Value', style: TextStyle(fontSize: 11, color: Color(0xFF7D7478))),
                                      Text('₹$approxVal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3C9A68))),
                                    ],
                                  ),
                                ],
                              ),
                              if (enq['custom_size'] == 1 || enq['custom_design'] == 1 || enq['custom_packaging'] == 1) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (enq['custom_size'] == 1) _tagPill('Custom Size'),
                                    if (enq['custom_design'] == 1) _tagPill('Custom Design'),
                                    if (enq['custom_packaging'] == 1) _tagPill('Custom Packaging'),
                                  ],
                                ),
                              ],
                              if ((enq['message'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8F0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Message: "${enq['message']}"',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF2C282E), fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF3C9A68)),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Artisan receives your contact info directly.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF7D7478)),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(color: Color(0xFF7A0B2E)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Contact request sent to artisan for Enquiry #${enq['id']}')),
                                      );
                                    },
                                    icon: const Icon(Icons.phone, size: 14, color: Color(0xFF7A0B2E)),
                                    label: const Text('Contact', style: TextStyle(color: Color(0xFF7A0B2E), fontSize: 12, fontWeight: FontWeight.bold)),
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
