import 'package:flutter/material.dart';
import 'package:hastakala/screens/buyer_marketplace_page.dart';
import 'package:hastakala/screens/buyer_orders_page.dart';

class BuyerHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? buyerSession;
  final VoidCallback onSwitchToArtisan;
  final VoidCallback onLogout;

  const BuyerHomeScreen({
    super.key,
    this.buyerSession,
    required this.onSwitchToArtisan,
    required this.onLogout,
  });

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int currentIndex = 0;

  void _handleSignOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out of buyer account.'),
        duration: Duration(seconds: 2),
      ),
    );
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BuyerMarketplacePage(
        buyerSession: widget.buyerSession,
        onSwitchToArtisan: widget.onSwitchToArtisan,
      ),
      BuyerOrdersPage(buyerSession: widget.buyerSession),
      _buildBuyerProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => setState(() => currentIndex = idx),
        indicatorColor: const Color(0xFF7A0B2E).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Color(0xFF7A0B2E)),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.mark_email_unread_outlined),
            selectedIcon: Icon(Icons.mark_email_read, color: Color(0xFF7A0B2E)),
            label: 'My Enquiries',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: Color(0xFF7A0B2E)),
            label: 'Business',
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerProfilePage() {
    final s = widget.buyerSession;
    final orgName = s?['organization_name'] ?? s?['business_name'] ?? 'Guest Buyer';
    final person = s?['contact_person'] ?? s?['name'] ?? 'Wholesale Buyer';
    final buyerType = s?['buyer_type'] ?? 'Corporate Wholesale Buyer';
    final location = s?['location'] ?? 'India';
    final email = s?['contact_email'] ?? s?['email'] ?? 'Not set';
    final phone = s?['phone'] ?? 'Not set';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Buyer Business Profile 🏢', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Color(0xFF7A0B2E)),
            onPressed: _handleSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFF7A0B2E),
                  child: Icon(Icons.store, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(orgName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                const SizedBox(height: 2),
                Text('$buyerType • $location', style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _profileRow('Contact Person', person),
                _profileRow('Phone / WhatsApp', phone),
                _profileRow('Business Email', email),
                _profileRow('Location', location),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out of Buyer Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C282E))),
        ],
      ),
    );
  }
}
