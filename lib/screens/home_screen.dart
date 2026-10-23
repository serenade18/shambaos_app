import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shambaOS/screens/customers/customer_screen.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/weather_model.dart';
import 'fields/field_service.dart';
import 'fields/field_widgets.dart';
import 'fields/fields_screen.dart';
import '../widgets/phosphor_icons.dart';
import 'home/home_hero.dart';
import 'home/today_section.dart';
import 'records/record_menu.dart';
import 'alerts/alerts_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/edit_profile_screen.dart';
import '../services/app_colors.dart';
import '../services/app_type.dart';
import '../widgets/ledger.dart';
import 'animals/animal_screen.dart';
import 'plants/plant_screen.dart';
import 'markets/market_screen.dart';
import 'sales/sales_screen.dart';
import 'vets/vets_screen.dart';
import 'auth/auth_ui.dart';
import 'dashboard/dashboard_screen.dart';
import '../l10n/tr.dart';
import 'farm/farm_map_screen.dart';
import 'farm/add_to_farm.dart';
import 'farm/setup_farm_screen.dart';

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
  List<TodayRow>? _todayRows; // the herds and batches, for Today
  WeatherModel? _today;
  double? _weekRain; // mm forecast over the next 7 days
  bool _weatherLoading = true;

  bool get _isProfileComplete =>
      _userName.isNotEmpty &&
      _userEmail.isNotEmpty &&
      !_userEmail.endsWith('@shambos.com');

  // Section hides only when BOTH conditions are satisfied
  bool get _allUpdatesComplete => _isProfileComplete && _isFarmSetup;

  List<Map<String, dynamic>> get _quickMenuItems => [
    {
      'title': 'Dashboard'.tr,
      'route': const DashboardScreen(),
      'icon': 'images/assets/icons/dashboard.png',
    },
    {
      'title': 'Animal Husbandry'.tr,
      'route': const AnimalScreen(),
      'icon': 'images/assets/icons/livestock.png',
    },
    {
      'title': 'Plant Husbandry'.tr,
      'route': const PlantScreen(),
      'icon': 'images/assets/icons/leaf.png',
    },
    {
      'title': 'Customers'.tr,
      'route': const CustomersScreen(),
      'icon': 'images/assets/icons/customer.png',
    },
    {
      'title': 'Sales'.tr,
      'route': null,
      'icon': 'images/assets/icons/revenue.png',
    },
    {
      'title': 'Inventory'.tr,
      'route': null,
      'icon': 'images/assets/icons/inventory.png',
    },
    {
      'title': 'Payments'.tr,
      'route': null,
      'icon': 'images/assets/icons/payment.png',
    },
    {
      'title': 'Procurement'.tr,
      'route': null,
      'icon': 'images/assets/icons/procurement.png',
    },
  ];

  List<Map<String, dynamic>> get _posterItems => [
    {
      'title': 'Choose your\nMaize Seeds'.tr,
      'subtitle': 'Based on season and location'.tr,
      'cta': 'View Seeds'.tr,
      'bgColor': const Color(0xFFDCEEF8),
      'ctaColor': const Color(0xFF1565C0),
      'imagePath': null,
    },
    {
      'title': 'Upgrade to\nPro Plan'.tr,
      'subtitle': 'Elevate your productivity today'.tr,
      'cta': 'Upgrade Now'.tr,
      'bgColor': const Color(0xFFE8F5E9),
      'ctaColor': AppColors.brand,
      'imagePath': null,
    },
    {
      'title': 'Market\nPrices Live'.tr,
      'subtitle': 'Real-time Nairobi commodity data'.tr,
      'cta': 'View Prices'.tr,
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
    FarmMapScreen.boundarySaved.addListener(_loadFarmStatus);
    _posterPageController = PageController(
      initialPage: _posterItems.length * 100,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    FarmMapScreen.boundarySaved.removeListener(_loadFarmStatus);
    _posterPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    if (user != null) {
      setState(() {
        _userName = user['name'] ?? user['username'] ?? user['email'] ?? 'User'.tr;
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
    _loadToday();
    final days = await FieldService.forecast(farm['id']);
    if (!mounted) return;
    setState(() {
      _today = days.isEmpty ? null : days.first;
      _weekRain = days.isEmpty ? null : days.take(7).fold<double>(0, (sum, d) => sum + d.precipitation);
      _weatherLoading = false;
    });
  }

  /// Today's herds and batches; kept as they were when it can't load.
  Future<void> _loadToday() async {
    final farm = _farm;
    if (farm == null) return;
    final rows = await TodayService.load('${farm['id']}');
    if (!mounted || rows == null) return;
    setState(() => _todayRows = rows);
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadUser(), _loadFarmStatus()]);
  }

  // ══════════════════════════════════════════════════════════
  // MY FIELDS
  // ══════════════════════════════════════════════════════════
  // The design's line icons (Lucide, ISC licence).
  static const _usersIcon = '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>';
  static const _receiptIcon = '<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><path d="M12 17.5v-11"/>';
  static const _vetIcon = '<path d="M11 2v2"/><path d="M5 2v2"/><path d="M5 3H4a2 2 0 0 0-2 2v4a6 6 0 0 0 12 0V5a2 2 0 0 0-2-2h-1"/><path d="M8 15a6 6 0 0 0 12 0v-3"/><circle cx="20" cy="10" r="2"/>';
  static const _storeIcon = '<path d="M15 21v-5a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v5"/><path d="M17.774 10.31a1.12 1.12 0 0 0-1.549 0 2.5 2.5 0 0 1-3.451 0 1.12 1.12 0 0 0-1.548 0 2.5 2.5 0 0 1-3.452 0 1.12 1.12 0 0 0-1.549 0 2.5 2.5 0 0 1-3.77-3.248l2.889-4.184A2 2 0 0 1 7 2h10a2 2 0 0 1 1.653.873l2.895 4.192a2.5 2.5 0 0 1-3.774 3.244"/><path d="M4 10.95V19a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8.05"/>';

  /// Customers, sales, vets and markets, a tap from Home (the design's "Your business").
  Widget _buildBusiness(AppColors colors) {
    Widget tile(String icon, String label, Widget Function() page) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                  child: Column(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: colors.brandSoft, shape: BoxShape.circle),
                      child: Center(child: LineIcon(icon, size: 20, color: colors.brandText)),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: AppType.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  ]),
                ),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Your business'.tr,
            style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        const SizedBox(height: 10),
        Row(children: [
          tile(_usersIcon, 'Customers'.tr, () => const CustomersScreen()),
          const SizedBox(width: 8),
          tile(_receiptIcon, 'Sales'.tr, () => const SalesScreen()),
          const SizedBox(width: 8),
          tile(_vetIcon, 'Vets'.tr, () => const VetsScreen()),
          const SizedBox(width: 8),
          tile(_storeIcon, 'Markets'.tr, () => const MarketScreen()),
        ]),
      ]),
    );
  }

  Widget _buildMyFields(AppColors colors) {
    final fields = _fields;
    final shown = fields?.take(3).toList();
    final link = TextStyle(fontFamily: AppType.text, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: colors.brandText);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('My fields'.tr,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: colors.textPrimary)),
              ),
              if (_farm != null)
                TextButton(
                  onPressed: () => openFarmRecordMenu(context, fields ?? const []).then((saved) {
                    if (saved) _loadToday();
                  }),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text('Record'.tr, style: link),
                ),
              if (fields != null && fields.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/fields'),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.only(left: 8)),
                  child: Text('See all'.tr, style: link),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // A farm with no boundary yet: weather is for its county until it's mapped.
          if (_farm != null && _farm!['boundary'] == null) ...[
            SlLedger(children: [
              SlLedgerRow(
                title: 'Map your farm'.tr,
                meta: 'Draw or walk its boundary for weather and crop checks on your exact land.'.tr,
                leading: Icon(PhosphorIconsRegular.mapPin, color: colors.brandText),
                status: Icon(PhosphorIconsRegular.caretRight, size: 18, color: colors.textSecondary),
                onTap: _openFarmMap,
              ),
            ]),
            const SizedBox(height: 12),
          ],
          if (fields == null)
            Container(height: 108, decoration: BoxDecoration(color: colors.surfaceMuted, borderRadius: BorderRadius.circular(16)))
          else if (fields.isEmpty)
            SlLedger(children: [
              SlLedgerRow(
                onTap: _farm == null ? _setUpFarm : _addToFarm,
                status: Icon(PhosphorIconsRegular.caretRight, size: 18, color: colors.textSecondary),
                title: _farm == null ? 'Set up your farm'.tr : 'No fields yet'.tr,
                meta: _farm == null
                    ? 'Add your farm to see your fields, weather and records here.'.tr
                    : 'Add the animals you keep and the crops you grow.'.tr,
              ),
            ])
          else ...[
            for (final f in shown!) ...[
              FieldCard(field: f, onTap: () => openField(context, f)),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  /// "What are you adding?" for the farm.
  Future<void> _addToFarm() async {
    final farm = _farm;
    if (farm == null) return;
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddToFarmScreen(farm: farm)));
    if (added == true) _loadFarmStatus();
  }

  /// A new farm: its name and county, the map, then what it runs. Home reloads
  /// through FarmMapScreen.boundarySaved.
  Future<void> _setUpFarm() => setUpFarm(context);

  /// The farm map.
  Future<void> _openFarmMap() async {
    final farm = _farm;
    if (farm == null) return;
    await FarmMapScreen.open(context, farm); // Home reloads through FarmMapScreen.boundarySaved
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
          title: 'Complete your profile'.tr,
          subtitle: 'Unlock a personalised experience'.tr,
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
          title: 'Setup your farm'.tr,
          subtitle: 'Add your farm details to get started'.tr,
          onTap: _setUpFarm,
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
                    'Important updates'.tr,
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
                  'Invite Friends'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Help your farmer friends by inviting\nthem to the app'.tr,
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
                      hintText: 'Enter phone number'.tr,
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
      extendBody: true, // the page scrolls under the nav bar
      bottomNavigationBar: const AppBottomNav(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.brand,
        backgroundColor: colors.cardBackground,
        displacement: 20,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: AppBottomNav.scrollPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHero(
                userName: _userName,
                initials: _getInitials(_userName),
                place: _farm == null
                    ? null
                    : ['${_farm!['name'] ?? ''}', '${_farm!['county'] ?? ''}'].where((p) => p.isNotEmpty).join(', '),
                today: _today,
                weekRain: _weekRain,
                weatherLoading: _weatherLoading,
                onAvatarTap: _openProfile,
                onPlaceTap: _farm == null ? null : _openFarmMap,
                onBellTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
              if (_todayRows?.isNotEmpty ?? false)
                TodaySection(rows: _todayRows!, fields: _fields ?? const [], onSaved: _loadToday),
              _buildBusiness(colors),
              _buildMyFields(colors),

              // Hidden only when BOTH profile is complete AND farm is set up
              if (!_allUpdatesComplete) ...[
                const SizedBox(height: 8),
                _buildImportantUpdates(colors),
              ],

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