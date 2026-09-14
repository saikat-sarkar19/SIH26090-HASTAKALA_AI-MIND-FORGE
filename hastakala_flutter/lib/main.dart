import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hastakala/services/api_service.dart';
import 'package:hastakala/services/speech_service.dart';
import 'package:hastakala/screens/buyer_home_screen.dart';
import 'package:hastakala/screens/buyer_auth_page.dart';
import 'package:hastakala/screens/artisan_enquiries_page.dart';


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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void logoutBuyer([BuildContext? ctx]) {
  currentBuyerSession = null;
  final nav = rootNavigatorKey.currentState;
  if (nav != null) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  } else if (ctx != null && ctx.mounted) {
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

void switchToArtisan([BuildContext? ctx]) {
  if (ctx != null && Navigator.canPop(ctx)) {
    Navigator.pop(ctx);
    return;
  }
  final nav = rootNavigatorKey.currentState;
  if (nav != null) {
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } else if (ctx != null && ctx.mounted) {
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}

class HastakalaApp extends StatelessWidget {
  const HastakalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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


Map<String, dynamic>? currentBuyerSession = {
  'id': 1,
  'organization_name': 'FabIndia B2B Procurement',
  'contact_person': 'Sunita Verma',
  'username': 'fabindia_buyer',
  'buyer_type': 'Corporate Wholesale Buyer',
  'location': 'Mumbai, Maharashtra',
  'contact_email': 'b2b@fabindia.com',
  'phone': '+91 98200 11223',
};

Map<String, dynamic>? currentArtisanSession = {
  'id': 1,
  'name': 'Ramesh Kumar',
  'username': 'ramesh_artisan',
  'phone': '9876543210',
  'gender': 'Male',
  'craft_type': 'Master Weaver & Bamboo Craftsman',
  'location': 'Varanasi, Uttar Pradesh',
  'profile_picture': '',
};

Map<String, Map<String, dynamic>> defaultAvatarPresets = {
  'preset:weaver': {'name': 'Handloom Weaver', 'color': Color(0xFF7A0B2E), 'icon': Icons.texture},
  'preset:potter': {'name': 'Pottery Craftsman', 'color': Color(0xFFD8703C), 'icon': Icons.soup_kitchen_outlined},
  'preset:bamboo': {'name': 'Bamboo Artisan', 'color': Color(0xFF2E7D32), 'icon': Icons.eco_outlined},
  'preset:painter': {'name': 'Heritage Artist', 'color': Color(0xFFE87872), 'icon': Icons.palette_outlined},
  'preset:master': {'name': 'Master Craftsman', 'color': Color(0xFFD8A54A), 'icon': Icons.workspace_premium_outlined},
};

Widget buildArtisanAvatar({
  double radius = 24,
  Map<String, dynamic>? session,
  VoidCallback? onTap,
  bool showEditBadge = false,
}) {
  final s = session ?? currentArtisanSession;
  final name = s?['name'] ?? 'Artisan';
  final pic = (s?['profile_picture'] ?? '').toString();
  final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A';

  Widget avatarWidget;

  if (pic.startsWith('preset:')) {
    final presetInfo = defaultAvatarPresets[pic] ?? defaultAvatarPresets['preset:weaver']!;
    avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: presetInfo['color'] as Color,
      child: Icon(presetInfo['icon'] as IconData, color: Colors.white, size: radius * 1.1),
    );
  } else if (pic.isNotEmpty) {
    ImageProvider? bgImage;
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      bgImage = NetworkImage(pic);
    } else if (pic.startsWith('data:image') || pic.length > 50) {
      try {
        final cleanBase64 = pic.contains(',') ? pic.split(',').last : pic;
        final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
        bgImage = MemoryImage(bytes);
      } catch (e) {
        debugPrint('Avatar base64 parse error: $e');
      }
    }
    avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.wine,
      backgroundImage: bgImage,
      child: bgImage == null
          ? Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.85))
          : null,
    );
  } else {
    avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.wine,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.85),
      ),
    );
  }

  if (showEditBadge) {
    avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: AppColors.wine,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  if (onTap != null) {
    return GestureDetector(onTap: onTap, child: avatarWidget);
  }
  return avatarWidget;
}

Future<void> saveArtisanProfilePicture(BuildContext context, String pictureValue, {VoidCallback? onUpdated}) async {
  try {
    if (currentArtisanSession != null) {
      final username = (currentArtisanSession!['username'] ?? '').toString().trim();
      final phone = (currentArtisanSession!['phone'] ?? '').toString().trim();
      final targetIdentifier = username.isNotEmpty ? username : phone;

      currentArtisanSession!['profile_picture'] = pictureValue;
      if (onUpdated != null) onUpdated();

      final res = await ApiService.updateArtisanProfile(
        username: targetIdentifier,
        fullName: currentArtisanSession!['name'],
        phone: currentArtisanSession!['phone'],
        gender: currentArtisanSession!['gender'],
        craftType: currentArtisanSession!['craft_type'],
        location: currentArtisanSession!['location'],
        profilePicture: pictureValue,
      );

      if (res != null && res['status'] == 'success' && res['artisan'] != null) {
        currentArtisanSession = res['artisan'];
        if (onUpdated != null) onUpdated();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully! 📸')),
        );
      }
    }
  } catch (e) {
    debugPrint('Error saving profile picture: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update picture: $e')),
      );
    }
  }
}

Future<void> pickArtisanProfilePicture(BuildContext context, {VoidCallback? onUpdated}) async {
  try {
    String? b64Data;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 75);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      b64Data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res != null && res.files.isNotEmpty && res.files.first.bytes != null) {
        b64Data = 'data:image/jpeg;base64,${base64Encode(res.files.first.bytes!)}';
      }
    }

    if (b64Data != null) {
      await saveArtisanProfilePicture(context, b64Data, onUpdated: onUpdated);
    }
  } catch (e) {
    debugPrint('Error picking profile picture: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick picture: $e')),
      );
    }
  }
}

Future<void> showProfileAvatarPickerModal(BuildContext context, {VoidCallback? onUpdated}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Set Profile Picture 📸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.wine)),
              IconButton(icon: const Icon(Icons.close, color: AppColors.muted), onPressed: () => Navigator.pop(modalCtx)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          const Text('Choose from 5 Default Artisan Icons:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.wine)),
          const SizedBox(height: 14),

          // 5 Default Avatar Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: defaultAvatarPresets.entries.map((entry) {
              final key = entry.key;
              final val = entry.value;
              final color = val['color'] as Color;
              final icon = val['icon'] as IconData;
              final name = val['name'] as String;
              final isSelected = (currentArtisanSession?['profile_picture'] ?? '') == key;

              return GestureDetector(
                onTap: () async {
                  Navigator.pop(modalCtx);
                  await saveArtisanProfilePicture(context, key, onUpdated: onUpdated);
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: color,
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 60,
                      child: Text(
                        name.split(' ').first,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.wine : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Upload Custom Photo Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(modalCtx);
                await pickArtisanProfilePicture(context, onUpdated: onUpdated);
              },
              icon: const Icon(Icons.photo_library_outlined, color: AppColors.wine),
              label: const Text('Upload Photo from Device / Gallery 📁', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.wine, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}


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
              text: 'Get Started',
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  bool obscurePassword = true;
  bool loading = false;
  bool isBuyerPortal = false; // Toggle between Artisan and Buyer Login

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      if (isBuyerPortal) {
        final res = await ApiService.loginBuyer(username, password);
        if (!mounted) return;
        if (res != null && res['status'] == 'success' && res['buyer'] != null) {
          currentBuyerSession = res['buyer'];
          final orgName = res['buyer']?['organization_name'] ?? 'Buyer';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, $orgName! 🏛️')),
          );
          rootNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => BuyerHomeScreen(
                buyerSession: currentBuyerSession,
                onSwitchToArtisan: switchToArtisan,
                onLogout: logoutBuyer,
              ),
            ),
            (route) => false,
          );
        } else {
          final detail = res?['detail'] ?? 'Invalid buyer username or password.';
          passwordCtrl.clear();
          passwordFocusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(detail), backgroundColor: Colors.red.shade800),
          );
        }
      } else {
        final res = await ApiService.loginArtisan(username, password);
        if (!mounted) return;

        if (res != null && res['status'] == 'success') {
          currentArtisanSession = res['artisan'];
          final artisanName = res['artisan']?['name'] ?? 'Artisan';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, $artisanName! 🎉')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          final detail = res?['detail'] ?? 'Invalid username or password. Please check your credentials.';
          passwordCtrl.clear();
          passwordFocusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(detail),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.deepWine,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: logo(width: 190),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Persona Switcher Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isBuyerPortal = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !isBuyerPortal ? AppColors.wine : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '👨‍🎨 Artisan Portal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isBuyerPortal ? Colors.white : AppColors.muted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isBuyerPortal = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isBuyerPortal ? AppColors.wine : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🏛️ Buyer Portal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isBuyerPortal ? Colors.white : AppColors.muted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      isBuyerPortal ? 'B2B Buyer Sign In' : 'Welcome to Hastakala',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.wine),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBuyerPortal
                          ? 'Source authentic handcrafted products directly from rural artisans'
                          : 'Sign in to your artisan business manager account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: usernameCtrl,
                      focusNode: usernameFocusNode,
                      enabled: !loading,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => passwordFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outlined, color: AppColors.wine),
                        labelText: 'Username or Phone',
                        hintText: 'Enter username or phone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      key: ValueKey('artisan_login_pass_${obscurePassword}'),
                      controller: passwordCtrl,
                      focusNode: passwordFocusNode,
                      enabled: !loading,
                      obscureText: obscurePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => loading ? null : _handleLogin(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.wine),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (passwordCtrl.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.cancel, color: AppColors.muted, size: 18),
                                onPressed: () => setState(() => passwordCtrl.clear()),
                              ),
                            IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
                              onPressed: () {
                                setState(() => obscurePassword = !obscurePassword);
                                passwordCtrl.selection = TextSelection.fromPosition(TextPosition(offset: passwordCtrl.text.length));
                                passwordFocusNode.requestFocus();
                              },
                            ),
                          ],
                        ),
                        labelText: 'Password',
                        hintText: 'Enter password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wine,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isBuyerPortal ? 'Sign In as Buyer 🏛️' : 'Sign In as Artisan 🚀', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isBuyerPortal) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New business buyer? ", style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerAuthPage(
                                    initialRegister: true,
                                    onBuyerLoggedIn: (s) {
                                      currentBuyerSession = s;
                                      rootNavigatorKey.currentState?.pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) => BuyerHomeScreen(
                                            buyerSession: currentBuyerSession,
                                            onSwitchToArtisan: switchToArtisan,
                                            onLogout: logoutBuyer,
                                          ),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    onSwitchToArtisan: () => setState(() => isBuyerPortal = false),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Register Organization',
                              style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.wine),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          currentBuyerSession = {
                            'id': 0,
                            'organization_name': 'Guest Buyer Organization',
                            'contact_person': 'Guest Sourcing Manager',
                            'username': 'guest_buyer',
                            'buyer_type': 'Wholesale Buyer',
                            'location': 'India',
                          };
                          rootNavigatorKey.currentState?.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => BuyerHomeScreen(
                                buyerSession: currentBuyerSession,
                                onSwitchToArtisan: switchToArtisan,
                                onLogout: logoutBuyer,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.explore_outlined, color: AppColors.wine, size: 18),
                        label: const Text('Browse Marketplace as Guest Buyer 🛍️', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an artisan account? ", style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Create New Account',
                              style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          currentArtisanSession = {
                            'id': 0,
                            'name': 'Guest Artisan',
                            'username': 'guest',
                            'phone': 'N/A',
                            'gender': 'Artisan',
                            'craft_type': 'Handloom & Handicrafts',
                            'location': 'India',
                          };
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                        },
                        child: const Text('Continue as Guest Artisan', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  String selectedGender = 'Male';
  String selectedCraft = 'Handloom Weaving & Textiles';
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;

  @override
  void dispose() {
    fullNameCtrl.dispose();
    usernameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  final List<String> craftOptions = [
    'Handloom Weaving & Textiles',
    'Terracotta Pottery & Bio-Clay',
    'Bamboo & Cane Craft',
    'Wood Carving & Handicrafts',
    'Metal Dokra & Brassware',
    'Artisanal Footwear & Leather',
    'Heritage Crafts & Other',
  ];

  void _handleRegister() async {
    final fullName = fullNameCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (fullName.isEmpty || username.isEmpty || phone.isEmpty || address.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match! Please check password confirmation.')),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters long.')),
      );
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.registerArtisan(
      fullName: fullName,
      username: username,
      phone: phone,
      gender: selectedGender,
      craftType: selectedCraft,
      address: address,
      password: password,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res != null && res['status'] == 'success') {
      currentArtisanSession = res['artisan'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Welcome to Hastakala, $fullName! 🎉')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      final detail = res?['detail'] ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.deepWine,
    appBar: AppBar(
      backgroundColor: AppColors.deepWine,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('New Artisan Registration', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ),
    body: Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(child: logo(width: 140)),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Your Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  const Text('Join the global digital network of traditional Indian artisans', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 20),

                  const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: fullNameCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.wine),
                      hintText: 'e.g. Ramesh Kumar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Username *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.alternate_email, color: AppColors.wine),
                      hintText: 'e.g. ramesh_artisan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.wine),
                      hintText: 'e.g. 9876543210',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Gender *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((g) {
                      final isSelected = selectedGender == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(g == 'Male' ? '👨 Male' : (g == 'Female' ? '👩 Female' : '🧑 Other')),
                          selected: isSelected,
                          selectedColor: AppColors.wine,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.wine,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (bool sel) {
                            if (sel) setState(() => selectedGender = g);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  const Text('Craft Specialty / Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCraft,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.wine),
                        items: craftOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedCraft = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Address / Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.wine),
                      hintText: 'e.g. Varanasi, Uttar Pradesh',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Create Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    key: ValueKey('reg_pass_${obscurePassword}'),
                    controller: passwordCtrl,
                    focusNode: passwordFocusNode,
                    obscureText: obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => confirmPasswordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.wine),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                          passwordCtrl.selection = TextSelection.fromPosition(TextPosition(offset: passwordCtrl.text.length));
                          passwordFocusNode.requestFocus();
                        },
                      ),
                      hintText: '••••••••',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Confirm Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                  const SizedBox(height: 4),
                  TextField(
                    key: ValueKey('reg_confirm_pass_${obscureConfirmPassword}'),
                    controller: confirmPasswordCtrl,
                    focusNode: confirmPasswordFocusNode,
                    obscureText: obscureConfirmPassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => loading ? null : _handleRegister(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.wine),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
                        onPressed: () {
                          setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                          confirmPasswordCtrl.selection = TextSelection.fromPosition(TextPosition(offset: confirmPasswordCtrl.text.length));
                          confirmPasswordFocusNode.requestFocus();
                        },
                      ),
                      hintText: 'Re-enter password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Register Account ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
      const BuyersPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(index == 0 ? 'Artisan Business Hub 🎨' : index == 1 ? 'My Product Catalog' : index == 2 ? 'Add Craft' : index == 3 ? 'B2B Enquiries 📩' : 'Artisan Profile', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add Craft'),
          NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mark_email_read), label: 'Enquiries'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
  List<dynamic> dueOrders = [];
  List<dynamic> enquiries = [];
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
    final int? artisanId = currentArtisanSession?['id'] is int
        ? currentArtisanSession!['id'] as int
        : int.tryParse(currentArtisanSession?['id']?.toString() ?? '');
    final String? artisanUsername = currentArtisanSession?['username']?.toString();
    final orders = await ApiService.getDueOrders(artisanId: artisanId, artisanUsername: artisanUsername);
    final enquiryList = await ApiService.getEnquiries(artisanId: artisanId, artisanUsername: artisanUsername);
    if (mounted) {
      setState(() {
        backendConnected = connected;
        stats = data;
        dueOrders = orders;
        enquiries = enquiryList;
        loading = false;
      });
    }
  }

  void _showProfileModal(BuildContext context) {
    final artisanName = currentArtisanSession?['name'] ?? 'Guest Artisan';
    final username = currentArtisanSession?['username'] ?? 'guest';
    final phone = currentArtisanSession?['phone'] ?? 'N/A';
    final gender = currentArtisanSession?['gender'] ?? 'N/A';
    final craftType = currentArtisanSession?['craft_type'] ?? 'Handloom & Handicrafts';
    final location = currentArtisanSession?['location'] ?? 'India';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (stCtx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  buildArtisanAvatar(
                    radius: 28,
                    showEditBadge: true,
                    onTap: () async {
                      await showProfileAvatarPickerModal(context, onUpdated: () {
                        setModalState(() {});
                        setState(() {});
                      });
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentArtisanSession?['name'] ?? artisanName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.wine),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${currentArtisanSession?['username'] ?? username}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Artisan Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.wine)),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context, () {
                        setState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.wine),
                          SizedBox(width: 4),
                          Text('Edit Profile', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildProfileRow(Icons.badge_outlined, 'Full Name', currentArtisanSession?['name'] ?? artisanName),
              _buildProfileRow(Icons.alternate_email, 'Username', '@${currentArtisanSession?['username'] ?? username}'),
              _buildProfileRow(Icons.phone_outlined, 'Phone', currentArtisanSession?['phone'] ?? phone),
              _buildProfileRow(Icons.wc_outlined, 'Gender', currentArtisanSession?['gender'] ?? gender),
              _buildProfileRow(Icons.brush_outlined, 'Craft Specialty', currentArtisanSession?['craft_type'] ?? craftType),
              _buildProfileRow(Icons.location_on_outlined, 'Location', currentArtisanSession?['location'] ?? location),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditProfileModal(context, () {
                          setState(() {});
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          currentArtisanSession = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully.')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                      label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext parentContext, VoidCallback onSaved) {
    final fullNameCtrl = TextEditingController(text: currentArtisanSession?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: currentArtisanSession?['phone'] ?? '');
    final locationCtrl = TextEditingController(text: currentArtisanSession?['location'] ?? '');
    String currentGender = currentArtisanSession?['gender'] ?? 'Male';
    String currentCraft = currentArtisanSession?['craft_type'] ?? 'Handloom Weaving & Textiles';
    bool saving = false;

    final List<String> craftOptions = [
      'Handloom Weaving & Textiles',
      'Terracotta Pottery & Bio-Clay',
      'Bamboo & Cane Craft',
      'Wood Carving & Handicrafts',
      'Metal Dokra & Brassware',
      'Artisanal Footwear & Leather',
      'Master Weaver & Bamboo Craftsman',
      'Heritage Crafts & Other',
    ];

    if (!craftOptions.contains(currentCraft)) {
      craftOptions.add(currentCraft);
    }

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (stCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(stCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Artisan Profile ✏️',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.wine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => Navigator.pop(dlgCtx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Avatar with Camera Icon
                Center(
                  child: Column(
                    children: [
                      buildArtisanAvatar(
                        radius: 36,
                        showEditBadge: true,
                        onTap: () async {
                          await showProfileAvatarPickerModal(stCtx, onUpdated: () {
                            setModalState(() {});
                            setState(() {});
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () async {
                          await showProfileAvatarPickerModal(stCtx, onUpdated: () {
                            setModalState(() {});
                            setState(() {});
                          });
                        },
                        icon: const Icon(Icons.photo_camera, size: 16, color: AppColors.wine),
                        label: const Text('Change Profile Picture', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                const SizedBox(height: 4),
                TextField(
                  controller: fullNameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.wine),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.wine),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Gender *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                const SizedBox(height: 4),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final sel = currentGender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: sel,
                        selectedColor: AppColors.wine.withOpacity(0.15),
                        onSelected: (val) {
                          if (val) setModalState(() => currentGender = g);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Text('Craft Specialty / Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentCraft,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.wine),
                      items: craftOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => currentCraft = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Location / Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                const SizedBox(height: 4),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.wine),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final username = currentArtisanSession?['username'] ?? '';
                      if (username.isEmpty) return;

                      setModalState(() => saving = true);
                      final res = await ApiService.updateArtisanProfile(
                        username: username,
                        fullName: fullNameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        gender: currentGender,
                        craftType: currentCraft,
                        location: locationCtrl.text.trim(),
                      );
                      setModalState(() => saving = false);

                      if (res != null && res['status'] == 'success' && res['artisan'] != null) {
                        currentArtisanSession = res['artisan'];
                      } else {
                        currentArtisanSession!['name'] = fullNameCtrl.text.trim();
                        currentArtisanSession!['phone'] = phoneCtrl.text.trim();
                        currentArtisanSession!['gender'] = currentGender;
                        currentArtisanSession!['craft_type'] = currentCraft;
                        currentArtisanSession!['location'] = locationCtrl.text.trim();
                      }

                      if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                      onSaved();
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Profile details updated successfully! ✨')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.wine),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEnquiries = enquiries.where((e) {
      final st = (e['status'] ?? '').toString().toLowerCase();
      return st != 'completed' && st != 'rejected';
    }).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              buildArtisanAvatar(
                radius: 22,
                showEditBadge: true,
                onTap: () => _showProfileModal(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showProfileModal(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, ${(currentArtisanSession?['name'] ?? 'Artisan').split(' ').first}! 🙏',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, color: AppColors.wine, size: 26),
                tooltip: 'Profile Details',
                onPressed: () => _showProfileModal(context),
              ),
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
                icon: Icons.handshake_outlined, label: 'Find\nBuyers', color: const Color(0xFFFFEDC8),
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
                icon: Icons.person_outline, label: 'My\nProfile', color: const Color(0xFFE6DEFF),
                onTap: () => widget.onNavigateTab?.call(4),
              )),
            ]),
            const SizedBox(height: 24),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Enquiries 📩', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.wine)),
              if (activeEnquiries.isNotEmpty)
                GestureDetector(
                  onTap: () => widget.onNavigateTab?.call(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeEnquiries.length} Active Lead${activeEnquiries.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeEnquiries.isNotEmpty) ...[
            ...activeEnquiries.take(3).map((enq) {
              final status = enq['status'] ?? 'New Lead';
              final qty = enq['order_quantity'] ?? 50;
              final price = enq['offer_price']?.toInt() ?? 450;
              final totalVal = qty * price;
              final prodTitle = enq['product_title'] ?? 'Artisan Craft';
              final businessName = enq['business_name'] ?? enq['buyer_name'] ?? 'Wholesale Buyer';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFECE3DD)),
                ),
                elevation: 0,
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onNavigateTab?.call(3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.handshake_outlined, color: AppColors.wine, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  businessName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.wine),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enquiry for $qty pcs of $prodTitle',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📍 ${enq['buyer_location'] ?? 'India'} • ${enq['buyer_type'] ?? 'Buyer'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            Text(
                              'Total: ₹$totalVal',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E4CF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5D5C1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E4CF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/artisan_art.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Image.network(
                        ApiService.getFullImageUrl('/uploads/artisan_art.jpg'),
                        fit: BoxFit.contain,
                        errorBuilder: (c2, e2, s2) => Container(
                          color: const Color(0xFFF3E4CF),
                          child: const Icon(Icons.handyman_outlined, size: 60, color: AppColors.wine),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'You Have No Pending Enquiries Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.wine),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Once B2B buyers send enquiries for your handcrafted products, your direct buyer leads will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
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
  String detectedLanguage = '';
  String translatedEnglishText = '';
  bool isTranslating = false;

  Uint8List? selectedImageBytes;
  String? originalFileName;
  Map<String, dynamic>? enhancedImageResult;
  Map<String, dynamic>? generatedCatalogResult;
  Map<String, dynamic>? pricingData;

  // PhotoRoom API Background Customizer State
  String selectedBgStyle = 'white';
  final TextEditingController customBgPromptCtrl = TextEditingController();

  // Persistent Controllers across all phases
  final TextEditingController voiceTextController = TextEditingController();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController artTypeCtrl = TextEditingController();
  final TextEditingController descEnCtrl = TextEditingController();
  final TextEditingController descHiCtrl = TextEditingController();
  final TextEditingController catCtrl = TextEditingController();
  final TextEditingController matCtrl = TextEditingController();
  final TextEditingController tagsCtrl = TextEditingController();

  // Minimum Order Quantity (MOQ) & Volume Wholesale Tiers
  int moq = 50;
  late final TextEditingController moqCtrl;
  List<Map<String, dynamic>> bulkTiers = [];

  bool get isAnyProcessRunning =>
      processing || publishing || isListening || isTranslating || calculatingPricing || _isTranslatingField;

  // Dynamic Pricing Sliders State
  double materialCost = 450.0;
  double laborHours = 12.0;
  double laborRate = 100.0;

  Timer? _enTranslationDebounce;
  Timer? _regionalTranslationDebounce;
  bool _isTranslatingField = false;

  static const Map<String, Map<String, String>> _langInfoMap = {
    'hi': {'name': 'Hindi (हिंदी)', 'code': 'hi', 'label': 'Hindi Description (हिंदी विवरण)'},
    'hi-in': {'name': 'Hindi (हिंदी)', 'code': 'hi', 'label': 'Hindi Description (हिंदी विवरण)'},
    'hindi': {'name': 'Hindi (हिंदी)', 'code': 'hi', 'label': 'Hindi Description (हिंदी विवरण)'},
    'bn': {'name': 'Bengali (বাংলা)', 'code': 'bn', 'label': 'Bengali Description (বাংলা विवरण)'},
    'bn-in': {'name': 'Bengali (বাংলা)', 'code': 'bn', 'label': 'Bengali Description (বাংলা विवरण)'},
    'bengali': {'name': 'Bengali (বাংলা)', 'code': 'bn', 'label': 'Bengali Description (বাংলা विवरण)'},
    'gu': {'name': 'Gujarati (ગુજરાતી)', 'code': 'gu', 'label': 'Gujarati Description (ગુજરાતી વિવરણ)'},
    'gu-in': {'name': 'Gujarati (ગુજરાતી)', 'code': 'gu', 'label': 'Gujarati Description (ગુજરાતી વિવરણ)'},
    'gujarati': {'name': 'Gujarati (ગુજરાતી)', 'code': 'gu', 'label': 'Gujarati Description (ગુજરાતી વિવરણ)'},
    'mr': {'name': 'Marathi (मराठी)', 'code': 'mr', 'label': 'Marathi Description (मराठी विवरण)'},
    'mr-in': {'name': 'Marathi (मराठी)', 'code': 'mr', 'label': 'Marathi Description (मराठी विवरण)'},
    'marathi': {'name': 'Marathi (मराठी)', 'code': 'mr', 'label': 'Marathi Description (मराठी विवरण)'},
    'ta': {'name': 'Tamil (தமிழ்)', 'code': 'ta', 'label': 'Tamil Description (தமிழ் விவரம்)'},
    'ta-in': {'name': 'Tamil (தமிழ்)', 'code': 'ta', 'label': 'Tamil Description (தமிழ் விவரம்)'},
    'tamil': {'name': 'Tamil (தமிழ்)', 'code': 'ta', 'label': 'Tamil Description (தமிழ் விவரம்)'},
    'te': {'name': 'Telugu (తెలుగు)', 'code': 'te', 'label': 'Telugu Description (తెలుగు వివరణ)'},
    'te-in': {'name': 'Telugu (తెలుగు)', 'code': 'te', 'label': 'Telugu Description (తెలుగు వివరణ)'},
    'telugu': {'name': 'Telugu (తెలుగు)', 'code': 'te', 'label': 'Telugu Description (తెలుగు వివరణ)'},
    'kn': {'name': 'Kannada (ಕನ್ನಡ)', 'code': 'kn', 'label': 'Kannada Description (ಕನ್ನಡ ವಿವರಣೆ)'},
    'kn-in': {'name': 'Kannada (ಕನ್ನಡ)', 'code': 'kn', 'label': 'Kannada Description (ಕನ್ನಡ ವಿವರಣೆ)'},
    'kannada': {'name': 'Kannada (ಕನ್ನಡ)', 'code': 'kn', 'label': 'Kannada Description (ಕನ್ನಡ ವಿವರಣೆ)'},
    'ml': {'name': 'Malayalam (മലയാളം)', 'code': 'ml', 'label': 'Malayalam Description (മലയാളം വിവരണം)'},
    'ml-in': {'name': 'Malayalam (മലയാളം)', 'code': 'ml', 'label': 'Malayalam Description (മലയാളം വിവരണം)'},
    'malayalam': {'name': 'Malayalam (മലയാളം)', 'code': 'ml', 'label': 'Malayalam Description (മലയാളം വിവരണം)'},
    'pa': {'name': 'Punjabi (ਪੰਜਾਬੀ)', 'code': 'pa', 'label': 'Punjabi Description (ਪੰਜਾਬੀ ਵੇਰਵਾ)'},
    'pa-in': {'name': 'Punjabi (ਪੰਜਾਬੀ)', 'code': 'pa', 'label': 'Punjabi Description (ਪੰਜਾਬੀ ਵੇਰਵਾ)'},
    'punjabi': {'name': 'Punjabi (ਪੰਜਾਬੀ)', 'code': 'pa', 'label': 'Punjabi Description (ਪੰਜਾਬੀ ਵੇਰਵਾ)'},
  };

  Map<String, String> _getActiveLanguageDetails() {
    String searchStr = '';
    if (selectedLanguage != 'Auto-Detect') {
      searchStr = selectedLanguage.toLowerCase().trim();
    } else if (detectedLanguage.isNotEmpty) {
      searchStr = detectedLanguage.toLowerCase().trim();
    }

    if (searchStr.isNotEmpty) {
      for (final entry in _langInfoMap.entries) {
        if (searchStr.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return const {'name': 'Hindi (हिंदी)', 'code': 'hi', 'label': 'Hindi Description (हिंदी विवरण)'};
  }

  Future<void> _translateEnToRegional() async {
    if (_isTranslatingField) return;
    final text = descEnCtrl.text.trim();
    if (text.isEmpty) return;

    final langDetails = _getActiveLanguageDetails();
    final targetCode = langDetails['code'] ?? 'hi';

    setState(() => _isTranslatingField = true);
    final res = await ApiService.translateText(text, sourceLang: 'en', targetLang: targetCode);
    if (mounted) {
      if (res != null && res['translated_text'] != null && res['translated_text'].toString().isNotEmpty) {
        descHiCtrl.text = res['translated_text'];
      }
      setState(() => _isTranslatingField = false);
    }
  }

  Future<void> _translateRegionalToEn() async {
    if (_isTranslatingField) return;
    final text = descHiCtrl.text.trim();
    if (text.isEmpty) return;

    final langDetails = _getActiveLanguageDetails();
    final sourceCode = langDetails['code'] ?? 'auto';

    setState(() => _isTranslatingField = true);
    final res = await ApiService.translateText(text, sourceLang: sourceCode, targetLang: 'en');
    if (mounted) {
      if (res != null && res['translated_text'] != null && res['translated_text'].toString().isNotEmpty) {
        descEnCtrl.text = res['translated_text'];
      }
      setState(() => _isTranslatingField = false);
    }
  }

  void _onEnChanged(String val) {
    if (_isTranslatingField) return;
    _enTranslationDebounce?.cancel();
    _enTranslationDebounce = Timer(const Duration(milliseconds: 1000), () {
      _translateEnToRegional();
    });
  }

  void _onRegionalChanged(String val) {
    if (_isTranslatingField) return;
    _regionalTranslationDebounce?.cancel();
    _regionalTranslationDebounce = Timer(const Duration(milliseconds: 1000), () {
      _translateRegionalToEn();
    });
  }

  @override
  void dispose() {
    moqCtrl.dispose();
    _enTranslationDebounce?.cancel();
    _regionalTranslationDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    moqCtrl = TextEditingController(text: '50');
    _fetchPricing();
    _translateCurrentText();
  }

  void _initBulkTiers({bool force = false}) {
    if (!force && bulkTiers.isNotEmpty) return;

    final wholesale = (pricingData?['price_wholesale'] as num?)?.toDouble() ?? 750.0;
    final minPrice = (pricingData?['min_price'] as num?)?.toDouble() ?? (wholesale * 0.85);

    final tier1Price = wholesale;
    final tier2Price = ((wholesale * 0.92) < minPrice) ? minPrice : (wholesale * 0.92);
    final tier3Price = ((wholesale * 0.85) < minPrice) ? minPrice : (wholesale * 0.85);

    final tier1End = moq < 50 ? 49 : (moq + 49);
    final tier2Start = tier1End + 1;
    final tier2End = tier2Start + 150;
    final tier3Start = tier2End + 1;

    bulkTiers = [
      {
        'tier': 'Tier 1 (Base MOQ)',
        'range': '$moq–$tier1End pieces',
        'min_qty': moq,
        'max_qty': tier1End,
        'price': tier1Price.roundToDouble(),
        'discount': 'Base Wholesale Rate',
      },
      {
        'tier': 'Tier 2 (Volume Bulk)',
        'range': '$tier2Start–$tier2End pieces',
        'min_qty': tier2Start,
        'max_qty': tier2End,
        'price': tier2Price.roundToDouble(),
        'discount': '8% Volume Discount',
      },
      {
        'tier': 'Tier 3 (Mega Order)',
        'range': '$tier3Start+ pieces',
        'min_qty': tier3Start,
        'max_qty': null,
        'price': tier3Price.roundToDouble(),
        'discount': '15% Mega Discount',
      },
    ];
  }

  void _setMoq(int newMoq) {
    if (newMoq < 1) return;
    setState(() {
      moq = newMoq;
      moqCtrl.text = moq.toString();
      _initBulkTiers(force: true);
    });
  }

  void _showAddTierDialog() {
    final rangeCtrl = TextEditingController(text: '${moq * 5}+ pieces');
    final priceCtrl = TextEditingController(
      text: ((pricingData?['min_price'] as num?)?.toInt() ?? 500).toString(),
    );
    final discountCtrl = TextEditingController(text: 'Custom Volume Rate');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Quantity Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.wine)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rangeCtrl,
              decoration: const InputDecoration(labelText: 'Quantity Range', hintText: 'e.g. 250–499 pieces'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wholesale Unit Price (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountCtrl,
              decoration: const InputDecoration(labelText: 'Discount Label', hintText: 'e.g. 12% Bulk Offer'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wine, foregroundColor: Colors.white),
            onPressed: () {
              final p = double.tryParse(priceCtrl.text) ?? 500.0;
              setState(() {
                bulkTiers.add({
                  'tier': 'Tier ${bulkTiers.length + 1}',
                  'range': rangeCtrl.text.isNotEmpty ? rangeCtrl.text : 'Bulk Tier',
                  'min_qty': moq,
                  'max_qty': null,
                  'price': p,
                  'discount': discountCtrl.text.isNotEmpty ? discountCtrl.text : 'Volume Rate',
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Tier'),
          ),
        ],
      ),
    );
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
        _initBulkTiers();
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
    final regDesc = catalog['description_regional'] ?? catalog['description_hi'];
    if (regDesc != null && regDesc.toString().isNotEmpty) {
      descHiCtrl.text = regDesc.toString();
    }
    if (catalog['type_of_art'] != null && catalog['type_of_art'].toString().isNotEmpty) {
      artTypeCtrl.text = catalog['type_of_art'];
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
    if (processing && step == 1) {
      return AIProcessingPage(
        onComplete: () {
          setState(() {
            processing = false;
            step = 2; // Jump to Review Phase after voice catalog generation
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
        final bool canTap = !isAnyProcessRunning && (
          i == 0 ||
          (i == 1 && selectedImageBytes != null) ||
          (i == 2 && selectedImageBytes != null && generatedCatalogResult != null) ||
          (i == 3 && selectedImageBytes != null && generatedCatalogResult != null)
        );

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canTap ? () => setState(() => step = i) : null,
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

    // Strict process checking: until any process is finished, Next is disabled!
    bool isNextEnabled = false;
    String nextButtonLabel = '';
    Widget nextButtonIcon = const Icon(Icons.arrow_forward, size: 18);

    if (step == 0) {
      if (processing) {
        isNextEnabled = false;
        nextButtonLabel = 'Enhancing Photo...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else if (selectedImageBytes == null) {
        isNextEnabled = false;
        nextButtonLabel = 'Select Photo First';
        nextButtonIcon = const Icon(Icons.add_a_photo_outlined, size: 18);
      } else {
        isNextEnabled = true;
        nextButtonLabel = 'Next: Voice →';
        nextButtonIcon = const Icon(Icons.arrow_forward, size: 18);
      }
    } else if (step == 1) {
      if (processing) {
        isNextEnabled = false;
        nextButtonLabel = 'Generating AI Catalog...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else if (isListening) {
        isNextEnabled = false;
        nextButtonLabel = 'Recording Microphone...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else if (isTranslating) {
        isNextEnabled = false;
        nextButtonLabel = 'Translating...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else {
        isNextEnabled = true;
        nextButtonLabel = 'Next: Review →';
        nextButtonIcon = const Icon(Icons.arrow_forward, size: 18);
      }
    } else if (step == 2) {
      if (_isTranslatingField) {
        isNextEnabled = false;
        nextButtonLabel = 'Translating Description...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else if (titleCtrl.text.trim().isEmpty) {
        isNextEnabled = false;
        nextButtonLabel = 'Enter Product Name';
        nextButtonIcon = const Icon(Icons.edit, size: 18);
      } else {
        isNextEnabled = !isAnyProcessRunning;
        nextButtonLabel = 'Next: Pricing →';
        nextButtonIcon = const Icon(Icons.arrow_forward, size: 18);
      }
    } else if (step == 3) {
      if (calculatingPricing) {
        isNextEnabled = false;
        nextButtonLabel = 'Calculating Pricing...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else if (publishing) {
        isNextEnabled = false;
        nextButtonLabel = 'Publishing Product...';
        nextButtonIcon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      } else {
        isNextEnabled = !isAnyProcessRunning;
        nextButtonLabel = 'Publish Product 🚀';
        nextButtonIcon = const Icon(Icons.rocket_launch_outlined, size: 18);
      }
    }

    return Row(
      children: [
        if (step > 0) ...[
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isAnyProcessRunning ? null : () {
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
              onPressed: isNextEnabled ? _onNextPressed : null,
              icon: nextButtonIcon,
              label: Text(
                nextButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                disabledBackgroundColor: AppColors.wine.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateCatalog() async {
    final text = voiceTextController.text.trim();
    if (text.isEmpty && selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product photo or record your voice description.')),
      );
      return;
    }

    setState(() => processing = true);
    final imgUrl = enhancedImageResult?['enhanced_image_url'] ?? enhancedImageResult?['raw_image_url'] ?? '';
    final String b64 = (selectedImageBytes != null) ? base64Encode(selectedImageBytes!) : '';

    final catalog = await ApiService.generateCatalog(
      text,
      language: selectedLanguage,
      imageUrl: imgUrl,
      imageBase64: b64,
    );

    if (mounted) {
      if (catalog != null) {
        _syncCatalogToControllers(catalog);
        generatedCatalogResult = catalog;
        setState(() {
          processing = false;
          step = 2; // Jump to Review Step
        });
        final artType = catalog['type_of_art'] ?? 'Artisan Craft';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Catalog Generated! ($artType) ✨'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach AI cataloger. You can edit details manually in Review.')),
        );
      }
    }
  }

  void _onNextPressed() async {
    if (isAnyProcessRunning) return;

    if (step == 0) {
      if (selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or capture a product photo first.')),
        );
        return;
      }
      setState(() => step = 1);
    } else if (step == 1) {
      if (generatedCatalogResult == null) {
        await _generateCatalog();
      } else {
        setState(() => step = 2);
      }
    } else if (step == 2) {
      if (titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a product title before continuing to pricing.')),
        );
        return;
      }
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

    final int? artisanId = currentArtisanSession?['id'] is int
        ? currentArtisanSession!['id'] as int
        : int.tryParse(currentArtisanSession?['id']?.toString() ?? '');
    final String? artisanUsername = currentArtisanSession?['username']?.toString();

    final String fallbackB64 = (selectedImageBytes != null && selectedImageBytes!.isNotEmpty)
        ? 'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}'
        : '';
    final String rawImgUri = (enhancedImageResult?['raw_image_url'] ?? '').toString().isNotEmpty
        ? enhancedImageResult!['raw_image_url']
        : fallbackB64;
    final String enhancedImgUri = (enhancedImageResult?['enhanced_image_url'] ?? '').toString().isNotEmpty
        ? enhancedImageResult!['enhanced_image_url']
        : rawImgUri;

    final success = await ApiService.publishProduct({
      'title': titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Handcrafted Artisan Product',
      'type_of_art': artTypeCtrl.text.isNotEmpty ? artTypeCtrl.text : 'Traditional Indian Craft',
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
      'moq': moq,
      'bulk_pricing': bulkTiers,
      'available_qty': 500,
      'bulk_available': 1,
      'custom_size': 1,
      'custom_design': 1,
      'custom_packaging': 1,
      'monthly_capacity': 1000,
      'production_time': '${(laborHours / 8).ceil()}–${(laborHours / 8).ceil() + 2} days',
      'artisan_name': currentArtisanSession?['name'] ?? 'Ramesh Kumar',
      'artisan_location': currentArtisanSession?['location'] ?? 'West Bengal',
      'raw_image_url': rawImgUri,
      'enhanced_image_url': enhancedImgUri,
      if (artisanId != null) 'artisan_id': artisanId,
      if (artisanUsername != null) 'artisan_username': artisanUsername,
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

  static const Map<String, Map<String, String>> _bgStyles = {
    'transparent': {'label': 'Remove BG (Cutout)', 'icon': '✂️', 'desc': 'PhotoRoom Sandbox Cutout'},
    'white': {'label': 'Clean White', 'icon': '⚪', 'desc': 'Pure studio white background'},
    'wood': {'label': 'Rustic Wood', 'icon': '🪵', 'desc': 'Warm wooden table setup'},
    'marble': {'label': 'Luxury Marble', 'icon': '🏛️', 'desc': 'Elegant marble showcase'},
    'heritage': {'label': 'Heritage Art', 'icon': '🪔', 'desc': 'Traditional Indian craft setting'},
    'silk': {'label': 'Royal Silk', 'icon': '🧵', 'desc': 'Textured rich silk fabric'},
    'minimalist': {'label': 'Minimal Beige', 'icon': '🎨', 'desc': 'Neutral aesthetic backdrop'},
    'custom': {'label': 'Custom AI', 'icon': '✨', 'desc': 'Custom text prompt for PhotoRoom AI'},
  };

  Widget _photoStep() {
    final hasSelectedPhoto = selectedImageBytes != null;
    final String studioImgUrl = (enhancedImageResult?['enhanced_image_url'] ?? '').toString().isNotEmpty
        ? enhancedImageResult!['enhanced_image_url']
        : (selectedImageBytes != null ? 'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}' : '');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. AI Image Studio & Background Remover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Powered by PhotoRoom Sandbox API. Select Remove BG (Cutout) or an e-commerce theme to isolate and enhance your product.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),

          const Text('Select PhotoRoom Studio Background:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.wine)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bgStyles.entries.map((entry) {
              final key = entry.key;
              final info = entry.value;
              final isSelected = selectedBgStyle == key;
              return ChoiceChip(
                label: Text('${info['icon']} ${info['label']}'),
                selected: isSelected,
                selectedColor: AppColors.wine,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.wine,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? AppColors.wine : const Color(0xFFE2D8D1)),
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      selectedBgStyle = key;
                    });
                    if (selectedImageBytes != null) {
                      _reEnhanceWithPhotoRoom();
                    }
                  }
                },
              );
            }).toList(),
          ),

          if (selectedBgStyle == 'custom') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customBgPromptCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. natural bamboo mat on sunny studio table',
                      labelText: 'Custom PhotoRoom Background Prompt',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: selectedImageBytes != null ? _reEnhanceWithPhotoRoom : null,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECE9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2D8D1)),
            ),
            child: hasSelectedPhoto
                ? Column(
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
                                        child: Image.memory(selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('PhotoRoom Studio ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                                        if (processing) ...[
                                          const SizedBox(width: 6),
                                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wine)),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ApiService.buildProductImage(
                                          studioImgUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.green, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Theme: ${_bgStyles[selectedBgStyle]?['label'] ?? 'Studio'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _pickAndEnhanceImage(ImageSource.gallery),
                                  icon: const Icon(Icons.refresh, size: 16, color: AppColors.wine),
                                  label: const Text('Change Photo', style: TextStyle(fontSize: 12, color: AppColors.wine)),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  onPressed: _reEnhanceWithPhotoRoom,
                                  icon: const Icon(Icons.auto_awesome, size: 14),
                                  label: const Text('Re-Enhance', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.wine,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
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
                      const SizedBox(height: 6),
                      const Text('PhotoRoom API will isolate product and generate AI background', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Future<void> _reEnhanceWithPhotoRoom() async {
    if (selectedImageBytes == null) return;
    final rawB64 = 'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}';
    setState(() {
      processing = true;
      generatedCatalogResult = null;
    });
    final result = await ApiService.enhanceImage(
      selectedImageBytes!,
      originalFileName ?? 'product.jpg',
      bgStyle: selectedBgStyle,
      bgPrompt: customBgPromptCtrl.text,
    );
    if (mounted) {
      setState(() {
        if (result != null && (result['enhanced_image_url'] ?? '').toString().isNotEmpty) {
          enhancedImageResult = result;
        } else if (enhancedImageResult == null) {
          enhancedImageResult = {
            'raw_image_url': rawB64,
            'enhanced_image_url': rawB64,
            'status': 'Original Preserved',
          };
        }
        processing = false;
      });
    }
  }

  Future<void> _pickAndEnhanceImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final rawB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          selectedImageBytes = bytes;
          originalFileName = picked.name;
          generatedCatalogResult = null;
          enhancedImageResult = {
            'raw_image_url': rawB64,
            'enhanced_image_url': rawB64,
            'status': 'Enhancing...',
          };
          processing = true;
        });

        final result = await ApiService.enhanceImage(
          bytes,
          picked.name,
          bgStyle: selectedBgStyle,
          bgPrompt: customBgPromptCtrl.text,
        );

        if (mounted) {
          setState(() {
            if (result != null && (result['enhanced_image_url'] ?? '').toString().isNotEmpty) {
              enhancedImageResult = result;
            } else {
              enhancedImageResult = {
                'raw_image_url': rawB64,
                'enhanced_image_url': rawB64,
                'status': 'Original Preserved',
              };
            }
            processing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image selection notice: $e')));
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
        const Text('2. Multilingual Voice & Multimodal Cataloger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Speak into your microphone or type details in any regional language.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),

        // Photo Attachment Status for Multimodal Input
        if (selectedImageBytes != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2D8D1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(selectedImageBytes!, width: 44, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Photo Attached (Vision Input)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine)),
                      Text(
                        enhancedImageResult != null ? 'Enhanced Studio Cutout ready for AI analysis' : 'Photo ready for AI analysis',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.green, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
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
                  DropdownMenuItem(value: 'Auto-Detect', child: Text('🌐 Choose your language')),
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
          onChanged: (_) {
            generatedCatalogResult = null;
            _translateCurrentText();
          },
          decoration: InputDecoration(
            labelText: 'Spoken Description / Transcript',
            hintText: 'Speak using mic or type craft details...',
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

        const SizedBox(height: 14),

        // Generate AI Catalog CTA Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: isAnyProcessRunning ? null : _generateCatalog,
            icon: processing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(
              processing ? 'Analyzing Product & Craft Details...' : 'Generate AI Catalog ✨',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.wine,
              disabledBackgroundColor: AppColors.wine.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),

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
          const SizedBox(height: 16),

          if (enhancedImageResult != null)
            Container(
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gold)),
              child: ApiService.buildProductImage(
                enhancedImageResult!['enhanced_image_url'],
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          _editableField('Product Name', titleCtrl, hintText: 'e.g. Handcrafted Ceramic Teacup'),
          _editableField('Type of Art / Craft Heritage', artTypeCtrl, hintText: 'e.g. Terracotta Pottery, Handloom Weaving'),
          _editableField('Category', catCtrl, hintText: 'e.g. Pottery & Clay, Handloom & Textiles'),
          _editableField('English Description (SEO)', descEnCtrl, maxLines: 4, onChanged: _onEnChanged, hintText: 'Detailed e-commerce product description in English'),
          _editableField('Regional Description', descHiCtrl, maxLines: 3, onChanged: _onRegionalChanged, hintText: 'विवरण / Regional description'),
          _editableField('Materials', matCtrl, hintText: 'e.g. Natural Bio-Clay, Organic Cotton'),
          _editableField('Tags', tagsCtrl, hintText: 'e.g. Handmade • Artisanal • Sustainable'),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController controller, {int maxLines = 1, ValueChanged<String>? onChanged, String? hintText}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB5A9A0), fontSize: 13),
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

          // Minimum Order Quantity (MOQ) Setting Card
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.inventory_2_outlined, color: AppColors.wine, size: 20),
                      SizedBox(width: 8),
                      Text('Minimum Order Quantity (MOQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.wine)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The lowest number of pieces a wholesale buyer can order in a single B2B enquiry.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          if (moq > 5) _setMoq(moq - 5);
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: moqCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.wine),
                          decoration: InputDecoration(
                            suffixText: 'pieces',
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              _setMoq(parsed);
                            } else {
                              moqCtrl.text = moq.toString();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.wine),
                        onPressed: () => _setMoq(moq + 5),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [10, 25, 50, 100, 200, 500].map((preset) {
                      final isSelected = moq == preset;
                      return ChoiceChip(
                        label: Text('$preset pcs'),
                        selected: isSelected,
                        selectedColor: AppColors.wine,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.wine,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                        onSelected: (selected) {
                          if (selected) _setMoq(preset);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Tiered Wholesale Pricing for Different Quantities Card
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.layers_outlined, color: AppColors.wine, size: 20),
                          SizedBox(width: 8),
                          Text('Wholesale Price by Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.wine)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _initBulkTiers(force: true),
                        icon: const Icon(Icons.refresh, size: 14, color: AppColors.green),
                        label: const Text('Reset AI Tiers', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set volume discounts for different order brackets. Buyers who order more units get better rates.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Tiers List
                  if (bulkTiers.isEmpty) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _initBulkTiers(force: true),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Recommended Wholesale Tiers'),
                      ),
                    ),
                  ] else ...[
                    ...List.generate(bulkTiers.length, (idx) {
                      final tier = bulkTiers[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF8F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEADBCE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.wine.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tier['tier'] ?? 'Tier ${idx + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.wine),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tier['discount'] ?? 'Volume Discount',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.green),
                                      ),
                                    ),
                                  ],
                                ),
                                if (bulkTiers.length > 1)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        bulkTiers.removeAt(idx);
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Quantity Range', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFE2D8D1)),
                                        ),
                                        child: Text(
                                          tier['range'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Wholesale Unit Price', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        key: ValueKey('tier_${idx}_${tier['price']}'),
                                        initialValue: (tier['price'] as num?)?.toInt().toString() ?? '500',
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.wine),
                                        decoration: InputDecoration(
                                          prefixText: '₹ ',
                                          suffixText: '/ pc',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          fillColor: Colors.white,
                                          filled: true,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onChanged: (newPrice) {
                                          final p = double.tryParse(newPrice);
                                          if (p != null) {
                                            tier['price'] = p;
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAddTierDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.wine),
                        label: const Text('Add Custom Wholesale Quantity Tier', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.wine),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
        AppButton(
          text: 'Return to Home Page 🏠',
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (r) => false,
          ),
        ),
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
    final int? artisanId = currentArtisanSession?['id'] is int
        ? currentArtisanSession!['id'] as int
        : int.tryParse(currentArtisanSession?['id']?.toString() ?? '');
    final String? artisanUsername = currentArtisanSession?['username']?.toString();

    final list = await ApiService.getProducts(
      artisanId: artisanId,
      artisanUsername: artisanUsername,
    );
    if (mounted) {
      setState(() {
        products = list;
        loading = false;
      });
    }
  }

  void _showProductDetailModal(BuildContext parentCtx, Map<String, dynamic> p) {
    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if ((p['enhanced_image_url'] ?? p['raw_image_url'] ?? '').toString().isNotEmpty)
                GestureDetector(
                  onTap: () => ApiService.showImagePreviewDialog(parentCtx, p['enhanced_image_url'] ?? p['raw_image_url']),
                  child: Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: ApiService.buildProductImage(
                          p['enhanced_image_url'] ?? p['raw_image_url'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Tap to Preview', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p['title'] ?? 'Product Details',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          p['status'] ?? 'Published',
                          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE3DD)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Retail Price (D2C)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text('₹${p['price_retail']?.toInt() ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.wine)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wholesale (B2B)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text('₹${p['price_wholesale']?.toInt() ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fair Price Floor:', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.bold)),
                        Text('₹${p['min_price']?.toInt() ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (p['type_of_art'] != null && p['type_of_art'].toString().isNotEmpty)
                _detailRow('Type of Art', p['type_of_art'].toString(), Icons.palette_outlined),
              _detailRow('Minimum Order Quantity (MOQ)', '${p['moq'] ?? 50} pieces', Icons.inventory_2_outlined),
              _detailRow('Category', p['category'] ?? 'N/A', Icons.category_outlined),
              _detailRow('Materials', p['materials'] ?? 'N/A', Icons.format_paint_outlined),
              _detailRow('Tags', p['tags'] ?? 'N/A', Icons.local_offer_outlined),
              if (p['bulk_pricing'] is List && (p['bulk_pricing'] as List).isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Wholesale Pricing by Quantity',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.wine),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFECE3DD)),
                  ),
                  child: Column(
                    children: (p['bulk_pricing'] as List).map<Widget>((tier) {
                      final t = tier is Map ? tier : <String, dynamic>{};
                      final range = t['range'] ?? '${t['min_qty'] ?? 0}+ pieces';
                      final price = t['price'] != null ? '₹${t['price']}' : '₹0';
                      final discount = t['discount']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              range.toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Row(
                              children: [
                                if (discount.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      discount,
                                      style: const TextStyle(
                                        color: AppColors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.wine,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              _detailRow('Description', p['description_en'] ?? 'N/A', Icons.description_outlined, isLongText: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDeleteProduct(parentCtx, modalCtx, p),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECE3DD)),
        ),
        child: Row(
          crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.wine),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext parentCtx, BuildContext? modalCtx, Map<String, dynamic> p) {
    showDialog(
      context: modalCtx ?? parentCtx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Product?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${p['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (modalCtx != null) {
                Navigator.pop(modalCtx);
              }
              if (p['id'] != null) {
                final success = await ApiService.deleteProduct(p['id']);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(parentCtx).showSnackBar(
                      SnackBar(content: Text('"${p['title']}" deleted successfully.'), backgroundColor: Colors.red),
                    );
                    _loadProducts();
                  } else {
                    ScaffoldMessenger.of(parentCtx).showSnackBar(
                      const SnackBar(content: Text('Failed to delete product.')),
                    );
                  }
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                          child: InkWell(
                            onTap: () => _showProductDetailModal(context, p),
                            child: Stack(
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(
                                    child: Container(
                                      color: const Color(0xFFE9DED3),
                                      width: double.infinity,
                                      child: ApiService.buildProductImage(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
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
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: InkWell(
                                    onTap: () => _confirmDeleteProduct(context, null, p),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                        ],
                                      ),
                                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    ]),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFECE3DD)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.wine),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    final fullNameCtrl = TextEditingController(text: currentArtisanSession?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: currentArtisanSession?['phone'] ?? '');
    final locationCtrl = TextEditingController(text: currentArtisanSession?['location'] ?? '');
    String currentGender = currentArtisanSession?['gender'] ?? 'Male';
    String currentCraft = currentArtisanSession?['craft_type'] ?? 'Handloom Weaving & Textiles';
    bool saving = false;

    final List<String> craftOptions = [
      'Handloom Weaving & Textiles',
      'Terracotta Pottery & Bio-Clay',
      'Bamboo & Cane Craft',
      'Wood Carving & Handicrafts',
      'Metal Dokra & Brassware',
      'Heritage Painting & Folk Art',
      'Jewelry & Beaded Craft',
      'Leather & General Craftsmanship',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (stCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            top: 20, left: 20, right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.wine, size: 28),
                    SizedBox(width: 8),
                    Text('Edit Artisan Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.wine)),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                  child: buildArtisanAvatar(
                    radius: 36,
                    showEditBadge: true,
                    onTap: () async {
                      await showProfileAvatarPickerModal(context, onUpdated: () {
                        setModalState(() {});
                        setState(() {});
                      });
                    },
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Tap photo to change profile picture', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
                const SizedBox(height: 16),

                const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 4),
                TextField(
                  controller: fullNameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    fillColor: Colors.white, filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    fillColor: Colors.white, filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 6),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final isSel = currentGender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: isSel,
                        selectedColor: AppColors.wine,
                        labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.wine, fontWeight: FontWeight.bold),
                        onSelected: (sel) {
                          if (sel) setModalState(() => currentGender = g);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                const Text('Craft Specialty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: craftOptions.contains(currentCraft) ? currentCraft : craftOptions.first,
                      items: craftOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => currentCraft = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Location / Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 4),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Varanasi, Uttar Pradesh',
                    fillColor: Colors.white, filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      final username = currentArtisanSession?['username'] ?? '';
                      final res = await ApiService.updateArtisanProfile(
                        username: username,
                        fullName: fullNameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        gender: currentGender,
                        craftType: currentCraft,
                        location: locationCtrl.text.trim(),
                        profilePicture: currentArtisanSession?['profile_picture'],
                      );
                      if (modalCtx.mounted) {
                        setModalState(() => saving = false);
                        Navigator.pop(modalCtx);
                        if (res != null && res['status'] == 'success') {
                          setState(() {
                            currentArtisanSession = res['artisan'];
                            currentArtisanSession!['name'] = fullNameCtrl.text.trim();
                            currentArtisanSession!['phone'] = phoneCtrl.text.trim();
                            currentArtisanSession!['gender'] = currentGender;
                            currentArtisanSession!['craft_type'] = currentCraft;
                            currentArtisanSession!['location'] = locationCtrl.text.trim();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile details updated successfully! ✨'), backgroundColor: AppColors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res?['message'] ?? 'Failed to update profile.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artisanName = currentArtisanSession?['name'] ?? 'Guest Artisan';
    final username = currentArtisanSession?['username'] ?? 'guest';
    final phone = currentArtisanSession?['phone'] ?? 'N/A';
    final gender = currentArtisanSession?['gender'] ?? 'N/A';
    final craftType = currentArtisanSession?['craft_type'] ?? 'Handloom & Handicrafts';
    final location = currentArtisanSession?['location'] ?? 'India';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.wine)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.wine),
                  tooltip: 'Edit Profile',
                  onPressed: _showEditProfileModal,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  buildArtisanAvatar(
                    radius: 34,
                    showEditBadge: true,
                    onTap: () async {
                      await showProfileAvatarPickerModal(context, onUpdated: () {
                        setState(() {});
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artisanName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.wine),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Verified Artisan', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Personal & Craft Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.wine)),
            const SizedBox(height: 12),

            _buildProfileRow(Icons.badge_outlined, 'Full Name', artisanName),
            _buildProfileRow(Icons.alternate_email, 'Username', '@$username'),
            _buildProfileRow(Icons.phone_outlined, 'Phone', phone),
            _buildProfileRow(Icons.wc_outlined, 'Gender', gender),
            _buildProfileRow(Icons.brush_outlined, 'Craft Specialty', craftType),
            _buildProfileRow(Icons.location_on_outlined, 'Location', location),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfileModal,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        currentArtisanSession = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully.')),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class BuyersPage extends StatelessWidget {
  const BuyersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtisanEnquiriesPage(artisanSession: currentArtisanSession);
  }
}
