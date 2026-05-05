import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/weather_widget.dart';
import 'profile/profile_screen.dart';
import 'profile/edit_profile_screen.dart';
import '../services/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<WeatherWidgetState> _weatherKey =
      GlobalKey<WeatherWidgetState>();

  String _userName = '';
  String _userEmail = '';
  bool _updatesExpanded = true;

  bool get _isProfileComplete =>
      _userName.isNotEmpty &&
      _userEmail.isNotEmpty &&
      !_userEmail.endsWith('@phone.shamba.local');

  final List<Map<String, dynamic>> _quickMenuItems = [
    {'title': 'Dashboard',        'icon': 'images/assets/icons/dashboard.png'},
    {'title': 'Animal Husbandry', 'icon': 'images/assets/icons/livestock.png'},
    {'title': 'Plant Husbandry',  'icon': 'images/assets/icons/leaf.png'},
    {'title': 'Sales',            'icon': 'images/assets/icons/revenue.png'},
    {'title': 'Customers',        'icon': 'images/assets/icons/customer.png'},
    {'title': 'Inventory',        'icon': 'images/assets/icons/inventory.png'},
    {'title': 'Payments',         'icon': 'images/assets/icons/payment.png'},
    {'title': 'Procurement',      'icon': 'images/assets/icons/procurement.png'},
  ];

  final List<Map<String, dynamic>> _posterItems = [
    {
      'title': 'Choose your\nMaize Seeds',
      'subtitle': 'Based on season and location',
      'cta': 'View Seeds',
      'bgColor': const Color(0xFFDCEEF8),
      'ctaColor': const Color(0xFF1565C0),
      'imagePath': null,
    },
    {
      'title': 'Upgrade to\nPro Plan',
      'subtitle': 'Elevate your productivity today',
      'cta': 'Upgrade Now',
      'bgColor': const Color(0xFFE8F5E9),
      'ctaColor': const Color(0xFF2E7D32),
      'imagePath': null,
    },
    {
      'title': 'Market\nPrices Live',
      'subtitle': 'Real-time Nairobi commodity data',
      'cta': 'View Prices',
      'bgColor': const Color(0xFFFFF8E1),
      'ctaColor': const Color(0xFFE65100),
      'imagePath': null,
    },
  ];

  late PageController _posterPageController;
  int _currentPosterPage = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _posterPageController = PageController(
      initialPage: _posterItems.length * 100,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _posterPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    if (user != null) {
      setState(() {
        _userName =
            user['name'] ?? user['username'] ?? user['email'] ?? 'User';
        _userEmail = user['email'] ?? '';
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadUser(),
      _weatherKey.currentState?.refresh() ?? Future.value(),
    ]);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userName: _userName,
          userEmail: _userEmail,
        ),
      ),
    );
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _userName,
          email: _userEmail,
          phone: '',        // fallback (replace if you have it)
          username: _userName, // or real username if available
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadUser(); // refresh after edit
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final palette = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return palette[name.hashCode % palette.length];
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));

  // ══════════════════════════════════════════════════════════
  // 1. HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(AppColors colors) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAvatarColor(_userName),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  _getInitials(_userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Karibu 👋',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 2. WEATHER STRIP
  // ══════════════════════════════════════════════════════════
  Widget _buildWeatherStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: WeatherWidget(key: _weatherKey),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 3. IMPORTANT UPDATES (collapsible, hidden when profile complete)
  // ══════════════════════════════════════════════════════════
  Widget _buildImportantUpdates(AppColors colors) {
    // Don't show if the user has a real name and a real email address
    if (_isProfileComplete) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _updatesExpanded = !_updatesExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text('📢', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Important Updates!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _updatesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF4CAF50),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFD6ECD9), width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_outlined,
                        color: Color(0xFF4CAF50), size: 24),
                  ),
                  title: const Text(
                    'Complete your profile',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A)),
                  ),
                  subtitle: const Text(
                    'Unlock a personalised experience',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                  trailing: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
                  onTap: _openEditProfile,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _updatesExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 4. Markets and vets
  // ══════════════════════════════════════════════════════════
  Widget _buildFeatureShortcuts(AppColors colors) {
    final items = [
      {
        'title': 'View Markets',
        'icon': 'images/assets/icons/market.png',
      },
      {
        'title': 'Bayer Products',
        'icon': 'images/assets/icons/product.png',
      },
      {
        'title': 'Request Vet',
        'icon': 'images/assets/icons/vet.png',
      },
      {
        'title': 'Nearby Agro\nDealer',
        'icon': 'images/assets/icons/dealer.png',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 16, // 👈 aligned with system
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 64, // 👈 tighter + consistent
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        item['icon']!,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5, // 👈 tuned for 2-line balance
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 5. QUICK MENU GRID
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickMenuGrid(AppColors colors) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int cols = 4;
          if (width < 360) cols = 3;
          if (width > 600) cols = 5;

          final itemW = width / cols;
          final boxSize = itemW * 0.62;
          final fontSize = (itemW * 0.12).clamp(10.0, 13.0);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickMenuItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = _quickMenuItems[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: boxSize,
                      width: boxSize,
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          item['icon'] as String,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 6. POSTER BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildPosterBanner() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _posterPageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) =>
                setState(() => _currentPosterPage = i % _posterItems.length),
            itemCount: 10000,
            itemBuilder: (context, index) {
              final actual = index % _posterItems.length;
              return _buildPosterCard(_posterItems[actual]);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _posterItems.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPosterPage == i ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPosterPage == i
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterCard(Map<String, dynamic> poster) {
    final bgColor = poster['bgColor'] as Color;
    final ctaColor = poster['ctaColor'] as Color;
    final imagePath = poster['imagePath'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            right: 155,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  poster['title'],
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: ctaColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  poster['subtitle'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctaColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(poster['cta']),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            top: 15,
            bottom: 15,
            width: 165,
            child: imagePath != null
                ? ClipOval(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _posterPlaceholder(ctaColor),
                    ),
                  )
                : _posterPlaceholder(ctaColor),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder(Color accent) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.10),
        border: Border.all(color: accent.withOpacity(0.20), width: 2),
      ),
      child: Icon(
        Icons.agriculture_rounded,
        color: accent.withOpacity(0.45),
        size: 52,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 7. INVITE FRIENDS
  // ══════════════════════════════════════════════════════════
  Widget _buildInviteFriends(AppColors colors) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Friends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Help your farmer friends by inviting\nthem to the app',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF4CAF50), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      suffixIcon: Icon(Icons.send_rounded,
                          color: Color(0xFF4CAF50), size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F5E9),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/farmer_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: const AppBottomNav(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.brand,
        backgroundColor: colors.cardBackground,
        displacement: 20,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors),
              _divider(),
              _buildWeatherStrip(),
              _divider(),

              // Only rendered when profile is incomplete
              if (!_isProfileComplete) ...[
                const SizedBox(height: 8),
                _buildImportantUpdates(colors),
              ],

              const SizedBox(height: 8),
              _divider(),
              _buildFeatureShortcuts(colors),

              const SizedBox(height: 8),
              _buildQuickMenuGrid(colors),
              const SizedBox(height: 8),
              _buildPosterBanner(),
              const SizedBox(height: 8),
              _buildInviteFriends(colors),
            ],
          ),
        ),
      ),
    );
  }
}