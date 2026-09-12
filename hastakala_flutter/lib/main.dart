import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hastakala/services/api_service.dart';
import 'package:hastakala/services/speech_service.dart';

void main() => runApp(const HastakalaApp());

class AppColors {
  static const wine = Color(0xFF7A0B2E);
  static const deepWine = Color(0xFF4A061C);
  static const coral = Color(0xFFE87872);
  static const gold = Color(0xFFD8A54A);
  static const cream = Color(0xFFFFF8F0);
  static const surface = Colors.white;
  static const ink = Color(0xFF2C282E);
  static const muted = Color(0xFF7D7478);
  static const green = Color(0xFF3C9A68);
}

class HastakalaApp extends StatelessWidget {
  const HastakalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hastakala',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.wine,
          primary: AppColors.wine,
          secondary: AppColors.gold,
          surface: Colors.white,
        ),
        fontFamily: 'sans-serif',
      ),
      home: const SplashScreen(),
    );
  }
}

Widget logo({double width = 150}) => Image.asset(
  'assets/images/hastakala_logo.png',
  width: width,
  fit: BoxFit.contain,
  errorBuilder: (ctx, err, stack) => Icon(Icons.palette_outlined, size: width * 0.6, color: AppColors.gold),
);

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const AppButton({super.key, required this.text, this.onPressed, this.icon, this.isLoading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : (icon == null ? const SizedBox.shrink() : Icon(icon)),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.wine,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class PageShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const PageShell({super.key, required this.title, required this.child, this.actions});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    ),
    body: SafeArea(child: child),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080A18),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            logo(width: 260),
            const SizedBox(height: 28),
            const Text(
              'Traditional Artisans.\nGlobal Opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFE4B5), fontSize: 18, height: 1.5),
            ),
            const Spacer(),
            AppButton(
              text: 'Begin your journey',
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * .48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.deepWine, AppColors.wine]),
          ),
          child: Center(child: logo(width: 200)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * .58,
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: Column(
              children: [
                const Text('Welcome to Hastakala', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your AI business manager for artisans', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 24),
                TextField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined),
                    labelText: 'Mobile Number',
                    hintText: '98765 43210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Get OTP',
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                  child: const Text('Continue as Guest Artisan', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  void _navigateToTab(int tabIndex) {
    setState(() {
      index = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onNavigateTab: _navigateToTab),
      const ProductsPage(),
      const AddProductPage(),
      const AssistantPage(),
      const BuyersPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add Craft'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'AI Chatbot'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Buyers'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const DashboardPage({super.key, this.onNavigateTab});
  @override State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> stats = {
    'total_products': 0,
    'total_enquiries': 0,
    'total_buyers': 0,
    'ai_opportunity': {'title': 'Handloom demand is high', 'subtitle': 'Add 2 new designs to attract buyers.'}
  };
  bool backendConnected = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final connected = await ApiService.checkBackendConnection();
    final data = await ApiService.getDashboardStats();
    if (mounted) {
      setState(() {
        backendConnected = connected;
        stats = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            const CircleAvatar(backgroundColor: AppColors.wine, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Namaste, Ramesh!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: backendConnected ? AppColors.green : Colors.orange),
                ),
                const SizedBox(width: 6),
                Text(backendConnected ? 'Backend Connected' : 'Local Mode', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ])),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: QuickAction(
              icon: Icons.camera_alt_outlined, label: 'Add New\nProduct', color: const Color(0xFFFFD9D4),
              onTap: () => widget.onNavigateTab?.call(2),
            )),
            const SizedBox(width: 12),
            Expanded(child: QuickAction(
              icon: Icons.smart_toy_outlined, label: 'Talk to AI\nChatbot', color: const Color(0xFFE6DEFF),
              onTap: () => widget.onNavigateTab?.call(3),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: QuickAction(
              icon: Icons.inventory_2_outlined, label: 'My\nProducts', color: const Color(0xFFD9F0E3),
              onTap: () => widget.onNavigateTab?.call(1),
            )),
            const SizedBox(width: 12),
            Expanded(child: QuickAction(
              icon: Icons.handshake_outlined, label: 'Find\nBuyers', color: const Color(0xFFFFEDC8),
              onTap: () => widget.onNavigateTab?.call(4),
            )),
          ]),
          const SizedBox(height: 24),
          const Text("Today's Business Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: MetricCard(value: '${stats['total_products']}', label: 'Products')),
            const SizedBox(width: 10),
            Expanded(child: MetricCard(value: '${stats['total_enquiries']}', label: 'Enquiries')),
            const SizedBox(width: 10),
            Expanded(child: MetricCard(value: '${stats['total_buyers']}', label: 'Verified Buyers')),
          ]),
          const SizedBox(height: 22),
          const Text('AI Opportunity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4B5), child: Icon(Icons.lightbulb_outline, color: AppColors.gold)),
              title: Text(stats['ai_opportunity']['title'] ?? 'Trending Crafts', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(stats['ai_opportunity']['subtitle'] ?? 'Add designs to get more buyers.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => widget.onNavigateTab?.call(2),
            ),
          ),
        ],
      ),
    ),
  );
}

class QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const QuickAction({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Container(
      height: 120,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 32, color: AppColors.wine),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );
}

class MetricCard extends StatelessWidget {
  final String value, label;
  const MetricCard({super.key, required this.value, required this.label});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECE3DD))),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.wine)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ]),
  );
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});
  @override State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  int step = 0;
  bool processing = false;
  bool publishing = false;
  bool isListening = false;
  bool calculatingPricing = false;

  String selectedLanguage = 'Auto-Detect';
  String detectedLanguage = 'Hindi (हिंदी)';
  String translatedEnglishText = 'Handwoven Banarasi Cotton Saree with authentic Zari embroidery motifs';
  bool isTranslating = false;

  Uint8List? selectedImageBytes;
  String? originalFileName;
  Map<String, dynamic>? enhancedImageResult;
  Map<String, dynamic>? generatedCatalogResult;
  Map<String, dynamic>? pricingData;

  // Persistent Controllers across all phases
  final TextEditingController voiceTextController = TextEditingController(
    text: "Handwoven Banarasi Cotton Saree with authentic Zari embroidery motifs"
  );

  final TextEditingController titleCtrl = TextEditingController(text: "Handwoven Banarasi Silk & Cotton Saree");
  final TextEditingController descEnCtrl = TextEditingController(text: "Exquisite handwoven Banarasi saree handcrafted by traditional master weavers.");
  final TextEditingController descHiCtrl = TextEditingController(text: "पारंपरिक मास्टर बुनकरों द्वारा हस्तनिर्मित उत्कृष्ट हथकरघा बनारसी साड़ी।");
  final TextEditingController catCtrl = TextEditingController(text: "Textiles  ›  Sarees");
  final TextEditingController matCtrl = TextEditingController(text: "Pure Handloom Cotton & Zari Thread");
  final TextEditingController tagsCtrl = TextEditingController(text: "Handloom • Saree • Traditional • Ethnic Wear • Banarasi");

  // Dynamic Pricing Sliders State
  double materialCost = 450.0;
  double laborHours = 12.0;
  double laborRate = 100.0;

  @override
  void initState() {
    super.initState();
    _fetchPricing();
    _translateCurrentText();
  }

  Future<void> _translateCurrentText() async {
    final text = voiceTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        detectedLanguage = '';
        translatedEnglishText = '';
      });
      return;
    }
    setState(() => isTranslating = true);
    final res = await ApiService.translateText(text);
    if (mounted && res != null) {
      setState(() {
        detectedLanguage = res['detected_language'] ?? '';
        translatedEnglishText = res['translated_text'] ?? '';
        isTranslating = false;
      });
    } else {
      if (mounted) setState(() => isTranslating = false);
    }
  }

  Future<void> _fetchPricing() async {
    setState(() => calculatingPricing = true);
    final result = await ApiService.calculatePricing(
      category: catCtrl.text.isNotEmpty ? catCtrl.text : 'Textiles',
      materials: matCtrl.text.isNotEmpty ? matCtrl.text : 'Cotton',
      rawMaterialCost: materialCost,
      laborHours: laborHours,
      laborRate: laborRate,
    );
    if (mounted) {
      setState(() {
        pricingData = result;
        calculatingPricing = false;
      });
    }
  }

  void _syncCatalogToControllers(Map<String, dynamic> catalog) {
    if (catalog['title'] != null && catalog['title'].toString().isNotEmpty) {
      titleCtrl.text = catalog['title'];
    }
    if (catalog['description_en'] != null && catalog['description_en'].toString().isNotEmpty) {
      descEnCtrl.text = catalog['description_en'];
    }
    if (catalog['description_hi'] != null && catalog['description_hi'].toString().isNotEmpty) {
      descHiCtrl.text = catalog['description_hi'];
    }
    if (catalog['category'] != null && catalog['category'].toString().isNotEmpty) {
      catCtrl.text = catalog['category'];
    }
    if (catalog['materials'] != null && catalog['materials'].toString().isNotEmpty) {
      matCtrl.text = catalog['materials'];
    }
    if (catalog['tags'] != null && catalog['tags'].toString().isNotEmpty) {
      tagsCtrl.text = catalog['tags'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (processing) {
      return AIProcessingPage(
        onComplete: () {
          setState(() {
            processing = false;
            step = 2; // Jump to Review Phase
          });
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Product', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Top Step Indicator Bar (Phases 1, 2, 3, 4) - Tappable Header
            _buildStepIndicatorHeader(),
            const SizedBox(height: 16),

            // Active Phase Content
            Expanded(
              child: _buildCurrentStepContent(),
            ),

            const SizedBox(height: 12),

            // Universal Back and Next Navigation Buttons Row
            _buildBottomNavigationRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicatorHeader() {
    final labels = ['Photo', 'Voice', 'Review', 'Pricing'];
    return Row(
      children: List.generate(4, (i) {
        final isActive = i == step;
        final isCompleted = i < step;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Tappable phase step indicators so users can jump to any step!
              setState(() => step = i);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive
                        ? AppColors.wine
                        : (isCompleted ? AppColors.green : const Color(0xFFE5E0DC)),
                    radius: 15,
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.wine : (isCompleted ? AppColors.green : AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (step) {
      case 0:
        return _photoStep();
      case 1:
        return _voiceStep();
      case 2:
        return _reviewStep();
      case 3:
        return _pricingStep();
      default:
        return _photoStep();
    }
  }

  Widget _buildBottomNavigationRow() {
    final backLabels = ['', 'Back to Photo', 'Back to Voice', 'Back to Review'];
    final nextLabels = ['Next: Voice →', 'Next: Review →', 'Next: Pricing →', 'Publish Product 🚀'];

    return Row(
      children: [
        if (step > 0) ...[
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    step = step - 1;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.wine),
                label: Text(
                  backLabels[step],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.wine, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.wine, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: step == 0 ? 1 : 1,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: publishing ? null : _onNextPressed,
              icon: publishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(step == 3 ? Icons.rocket_launch_outlined : Icons.arrow_forward, size: 18),
              label: Text(
                nextLabels[step],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onNextPressed() async {
    if (step == 0) {
      setState(() => step = 1);
    } else if (step == 1) {
      // If voice text provided and catalog not generated yet, generate catalog automatically
      if (voiceTextController.text.trim().isNotEmpty && generatedCatalogResult == null) {
        setState(() => processing = true);
        final catalog = await ApiService.generateCatalog(voiceTextController.text);
        if (catalog != null) {
          _syncCatalogToControllers(catalog);
          generatedCatalogResult = catalog;
        }
        setState(() {
          processing = false;
          step = 2;
        });
      } else {
        setState(() => step = 2);
      }
    } else if (step == 2) {
      _fetchPricing();
      setState(() => step = 3);
    } else if (step == 3) {
      _publishProduct();
    }
  }

  Future<void> _publishProduct() async {
    setState(() => publishing = true);
    final retail = pricingData?['price_retail'] ?? 999;
    final wholesale = pricingData?['price_wholesale'] ?? 750;
    final minPrice = pricingData?['min_price'] ?? 550;

    final success = await ApiService.publishProduct({
      'title': titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Handcrafted Artisan Product',
      'description_en': descEnCtrl.text,
      'description_hi': descHiCtrl.text,
      'category': catCtrl.text,
      'materials': matCtrl.text,
      'tags': tagsCtrl.text,
      'price_retail': (retail as num).toDouble(),
      'price_wholesale': (wholesale as num).toDouble(),
      'min_price': (minPrice as num).toDouble(),
      'material_cost': materialCost,
      'labor_cost': laborHours * laborRate,
      'production_days': (laborHours / 8).ceil(),
      'raw_image_url': enhancedImageResult?['raw_image_url'] ?? '',
      'enhanced_image_url': enhancedImageResult?['enhanced_image_url'] ?? '',
    });

    if (mounted) {
      setState(() => publishing = false);
      if (success) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishedPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to publish product. Please check backend.')));
      }
    }
  }

  Widget _photoStep() {
    final hasEnhanced = enhancedImageResult != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('1. AI Image Studio & Enhancer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Capture your product photo. AI will clean background & apply studio lighting.', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 18),
      Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF0ECE9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2D8D1)),
          ),
          child: hasEnhanced
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Original Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('AI Studio Enhanced ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        ApiService.getFullImageUrl(enhancedImageResult!['enhanced_image_url']),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(color: Colors.white, child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 40)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.white,
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppColors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Studio background & lighting applied', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(radius: 36, backgroundColor: AppColors.wine, child: Icon(Icons.camera_alt_outlined, size: 34, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text('Tap to capture or choose photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickAndEnhanceImage(ImageSource.camera),
                          icon: const Icon(Icons.camera),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cream,
                            foregroundColor: AppColors.wine,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _pickAndEnhanceImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cream,
                            foregroundColor: AppColors.wine,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    ]);
  }

  Future<void> _pickAndEnhanceImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          selectedImageBytes = bytes;
          originalFileName = picked.name;
          processing = true;
        });
        final result = await ApiService.enhanceImage(bytes, picked.name);
        setState(() {
          enhancedImageResult = result;
          processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image selection error: $e')));
      }
    }
  }

  Widget _voiceStep() {
    final sampleVoices = [
      {'lang': 'हिंदी (Hindi)', 'text': 'यह बनारसी सूती धागे से बनी हाथ से बुनी गई साड़ी है जिसमें सुंदर ज़री का काम है'},
      {'lang': 'বাংলা (Bengali)', 'text': 'এটি প্রাকৃতিক বাঁশ দিয়ে তৈরি হাতে বোনা সুন্দর ঝুড়ি'},
      {'lang': 'ગુજરાતી (Gujarati)', 'text': 'આ હાથથી બનાવેલું ટેરાકોટા માટીનું સુંદર માટલું છે'},
      {'lang': 'मराठी (Marathi)', 'text': 'हे लाकडावर हस्तकला करून बनवलेले पारंपरिक शोकेस पीस आहे'},
      {'lang': 'தமிழ் (Tamil)', 'text': 'இதுபாரம்பரிய தறி நெசவு மூலம் செய்யப்பட்ட கைத்தறி சேலை'},
      {'lang': 'English', 'text': 'Handcrafted terracotta clay water pitcher made with natural bio clay'},
    ];

    return SingleChildScrollView(
      child: Column(children: [
        const Text('2. Multilingual Voice Cataloger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Speak into your microphone or type details in any regional language.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Speech Language:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.wine)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8D1)),
              ),
              child: DropdownButton<String>(
                value: selectedLanguage,
                underline: Container(),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.wine),
                items: const [
                  DropdownMenuItem(value: 'Auto-Detect', child: Text('🌐 Auto-Detect (Any Language)')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('🇮🇳 Hindi (हिंदी)')),
                  DropdownMenuItem(value: 'en-US', child: Text('🇺🇸 English')),
                  DropdownMenuItem(value: 'bn-IN', child: Text('🇮🇳 Bengali (বাংলা)')),
                  DropdownMenuItem(value: 'gu-IN', child: Text('🇮🇳 Gujarati (ગુજરાતી)')),
                  DropdownMenuItem(value: 'mr-IN', child: Text('🇮🇳 Marathi (मराठी)')),
                  DropdownMenuItem(value: 'ta-IN', child: Text('🇮🇳 Tamil (தமிழ்)')),
                  DropdownMenuItem(value: 'te-IN', child: Text('🇮🇳 Telugu (తెలుగు)')),
                  DropdownMenuItem(value: 'kn-IN', child: Text('🇮🇳 Kannada (ಕನ್ನಡ)')),
                  DropdownMenuItem(value: 'ml-IN', child: Text('🇮🇳 Malayalam (മലയാളം)')),
                  DropdownMenuItem(value: 'pa-IN', child: Text('🇮🇳 Punjabi (ਪੰਜਾਬੀ)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedLanguage = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: voiceTextController,
          maxLines: 3,
          onChanged: (_) => _translateCurrentText(),
          decoration: InputDecoration(
            labelText: 'Spoken Description / Transcript',
            hintText: 'Speak using mic or type e.g. यह सूती धागे से बनी हाथ से बुनी साड़ी है...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : AppColors.wine),
              onPressed: _toggleVoiceRecording,
            ),
          ),
        ),

        if (voiceTextController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2D8D1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate, size: 18, color: AppColors.wine),
                        const SizedBox(width: 6),
                        Text(
                          detectedLanguage.isNotEmpty ? 'Detected: $detectedLanguage' : 'Google Translate Auto-Detecting...',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine),
                        ),
                      ],
                    ),
                    if (isTranslating)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wine))
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Google Translate API', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const Divider(height: 16),
                const Text('Original Regional Text:', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(voiceTextController.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (translatedEnglishText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('English Translation (Google Translate):', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(translatedEnglishText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.wine)),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        GestureDetector(
          onTap: _toggleVoiceRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? Colors.red : AppColors.wine,
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Colors.red : AppColors.wine).withValues(alpha: 0.4),
                  blurRadius: isListening ? 26 : 12,
                  spreadRadius: isListening ? 8 : 2,
                )
              ],
            ),
            child: Icon(isListening ? Icons.graphic_eq : Icons.mic, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isListening ? '🔴 Listening to your Microphone... Speak in any language!' : 'Tap Microphone to Speak (Uses Live Web Speech)',
          style: TextStyle(fontWeight: FontWeight.bold, color: isListening ? Colors.red : AppColors.wine, fontSize: 13),
        ),
        if (isListening) ...[
          const SizedBox(height: 6),
          const SizedBox(width: 140, child: LinearProgressIndicator(color: Colors.red)),
        ],

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickAndProcessAudioFile,
          icon: const Icon(Icons.audio_file, color: AppColors.wine),
          label: const Text('Upload Voice Note (.wav / .mp3 / .m4a)', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.wine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 20),
        const Align(alignment: Alignment.centerLeft, child: Text('Quick Regional Voice Samples:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: sampleVoices.map((v) => ActionChip(
            avatar: const Icon(Icons.record_voice_over, size: 14, color: AppColors.wine),
            label: Text(v['lang']!, style: const TextStyle(fontSize: 11)),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2D8D1)),
            onPressed: () {
              setState(() {
                voiceTextController.text = v['text']!;
              });
              _translateCurrentText();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Loaded ${v['lang']} voice sample!'),
                duration: const Duration(seconds: 1),
              ));
            },
          )).toList(),
        ),
      ]),
    );
  }

  void _toggleVoiceRecording() {
    if (isListening) {
      SpeechService.stopListening();
      setState(() => isListening = false);
    } else {
      setState(() => isListening = true);
      final langCode = selectedLanguage == 'Auto-Detect' ? 'hi-IN' : selectedLanguage;
      final success = SpeechService.startListening(
        languageCode: langCode,
        onResult: (text) {
          if (mounted) {
            setState(() {
              voiceTextController.text = text;
            });
            _translateCurrentText();
          }
        },
        onEnd: () {
          if (mounted) {
            setState(() => isListening = false);
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() => isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Microphone Error: $err. Please check browser mic permissions.'),
              backgroundColor: Colors.red,
            ));
          }
        },
      );

      if (!success) {
        setState(() => isListening = false);
      }
    }
  }

  Future<void> _pickAndProcessAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'webm'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() => processing = true);
          final catalog = await ApiService.generateCatalogFromAudio(file.bytes!, file.name);
          if (catalog != null) {
            _syncCatalogToControllers(catalog);
            generatedCatalogResult = catalog;
          }
          setState(() {
            processing = false;
            step = 2;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Audio file ${file.name} processed by AI Cataloger! ✨'),
              backgroundColor: AppColors.green,
            ));
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio file selection error: $e')));
    }
  }

  Widget _reviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3. Review & Edit AI Catalog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Review AI-generated attributes. Feel free to edit any field before pricing.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          if (enhancedImageResult != null)
            Container(
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gold)),
              child: Image.network(
                ApiService.getFullImageUrl(enhancedImageResult!['enhanced_image_url']),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppColors.cream, child: const Icon(Icons.image_outlined, size: 60, color: AppColors.wine)),
              ),
            ),
          const SizedBox(height: 16),
          _editableField('Product Name', titleCtrl),
          _editableField('English Description (SEO)', descEnCtrl, maxLines: 3),
          _editableField('Hindi Description (हिंदी विवरण)', descHiCtrl, maxLines: 3),
          _editableField('Category', catCtrl),
          _editableField('Materials', matCtrl),
          _editableField('Tags', tagsCtrl),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController controller, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2D8D1))),
        ),
      ),
    ]),
  );

  Widget _pricingStep() {
    final retail = pricingData?['price_retail'] ?? 999;
    final wholesale = pricingData?['price_wholesale'] ?? 750;
    final minPrice = pricingData?['min_price'] ?? 550;
    final range = pricingData?['market_range'] ?? '₹700 – ₹1,200';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('4. Dynamic Pricing Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('AI recommended pricing based on raw materials, craft labor, and market demand.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Product Title', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(catCtrl.text),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFDFF2E7), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI Market Pricing Suggestion', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: PriceBox(title: 'Retail Price (D2C)', price: '₹${retail.toInt()}')),
                const SizedBox(width: 12),
                Expanded(child: PriceBox(title: 'Wholesale (B2B)', price: '₹${wholesale.toInt()}')),
              ]),
              const SizedBox(height: 10),
              Text('Fair Price Floor: ₹${minPrice.toInt()} | Market Range: $range', style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('Adjust Production Costs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Material Cost'),
                  Text('₹${materialCost.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                Slider(
                  value: materialCost,
                  min: 50, max: 2000, divisions: 39,
                  onChanged: (v) {
                    setState(() => materialCost = v);
                    _fetchPricing();
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Labor Hours'),
                  Text('${laborHours.toInt()} hours', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                Slider(
                  value: laborHours,
                  min: 1, max: 40, divisions: 39,
                  onChanged: (v) {
                    setState(() => laborHours = v);
                    _fetchPricing();
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class AIProcessingPage extends StatefulWidget {
  final VoidCallback onComplete;
  const AIProcessingPage({super.key, required this.onComplete});
  @override State<AIProcessingPage> createState() => _AIProcessingPageState();
}

class _AIProcessingPageState extends State<AIProcessingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onComplete();
    });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.deepWine,
    body: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.auto_awesome, size: 80, color: AppColors.gold),
      SizedBox(height: 24),
      Text('Hastakala AI Working...', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      SizedBox(height: 10),
      Text('Creating e-commerce photos & catalog', style: TextStyle(color: Colors.white70)),
      SizedBox(height: 28),
      CircularProgressIndicator(color: AppColors.gold),
    ])),
  );
}

class PriceBox extends StatelessWidget {
  final String title, price;
  const PriceBox({super.key, required this.title, required this.price});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      const SizedBox(height: 6),
      Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.wine)),
    ]),
  );
}

class PublishedPage extends StatelessWidget {
  const PublishedPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircleAvatar(radius: 54, backgroundColor: AppColors.green, child: Icon(Icons.check, size: 60, color: Colors.white)),
        const SizedBox(height: 24),
        const Text('Product Published!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Your product is now listed and available to GeM & B2B buyers across India.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 34),
        AppButton(text: 'Return to Dashboard', onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
      ]),
    )),
  );
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await ApiService.getProducts();
    if (mounted) {
      setState(() {
        products = list;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('My Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ]),
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(child: Text('No products published yet.'))
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final p = products[i];
                        final imgUrl = p['enhanced_image_url'] ?? p['raw_image_url'] ?? '';
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Container(
                                color: const Color(0xFFE9DED3),
                                width: double.infinity,
                                child: imgUrl.isNotEmpty
                                    ? Image.network(
                                        ApiService.getFullImageUrl(imgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.image_outlined, size: 48, color: AppColors.wine),
                                      )
                                    : const Icon(Icons.image_outlined, size: 48, color: AppColors.wine),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('₹${p['price_retail']?.toInt() ?? 0}', style: const TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.check_circle, color: AppColors.green, size: 12),
                                  const SizedBox(width: 4),
                                  Text(p['status'] ?? 'Published', style: const TextStyle(color: AppColors.green, fontSize: 11)),
                                ]),
                              ]),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
      ),
    ]),
  );
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final List<Map<String, String>> messages = [
    {
      'text': 'Namaste Ramesh! 🙏 I am your Hastakala AI Chatbot. Ask me anything about craft pricing, finding bulk B2B buyers, trending designs, or government artisan schemes!',
      'sender': 'ai'
    }
  ];
  final TextEditingController inputCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  bool typing = false;
  bool isListening = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage(String query) async {
    if (query.trim().isEmpty) return;
    final text = query.trim();
    setState(() {
      messages.add({'text': text, 'sender': 'user'});
      typing = true;
    });
    inputCtrl.clear();
    _scrollToBottom();

    final res = await ApiService.chatAssistant(text);
    if (mounted) {
      setState(() {
        typing = false;
        messages.add({
          'text': res?['reply'] ?? 'Namaste! I am here to help your artisan business grow.',
          'sender': 'ai'
        });
      });
      _scrollToBottom();
    }
  }

  void _toggleMic() {
    if (isListening) {
      SpeechService.stopListening();
      setState(() => isListening = false);
    } else {
      setState(() => isListening = true);
      final success = SpeechService.startListening(
        languageCode: 'hi-IN',
        onResult: (resultText) {
          if (mounted) {
            setState(() {
              inputCtrl.text = resultText;
            });
          }
        },
        onEnd: () {
          if (mounted) {
            setState(() => isListening = false);
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() => isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Mic Error: $err'),
              backgroundColor: Colors.red,
            ));
          }
        },
      );
      if (!success) {
        setState(() => isListening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.wine,
              radius: 20,
              child: Icon(Icons.smart_toy, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Chatbot Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                  ),
                  const SizedBox(width: 6),
                  const Text('Online • Hastakala Intelligence', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            controller: scrollCtrl,
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final m = messages[i];
              final isAi = m['sender'] == 'ai';
              return Row(
                mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAi) ...[
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.wine,
                      child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAi ? Colors.white : AppColors.wine,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isAi ? 4 : 16),
                          bottomRight: Radius.circular(isAi ? 16 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        m['text']!,
                        style: TextStyle(
                          color: isAi ? AppColors.ink : Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (!isAi) ...[
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.gold,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (typing) ...[
          const SizedBox(height: 8),
          Row(children: const [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wine)),
            SizedBox(width: 10),
            Text('AI Chatbot is typing answer...', style: TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic)),
          ]),
        ],
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _suggestionChip('How much should I sell saree for?'),
            const SizedBox(width: 6),
            _suggestionChip('Find verified buyers for handloom'),
            const SizedBox(width: 6),
            _suggestionChip('PM Vishwakarma Loan Scheme'),
            const SizedBox(width: 6),
            _suggestionChip('Which crafts are trending this week?'),
          ]),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputCtrl,
                decoration: InputDecoration(
                  hintText: isListening ? 'Listening... Speak into mic' : 'Ask AI Chatbot...',
                  hintStyle: TextStyle(color: isListening ? Colors.red : AppColors.muted),
                  prefixIcon: IconButton(
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : AppColors.wine),
                    onPressed: _toggleMic,
                    tooltip: 'Speak query via mic',
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2D8D1))),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.wine,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => sendMessage(inputCtrl.text),
              ),
            ),
          ],
        ),
      ]),
    ),
  );

  Widget _suggestionChip(String text) => ActionChip(
    avatar: const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.wine),
    label: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    backgroundColor: Colors.white,
    side: const BorderSide(color: Color(0xFFE2D8D1)),
    onPressed: () => sendMessage(text),
  );
}

class BuyersPage extends StatefulWidget {
  const BuyersPage({super.key});
  @override State<BuyersPage> createState() => _BuyersPageState();
}

class _BuyersPageState extends State<BuyersPage> {
  List<dynamic> buyers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    final list = await ApiService.getBuyers();
    if (mounted) {
      setState(() {
        buyers = list;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageShell(
    title: 'Verified B2B Buyers & GeM',
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buyers.length,
            itemBuilder: (_, i) {
              final b = buyers[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(backgroundColor: AppColors.wine, child: Icon(Icons.store, color: Colors.white)),
                  title: Text(b['organization_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Text('${b['buyer_type']} • ${b['location']}'),
                    const SizedBox(height: 4),
                    Text('Target: ${b['target_category']}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text('Min Order: ${b['min_order_qty']} units', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                  ]),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connecting to ${b['organization_name']}...')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.wine, foregroundColor: Colors.white),
                    child: const Text('Connect'),
                  ),
                ),
              );
            },
          ),
  );
}
