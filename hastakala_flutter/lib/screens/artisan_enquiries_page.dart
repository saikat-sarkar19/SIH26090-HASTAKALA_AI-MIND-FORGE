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

  Future<void> _updateStatus(Map<String, dynamic> enq, String newStatus, {String rejectionReason = ''}) async {
    final enquiryId = enq['id'];
    final buyerName = enq['business_name'] ?? enq['buyer_name'] ?? 'Buyer';
    final success = await ApiService.updateEnquiryStatus(enquiryId, newStatus, rejectionReason: rejectionReason);
    
    if (success && mounted) {
      String msg;
      if (newStatus == 'Accepted') {
        msg = 'Notification sent to $buyerName! Enquiry accepted successfully. ✅';
      } else if (newStatus == 'Rejected') {
        msg = 'Notification sent to $buyerName. Enquiry rejected. ❌';
      } else if (newStatus == 'Completed') {
        msg = 'Enquiry marked as completed and moved to Enquiry History! 📜';
      } else {
        msg = 'Lead status updated to: $newStatus';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: newStatus == 'Rejected' ? Colors.red.shade700 : const Color(0xFF7A0B2E),
        ),
      );
      _loadEnquiries();
    }
  }

  void _showRejectReasonDialog(Map<String, dynamic> enq) {
    final buyerName = enq['business_name'] ?? enq['buyer_name'] ?? 'Buyer';
    final List<String> options = [
      'Production capacity full',
      'Insufficient raw material',
      'Too large order request',
      'Others',
    ];
    String selectedOption = options.first;
    final otherReasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (stCtx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              const Text('Reject Enquiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please select the reason for rejecting this enquiry from $buyerName:',
                style: const TextStyle(fontSize: 13, color: Color(0xFF7D7478)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedOption,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.red.shade700),
                    items: options.map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C282E))),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          selectedOption = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              if (selectedOption == 'Others') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otherReasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type your custom reason...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                String finalReason = selectedOption;
                if (selectedOption == 'Others') {
                  finalReason = otherReasonCtrl.text.trim();
                  if (finalReason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a rejection reason for "Others".')),
                    );
                    return;
                  }
                }
                Navigator.pop(dlgCtx);
                _updateStatus(enq, 'Rejected', rejectionReason: finalReason);
              },
              child: const Text('Confirm Rejection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7A0B2E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(modalCtx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
              ),
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
      case 'accepted':
        return const Color(0xFF3C9A68);
      case 'rejected':
        return Colors.red.shade700;
      case 'completed':
        return Colors.grey.shade700;
      default:
        return const Color(0xFF7A0B2E);
    }
  }

  bool _isHistory(String status) {
    final st = status.toLowerCase();
    return st == 'completed' || st == 'rejected';
  }

  @override
  Widget build(BuildContext context) {
    final activeEnquiries = enquiries.where((e) => !_isHistory((e['status'] ?? '').toString())).toList();
    final historyEnquiries = enquiries.where((e) => _isHistory((e['status'] ?? '').toString())).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: const Color(0xFF7A0B2E),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF7A0B2E),
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Active Enquiries', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (activeEnquiries.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A0B2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${activeEnquiries.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Enquiry History 📜', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (historyEnquiries.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${historyEnquiries.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadEnquiries,
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7A0B2E)))
              : TabBarView(
                  children: [
                    _buildEnquiryList(activeEnquiries, isHistoryTab: false),
                    _buildEnquiryList(historyEnquiries, isHistoryTab: true),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEnquiryList(List<dynamic> list, {required bool isHistoryTab}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHistoryTab ? Icons.history_outlined : Icons.mark_email_read_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isHistoryTab ? 'No enquiry history yet' : 'No active enquiries right now',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
              ),
              const SizedBox(height: 6),
              Text(
                isHistoryTab
                    ? 'Completed and rejected B2B buyer enquiries will be saved here for your records.'
                    : 'When corporate buyers or wholesalers send quotes, active enquiries will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF7D7478)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, idx) {
        final enq = list[idx];
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
                      onSelected: (val) {
                        if (val == 'Rejected') {
                          _showRejectReasonDialog(enq);
                        } else {
                          _updateStatus(enq, val);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'New Lead', child: Text('Mark as New Lead')),
                        const PopupMenuItem(value: 'Accepted', child: Text('Mark as Accepted ✅')),
                        const PopupMenuItem(value: 'Rejected', child: Text('Mark as Rejected ❌')),
                        const PopupMenuItem(value: 'Completed', child: Text('Mark as Completed 📜')),
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

