import 'package:flutter/material.dart';
import 'package:hastakala/services/api_service.dart';

class BuyerAuthPage extends StatefulWidget {
  final Function(Map<String, dynamic> session) onBuyerLoggedIn;
  final VoidCallback onSwitchToArtisan;
  final bool initialRegister;

  const BuyerAuthPage({
    super.key,
    required this.onBuyerLoggedIn,
    required this.onSwitchToArtisan,
    this.initialRegister = false,
  });

  @override
  State<BuyerAuthPage> createState() => _BuyerAuthPageState();
}

class _BuyerAuthPageState extends State<BuyerAuthPage> {
  late bool isLogin;
  bool loading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    isLogin = !widget.initialRegister;
  }

  // Controllers for Login
  final TextEditingController loginUsernameCtrl = TextEditingController();
  final TextEditingController loginPasswordCtrl = TextEditingController();
  final FocusNode loginPasswordFocusNode = FocusNode();

  // Controllers for Register
  final TextEditingController regOrgNameCtrl = TextEditingController();
  final TextEditingController regContactPersonCtrl = TextEditingController();
  final TextEditingController regUsernameCtrl = TextEditingController();
  final TextEditingController regPasswordCtrl = TextEditingController();
  final FocusNode regPasswordFocusNode = FocusNode();
  final TextEditingController regPhoneCtrl = TextEditingController();
  final TextEditingController regEmailCtrl = TextEditingController();
  final TextEditingController regLocationCtrl = TextEditingController(text: 'Mumbai, Maharashtra');
  String selectedBuyerType = 'Corporate Wholesale Buyer';

  final List<String> buyerTypes = [
    'Corporate Wholesale Buyer',
    'Retail Boutique Owner',
    'Government Procurement (GeM)',
    'Fair & Exhibition Exporter',
    'Cooperative Federation / NGO',
  ];

  @override
  void dispose() {
    loginUsernameCtrl.dispose();
    loginPasswordCtrl.dispose();
    loginPasswordFocusNode.dispose();
    regOrgNameCtrl.dispose();
    regContactPersonCtrl.dispose();
    regUsernameCtrl.dispose();
    regPasswordCtrl.dispose();
    regPasswordFocusNode.dispose();
    regPhoneCtrl.dispose();
    regEmailCtrl.dispose();
    regLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = loginUsernameCtrl.text.trim();
    final password = loginPasswordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter buyer username and password.')),
      );
      return;
    }

    setState(() => loading = true);
    final res = await ApiService.loginBuyer(username, password);
    if (!mounted) return;
    setState(() => loading = false);

    if (res != null && res['status'] == 'success' && res['buyer'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, ${res['buyer']['organization_name'] ?? 'Buyer'}! 🎉')),
      );
      widget.onBuyerLoggedIn(res['buyer']);
    } else {
      final err = res?['detail'] ?? 'Invalid buyer credentials. Please check your username and password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _handleRegister() async {
    final org = regOrgNameCtrl.text.trim();
    final person = regContactPersonCtrl.text.trim();
    final user = regUsernameCtrl.text.trim();
    final pwd = regPasswordCtrl.text.trim();
    final phone = regPhoneCtrl.text.trim();
    final email = regEmailCtrl.text.trim();
    final loc = regLocationCtrl.text.trim();

    if (org.isEmpty || user.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (Organization, Username, Password).')),
      );
      return;
    }

    setState(() => loading = true);
    final res = await ApiService.registerBuyer(
      organizationName: org,
      contactPerson: person,
      username: user,
      password: pwd,
      phone: phone,
      contactEmail: email,
      location: loc.isNotEmpty ? loc : 'India',
      buyerType: selectedBuyerType,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res != null && res['status'] == 'success' && res['buyer'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buyer Account created! Welcome, $org! 🎉')),
      );
      widget.onBuyerLoggedIn(res['buyer']);
    } else {
      final err = res?['detail'] ?? 'Registration failed. Username may already exist.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade800),
      );
    }
  }

  void _continueAsGuestBuyer() {
    final guestSession = {
      'id': 0,
      'organization_name': 'Guest Business Buyer',
      'contact_person': 'Guest Buyer',
      'username': 'guest_buyer',
      'buyer_type': 'Wholesale Buyer',
      'location': 'India',
    };
    widget.onBuyerLoggedIn(guestSession);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A061C),
      body: SafeArea(
        child: Column(
          children: [
            // Top Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hastakala B2B',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Wholesale Marketplace for Artisans',
                        style: TextStyle(fontSize: 12, color: const Color(0xFFFFE4B5).withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFE4B5)),
                    onPressed: widget.onSwitchToArtisan,
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('Artisan Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Form Body Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Toggle Tab (Login vs Register)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isLogin ? const Color(0xFF7A0B2E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Buyer Sign In',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isLogin ? Colors.white : const Color(0xFF7D7478),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isLogin ? const Color(0xFF7A0B2E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Register Business',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !isLogin ? Colors.white : const Color(0xFF7D7478),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (isLogin) ...[
                        // Buyer Login Form
                        const Text(
                          'Business Buyer Login',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Source directly from master rural artisans with bulk MOQ pricing', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                        const SizedBox(height: 20),

                        TextField(
                          controller: loginUsernameCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF7A0B2E)),
                            labelText: 'Username, Email, or Phone',
                            hintText: 'e.g. fabindia_buyer or gem_buyer',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          key: ValueKey('buyer_login_pass_${obscurePassword}'),
                          controller: loginPasswordCtrl,
                          focusNode: loginPasswordFocusNode,
                          obscureText: obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF7A0B2E)),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                              onPressed: () {
                                setState(() => obscurePassword = !obscurePassword);
                                loginPasswordCtrl.selection = TextSelection.fromPosition(TextPosition(offset: loginPasswordCtrl.text.length));
                                loginPasswordFocusNode.requestFocus();
                              },
                            ),
                            labelText: 'Password',
                            hintText: 'Enter password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF7A0B2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: loading ? null : _handleLogin,
                            child: loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In as Buyer 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else ...[
                        // Buyer Register Form
                        const Text(
                          'Register as Business Buyer',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Join to place B2B bulk orders directly with verified artisans', style: TextStyle(fontSize: 12, color: Color(0xFF7D7478))),
                        const SizedBox(height: 16),

                        TextField(
                          controller: regOrgNameCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.store, color: Color(0xFF7A0B2E)),
                            labelText: 'Company / Business Name *',
                            hintText: 'e.g. FabIndia, Heritage Boutique',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: regContactPersonCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7A0B2E)),
                                  labelText: 'Contact Person',
                                  hintText: 'Your name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: regUsernameCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF7A0B2E)),
                                  labelText: 'Username *',
                                  hintText: 'e.g. fab_buyer',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: regPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7A0B2E)),
                                  labelText: 'Phone',
                                  hintText: '10 digits',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: regEmailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7A0B2E)),
                                  labelText: 'Email',
                                  hintText: 'b2b@org.com',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: selectedBuyerType,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF7A0B2E)),
                            labelText: 'Buyer Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: buyerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => selectedBuyerType = v ?? selectedBuyerType),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: regLocationCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF7A0B2E)),
                            labelText: 'City / State',
                            hintText: 'e.g. Mumbai, Maharashtra',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          key: ValueKey('buyer_reg_pass_${obscurePassword}'),
                          controller: regPasswordCtrl,
                          focusNode: regPasswordFocusNode,
                          obscureText: obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF7A0B2E)),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                              onPressed: () {
                                setState(() => obscurePassword = !obscurePassword);
                                regPasswordCtrl.selection = TextSelection.fromPosition(TextPosition(offset: regPasswordCtrl.text.length));
                                regPasswordFocusNode.requestFocus();
                              },
                            ),
                            labelText: 'Create Password *',
                            hintText: 'At least 4 chars',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF7A0B2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: loading ? null : _handleRegister,
                            child: loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Register & Access Marketplace 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Color(0xFF7D7478), fontSize: 11))),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Continue as Guest Buyer
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7A0B2E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _continueAsGuestBuyer,
                        icon: const Icon(Icons.explore_outlined, color: Color(0xFF7A0B2E)),
                        label: const Text(
                          'Browse Marketplace as Guest Buyer 🛍️',
                          style: TextStyle(color: Color(0xFF7A0B2E), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!isLogin) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have a buyer account? ", style: TextStyle(color: Color(0xFF7D7478), fontSize: 13)),
                            GestureDetector(
                              onTap: () => setState(() => isLogin = true),
                              child: const Text('Sign In', style: TextStyle(color: Color(0xFF7A0B2E), fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Demo Buyer Accounts Hint
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8A54A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD8A54A).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 Demo Buyer Logins:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A0B2E))),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  loginUsernameCtrl.text = 'fabindia_buyer';
                                  loginPasswordCtrl.text = 'password123';
                                  setState(() => isLogin = true);
                                },
                                child: const Text('• fabindia_buyer / password123 (Tap to auto-fill)', style: TextStyle(fontSize: 11, color: Color(0xFF7A0B2E), decoration: TextDecoration.underline)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  loginUsernameCtrl.text = 'gem_buyer';
                                  loginPasswordCtrl.text = 'password123';
                                  setState(() => isLogin = true);
                                },
                                child: const Text('• gem_buyer / password123 (Government GeM Buyer)', style: TextStyle(fontSize: 11, color: Color(0xFF7A0B2E), decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
