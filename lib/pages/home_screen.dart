import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/weather_widget.dart';
import '../pages/profile/profile_screen.dart';
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

  final List<Map<String, dynamic>> _quickMenuItems = [
    {'title': 'Husbandry', 'icon': Icons.pets_outlined},
    {'title': 'Planting', 'icon': Icons.grass_outlined},
    {'title': 'Inventory', 'icon': Icons.inventory_2_outlined},
    {'title': 'Revenue', 'icon': Icons.monetization_on_outlined},
    {'title': 'Customers', 'icon': Icons.people_outline},
    {'title': 'Procurement', 'icon': Icons.shopping_cart_outlined},
    {'title': 'Payments', 'icon': Icons.receipt_long_outlined},
    {'title': 'Analytics', 'icon': Icons.analytics_outlined},
  ];

  final List<Map<String, dynamic>> _adBanners = [
    {
      'title': 'UPGRADE PRO',
      'desc': 'Elevate your productivity and achieve more with our Pro plan!',
      'icon': Icons.trending_up_rounded,
    },
    {
      'title': 'SMART FARMING',
      'desc': 'Get precise NDVI satellite data for all your active fields.',
      'icon': Icons.satellite_alt_rounded,
    },
    {
      'title': 'MARKET PRICES',
      'desc': 'Real-time commodity prices from the Nairobi market.',
      'icon': Icons.bar_chart_rounded,
    },
  ];

  late PageController _adPageController;
  int _currentAdPage = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Set initial page to a middle-ground index for infinite feel
    _adPageController = PageController(
      initialPage: _adBanners.length * 100, 
      viewportFraction: 0.9,
    );
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


  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.headerBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _openProfile,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAvatarColor(_userName),
                        border: Border.all(
                          color: colors.avatarBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${_userName.isEmpty ? "User" : _userName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: colors.iconOverlay,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              WeatherWidget(key: _weatherKey),
            ],
          ),
        ),
      ),
    );
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  // ══════════════════════════════════════════════════════════
  // QUICK MENU
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickMenuHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Quick Actions',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuickMenuGrid(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          int crossAxisCount = 4;
          if (width < 360) {
            crossAxisCount = 3;
          } else if (width > 600) {
            crossAxisCount = 5;
          }

          final itemWidth = width / crossAxisCount;
          final iconSize = itemWidth * 0.35;
          final containerSize = itemWidth * 0.55;
          final fontSize = itemWidth * 0.12;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickMenuItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final item = _quickMenuItems[index];

              return Column(
                children: [
                  Container(
                    height: containerSize,
                    width: containerSize,
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      item['icon'],
                      color: const Color(0xFF4CAF50),
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize.clamp(10, 14),
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // AD CAROUSEL
  // ══════════════════════════════════════════════════════════
  Widget _buildAdCarousel(AppColors colors) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: PageView.builder(
            controller: _adPageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (int index) {
              setState(() {
                // 3. Map the large index back to 0, 1, or 2 for the dots
                _currentAdPage = index % _adBanners.length;
              });
            },
            // 4. Set a massive number for the item count
            itemCount: 10000, 
            itemBuilder: (context, index) {
              // 5. Calculate the actual index for the data
              final actualIndex = index % _adBanners.length;
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                child: _buildAdBanner(_adBanners[actualIndex], colors),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _adBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentAdPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentAdPage == index
                    ? const Color(0xFF4CAF50)
                    : colors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdBanner(Map<String, dynamic> ad, AppColors colors) {
    final List<List<Color>> gradients = [
      [const Color(0xFF1D976C), const Color.fromARGB(255, 29, 134, 68)],
      [const Color.fromARGB(255, 38, 85, 228), const Color(0xFF2948ff)],
      [const Color(0xFFf7971e), const Color.fromARGB(255, 183, 152, 18)],
    ];

    final gradient = gradients[_adBanners.indexOf(ad) % gradients.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad['desc'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Explore",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      ad['icon'],
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      bottomNavigationBar: const AppBottomNav(),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.brand,
              backgroundColor: colors.cardBackground,
              displacement: 20,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors),
                    const SizedBox(height: 20),
                    _buildAdCarousel(colors),
                    const SizedBox(height: 28),
                    _buildQuickMenuHeader(colors),
                    const SizedBox(height: 16),
                    _buildQuickMenuGrid(colors),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}