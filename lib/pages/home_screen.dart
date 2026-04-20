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
  int _selectedCategory = 0;

  final GlobalKey<WeatherWidgetState> _weatherKey =
      GlobalKey<WeatherWidgetState>();

  String _userName = '';
  String _userEmail = '';

  final List<String> _categories = [
    'All',
    'Carrots',
    'Vegetable',
    'Fruit',
    'Pumpkin',
    'Grain',
  ];

  final List<Map<String, String>> _fields = [
    {
      'title': 'Optimize Pumpkin Harvest',
      'desc': 'Implement efficient workflows with our automated system.',
      'image': 'images/auth/banana.png',
    },
    {
      'title': 'Healthy Wheat Growth',
      'desc': 'Real time health monitoring for the grain sector.',
      'image': 'images/auth/farm.png',
    },
    {
      'title': 'Carrot Field Analytics',
      'desc': 'Track soil quality and yield predictions live.',
      'image': 'images/auth/chicken.png',
    },
  ];

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

  final PageController _adPageController = PageController();
  int _currentAdPage = 0;

  final List<Map<String, dynamic>> _adBanners = [
    {
      'title': 'UPGRADE PRO 🚀',
      'desc': 'Elevate your productivity and achieve more with our Pro plan!',
      'icon': Icons.trending_up_rounded,
    },
    {
      'title': 'SMART FARMING 🚜',
      'desc': 'Get precise NDVI satellite data for all your active fields.',
      'icon': Icons.satellite_alt_rounded,
    },
    {
      'title': 'MARKET PRICES 📈',
      'desc': 'Real-time commodity prices from the Nairobi market.',
      'icon': Icons.bar_chart_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
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
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickMenuItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 15,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final item = _quickMenuItems[index];
          return Column(
            children: [
              Container(
                height: 60,
                width: 60,
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
                  color: const Color(0xFF4CAF50), // Shamba Green
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // AD CAROUSEL
  // ══════════════════════════════════════════════════════════
  // Widget _buildAdCarousel(AppColors colors) {
  //   return Column(
  //     children: [
  //       SizedBox(
  //         height: 180,
  //         child: PageView.builder(
  //           controller: _adPageController,
  //           physics: const BouncingScrollPhysics(),
  //           padEnds: false,
  //           onPageChanged: (int page) => setState(() => _currentAdPage = page),
  //           itemCount: _adBanners.length,
  //           itemBuilder: (context, index) {
  //             return _buildAdBanner(_adBanners[index], colors);
  //           },
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       // Pagination dots
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(
  //           _adBanners.length,
  //           (index) => AnimatedContainer(
  //             duration: const Duration(milliseconds: 300),
  //             margin: const EdgeInsets.symmetric(horizontal: 4),
  //             height: 6,
  //             width: _currentAdPage == index ? 20 : 6,
  //             decoration: BoxDecoration(
  //               color: _currentAdPage == index 
  //                   ? const Color(0xFF4CAF50) 
  //                   : colors.textHint.withOpacity(0.3),
  //               borderRadius: BorderRadius.circular(3),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

Widget _buildAdCarousel(AppColors colors) {
  return Column(
    children: [
      SizedBox(
        height: 180,
        width: double.infinity,
        child: PageView.builder(
          controller: _adPageController,
          physics: const PageScrollPhysics(), // tighter snapping
          padEnds: false,
          onPageChanged: (int page) => setState(() => _currentAdPage = page),
          itemCount: _adBanners.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: MediaQuery.of(context).size.width, // force full width
              child: _buildAdBanner(_adBanners[index], colors),
            );
          },
        ),
      ),
      const SizedBox(height: 12),

      // Pagination dots
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
      [const Color(0xFF1D976C), const Color(0xFF93F9B9)], // green
      [const Color(0xFF396afc), const Color(0xFF2948ff)], // blue
      [const Color(0xFFf7971e), const Color(0xFFffd200)], // orange
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
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✨ Glow / Blur overlay
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

          // Decorative radial glow
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

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // LEFT CONTENT
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TITLE
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

                      // DESCRIPTION
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

                      // CTA BUTTON
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

                // RIGHT ICON
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.brand,
                  backgroundColor: colors.cardBackground,
                  displacement: 20,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildAdCarousel(colors),
                        // const SizedBox(height: 28),
                        // _buildMyFieldsHeader(colors),
                        // const SizedBox(height: 16),
                        // _buildCategoryChips(colors),
                        // const SizedBox(height: 20),
                        // _buildFieldCards(colors),
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
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(),
          ),
        ],
      ),
    );
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

  // ══════════════════════════════════════════════════════════
  // MY FIELDS HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildMyFieldsHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Fields',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'See All',
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CATEGORY CHIPS
  // ══════════════════════════════════════════════════════════
  Widget _buildCategoryChips(AppColors colors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? colors.chipSelected : colors.chipBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? colors.chipSelected.withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: selected ? 8 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: selected ? Colors.white : colors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FIELD CARDS
  // ══════════════════════════════════════════════════════════
  Widget _buildFieldCards(AppColors colors) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _fields.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) =>
            _buildFieldCard(_fields[index], colors),
      ),
    );
  }

  Widget _buildFieldCard(Map<String, String> field, AppColors colors) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  field['image']!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.grass,
                          color: AppColors.brand, size: 40),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field['title']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  field['desc']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}