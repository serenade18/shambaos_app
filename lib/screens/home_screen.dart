import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shambaOS/screens/customers/customer_screen.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/weather_model.dart';
import 'fields/field_service.dart';
import 'fields/field_widgets.dart';
import 'fields/fields_screen.dart';
import 'home/home_hero.dart';
import 'profile/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/edit_profile_screen.dart';
import '../services/app_colors.dart';
import '../services/app_type.dart';
import '../widgets/ledger.dart';
import 'animals/animal_screen.dart';
import 'plants/plant_screen.dart';
import 'markets/market_screen.dart';
import 'dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isFarmSetup = false;
  bool _updatesExpanded = true;
  Map<String, dynamic>? _farm;
  List<Field>? _fields;
  FieldCategory? _category;
  WeatherModel? _today;
  bool _weatherLoading = true;

  bool get _isProfileComplete =>
      _userName.isNotEmpty &&
      _userEmail.isNotEmpty &&
      !_userEmail.endsWith('@phone.shamba.local');

  // Section hides only when BOTH conditions are satisfied
  bool get _allUpdatesComplete => _isProfileComplete && _isFarmSetup;

  final List<Map<String, dynamic>> _quickMenuItems = [
    {
      'title': 'Dashboard',
      'route': const DashboardScreen(),
      'icon': 'images/assets/icons/dashboard.png',
    },
    {
      'title': 'Animal Husbandry',
      'route': const AnimalScreen(),
      'icon': 'images/assets/icons/livestock.png',
    },
    {
      'title': 'Plant Husbandry',
      'route': const PlantScreen(),
      'icon': 'images/assets/icons/leaf.png',
    },
    {
      'title': 'Customers',
      'route': const CustomersScreen(),
      'icon': 'images/assets/icons/customer.png',
    },
    {
      'title': 'Sales',
      'route': null,
      'icon': 'images/assets/icons/revenue.png',
    },
    {
      'title': 'Inventory',
      'route': null,
      'icon': 'images/assets/icons/inventory.png',
    },
    {
      'title': 'Payments',
      'route': null,
      'icon': 'images/assets/icons/payment.png',
    },
    {
      'title': 'Procurement',
      'route': null,
      'icon': 'images/assets/icons/procurement.png',
    },
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
      'ctaColor': AppColors.brand,
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
    _loadFarmStatus();
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
        _userName = user['name'] ?? user['username'] ?? user['email'] ?? 'User';
        _userEmail = user['email'] ?? '';
      });
    }
  }

  /// The main farm, its fields, and today's forecast for it.
  Future<void> _loadFarmStatus() async {
    final (farm, fields) = await FieldService.load();
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _fields = fields;
      _isFarmSetup = farm != null;
    });
    if (farm == null) {
      setState(() => _weatherLoading = false);
      return;
    }
    final days = await FieldService.forecast(farm['id']);
    if (!mounted) return;
    setState(() {
      _today = days.isEmpty ? null : days.first;
      _weatherLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadUser(), _loadFarmStatus()]);
  }

  // ══════════════════════════════════════════════════════════
  // MY FIELDS
  // ══════════════════════════════════════════════════════════
  Widget _buildMyFields(AppColors colors) {
    final fields = _fields;
    final shown = fields?.where((f) => _category == null || f.category == _category).take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('My fields', style: AppType.titleM.copyWith(color: colors.textPrimary))),
              if (fields != null && fields.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/fields'),
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (fields == null)
            Container(height: 108, decoration: BoxDecoration(color: colors.surfaceMuted, borderRadius: BorderRadius.circular(16)))
          else if (fields.isEmpty)
            SlLedger(children: [
              SlLedgerRow(
                title: _farm == null ? 'Set up your farm' : 'No fields yet',
                meta: _farm == null
                    ? 'Add your farm to see your fields, weather and records here.'
                    : 'Add the animals you keep and the crops you grow.',
              ),
            ])
          else ...[
            FieldCategories(
              selected: _category,
              present: fields.map((f) => f.category).toSet(),
              onChanged: (cat) => setState(() => _category = cat),
            ),
            const SizedBox(height: 16),
            for (final f in shown!) ...[
              FieldCard(field: f, onTap: () => openField(context, f)),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(userName: _userName, userEmail: _userEmail),
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
          phone: '',
          username: _userName,
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadUser();
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: context.appColors.divider);

  // ══════════════════════════════════════════════════════════
  // 1. HEADER
  // ══════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════
  // 3. IMPORTANT UPDATES (collapsible, hidden when all complete)
  // ══════════════════════════════════════════════════════════
  Widget _buildUpdateItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Its own Material, so the tap ripple shows on the tinted box behind it.
    return Material(
      type: MaterialType.transparency,
      child: _updateTile(icon: icon, title: title, subtitle: subtitle, onTap: onTap),
    );
  }

  Widget _updateTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.appColors.brandSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.appColors.brandText, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: context.appColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: context.appColors.textSecondary),
      ),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildImportantUpdates(AppColors colors) {
    // Guard: nothing to show
    if (_allUpdatesComplete) return const SizedBox.shrink();

    // Build only the items that are still pending
    final List<Widget> pendingItems = [];

    if (!_isProfileComplete) {
      pendingItems.add(
        _buildUpdateItem(
          icon: Icons.auto_awesome_outlined,
          title: 'Complete your profile',
          subtitle: 'Unlock a personalised experience',
          onTap: _openEditProfile,
        ),
      );
    }

    if (!_isFarmSetup) {
      if (pendingItems.isNotEmpty) {
        pendingItems.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: context.appColors.brandSoft,
          ),
        );
      }
      pendingItems.add(
        _buildUpdateItem(
          icon: Icons.agriculture_outlined,
          title: 'Setup your farm',
          subtitle: 'Add your farm details to get started',
          onTap: () {
            // TODO: Navigate to farm setup screen
          },
        ),
      );
    }

    return Container(
      color: context.appColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _updatesExpanded = !_updatesExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Important updates',
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
                    color: context.appColors.brandText,
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
                  color: context.appColors.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appColors.brandSoft, width: 1),
                ),
                // Uses dynamic pendingItems — only shows what's incomplete
                child: Column(children: pendingItems),
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
  // 4. FEATURE SHORTCUTS
  // ══════════════════════════════════════════════════════════
  Widget _buildFeatureShortcuts(AppColors colors) {
    final items = [
      {'title': 'Markets', 'route': const MarketScreen(), 'icon': 'images/assets/icons/market.png'},
      {'title': 'Products', 'route': null, 'icon': 'images/assets/icons/product.png'},
      {'title': 'Vet', 'route': null, 'icon': 'images/assets/icons/vet.png'},
      {'title': 'Agro Dealer', 'route': null, 'icon': 'images/assets/icons/dealer.png'},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final containerHeight = isTablet ? 260.0 : 220.0;
    final iconBoxHeight = isTablet ? 80.0 : 70.0;
    final iconSize = isTablet ? 38.0 : 34.0;
    final fontSize = isTablet ? 13.0 : 12.0;

    return Container(
      height: containerHeight,
      color: context.appColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: items.map((item) {
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (item['route'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => item['route'] as Widget,
                          ),
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: iconBoxHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: context.appColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              item['icon'] as String,
                              height: iconSize,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported_outlined,
                                color: context.appColors.brandText,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 5. QUICK MENU GRID
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickMenuGrid(AppColors colors) {
    return Container(
      color: context.appColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          LayoutBuilder(
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
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final item = _quickMenuItems[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (item['route'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item['route']),
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Container(
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
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    item['icon'] as String,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.image_not_supported_outlined,
                                      color: context.appColors.brandText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
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
                    ? AppColors.brand
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
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
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
                      horizontal: 20,
                      vertical: 10,
                    ),
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
      color: context.appColors.cardBackground,
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
                Text(
                  'Help your farmer friends by inviting\nthem to the app',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.brand,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: Icon(
                        Icons.send_rounded,
                        color: context.appColors.brandText,
                        size: 20,
                      ),
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
              color: context.appColors.brandSoft,
              border: Border.all(
                color: AppColors.brand.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'images/assets/icons/farmer.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline_rounded,
                  color: context.appColors.brandText,
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
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
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
              HomeHero(
                userName: _userName,
                initials: _getInitials(_userName),
                place: _farm == null ? null : ('${_farm!['county'] ?? ''}'.isNotEmpty ? '${_farm!['county']}' : _farm!['name']),
                today: _today,
                weatherLoading: _weatherLoading,
                onAvatarTap: _openProfile,
                onBellTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
              _buildMyFields(colors),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SlSeasonStrip(),
              ),

              // Hidden only when BOTH profile is complete AND farm is set up
              if (!_allUpdatesComplete) ...[
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