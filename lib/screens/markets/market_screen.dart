import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_colors.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  // ══════════════════════════════════════════════════════════
  // DATA
  // ══════════════════════════════════════════════════════════
  final List<Map<String, dynamic>> _markets = [
    {
      'id': 1,
      'name': 'Wakulima Market',
      'location': 'Nairobi CBD',
      'distance': '2.1 km',
      'type': 'Wholesale',
      'status': 'open',
      'hours': '5:00 AM – 6:00 PM',
      'products': ['Vegetables', 'Grains', 'Fruits'],
      'buyers': 340,
      'rating': 4.7,
      'icon': Icons.store_rounded,
    },
    {
      'id': 2,
      'name': 'Gikomba Market',
      'location': 'Gikomba',
      'distance': '3.4 km',
      'type': 'Wholesale',
      'status': 'busy',
      'hours': '6:00 AM – 8:00 PM',
      'products': ['Cereals', 'Pulses', 'Potatoes'],
      'buyers': 510,
      'rating': 4.5,
      'icon': Icons.local_shipping_rounded,
    },
    {
      'id': 3,
      'name': 'Organic Growers Hub',
      'location': 'Kilimani',
      'distance': '5.0 km',
      'type': 'Organic',
      'status': 'open',
      'hours': '7:00 AM – 4:00 PM',
      'products': ['Organic Veg', 'Herbs', 'Honey'],
      'buyers': 120,
      'rating': 4.9,
      'icon': Icons.eco_rounded,
    },
    {
      'id': 4,
      'name': 'City Park Retail Market',
      'location': 'Ngara',
      'distance': '1.8 km',
      'type': 'Retail',
      'status': 'open',
      'hours': '8:00 AM – 7:00 PM',
      'products': ['Fruits', 'Vegetables', 'Eggs'],
      'buyers': 230,
      'rating': 4.3,
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'id': 5,
      'name': 'Kenya Export Market',
      'location': 'Industrial Area',
      'distance': '8.2 km',
      'type': 'Export',
      'status': 'open',
      'hours': '6:00 AM – 5:00 PM',
      'products': ['Cut Flowers', 'French Beans', 'Avocado'],
      'buyers': 85,
      'rating': 4.8,
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'id': 6,
      'name': 'Kangemi Retail Hub',
      'location': 'Kangemi',
      'distance': '6.7 km',
      'type': 'Retail',
      'status': 'closed',
      'hours': 'Opens at 7:00 AM',
      'products': ['Maize', 'Beans', 'Kale'],
      'buyers': 180,
      'rating': 4.1,
      'icon': Icons.local_grocery_store_rounded,
    },
  ];

  final List<String> _filters = ['All', 'Wholesale', 'Retail', 'Organic', 'Export'];
  String _activeFilter = 'All';
  int? _selectedId;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ══════════════════════════════════════════════════════════
  // COMPUTED
  // ══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> get _filteredMarkets {
    List<Map<String, dynamic>> result = _markets;

    if (_activeFilter != 'All') {
      result = result.where((m) => m['type'] == _activeFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((m) {
        final products = (m['products'] as List<String>).join(' ').toLowerCase();
        return m['name'].toString().toLowerCase().contains(q) ||
            m['location'].toString().toLowerCase().contains(q) ||
            products.contains(q);
      }).toList();
    }

    return result;
  }

  Map<String, dynamic>? get _selectedMarket =>
      _selectedId == null ? null : _markets.firstWhere((m) => m['id'] == _selectedId);

  // ══════════════════════════════════════════════════════════
  // SEARCH HELPERS
  // ══════════════════════════════════════════════════════════
  void _startSearch() {
    setState(() => _isSearching = true);
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(colors),
                _buildFilterBar(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _buildList(colors),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _buildBottomBar(colors),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: context.appColors.cardBackground,
      child: Row(
        children: [
          _circleButton(
            Icons.arrow_back_ios_new_rounded,
            () => _isSearching ? _stopSearch() : Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          if (!_isSearching)
            Expanded(
              child: Text(
                'Markets Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 15, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search markets, produce...',
                  hintStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          if (_isSearching && _searchQuery.isNotEmpty)
            _circleButton(Icons.close_rounded, () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _searchFocusNode.requestFocus();
            }),
          if (!_isSearching) _circleButton(Icons.search_rounded, _startSearch),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.appColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: context.appColors.textPrimary),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FILTER BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildFilterBar() {
    return Container(
      color: context.appColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isActive = f == _activeFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2D7A3A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? const Color(0xFF2D7A3A) : context.appColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LIST
  // ══════════════════════════════════════════════════════════
  Widget _buildList(AppColors colors) {
    final items = _filteredMarkets;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: context.appColors.textHint),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No markets found for "$_searchQuery"'
                  : 'No markets in this category',
              style: TextStyle(fontSize: 14, color: context.appColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        _selectedId != null ? 100 : 20,
      ),
      itemCount: items.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              '${items.length} market${items.length == 1 ? '' : 's'} available',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          );
        }
        return _buildMarketCard(items[i - 1], colors);
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // MARKET CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildMarketCard(Map<String, dynamic> market, AppColors colors) {
    final isSelected = market['id'] == _selectedId;
    final status = market['status'] as String;
    final products = market['products'] as List<String>;

    return GestureDetector(
      onTap: () => setState(() => _selectedId = market['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D7A3A) : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.appColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    market['icon'] as IconData,
                    size: 26,
                    color: context.appColors.brandText,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        market['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: context.appColors.textHint),
                          const SizedBox(width: 2),
                          Text(
                            '${market['location']}  ·  ${market['distance']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusBadge(status),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          market['rating'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: context.appColors.divider),
            ),

            // ── Meta row ─────────────────────────────────────
            Row(
              children: [
                _metaItem(Icons.access_time_rounded, market['hours'] as String),
                const SizedBox(width: 16),
                _metaItem(
                  Icons.people_alt_rounded,
                  '${market['buyers']} buyers',
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Product tags ──────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: products
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.appColors.border, width: 0.5),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                            fontSize: 11.5, color: context.appColors.textSecondary),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 12),

            // ── Action button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(
                  () => _selectedId = isSelected ? null : market['id'],
                ),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? context.appColors.brandSoft
                      : const Color(0xFF2D7A3A),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 16,
                      color: isSelected
                          ? context.appColors.brandText
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSelected ? 'Selected — Tap to Remove' : 'Sell Here',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.appColors.brandText
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    String label;

    switch (status) {
      case 'open':
        bg = context.appColors.brandSoft;
        fg = context.appColors.brandText;
        label = 'Open';
        break;
      case 'busy':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        label = 'Busy';
        break;
      default:
        bg = const Color(0xFFFBE9E7);
        fg = const Color(0xFFBF360C);
        label = 'Closed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appColors.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.appColors.textHint),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomBar(AppColors colors) {
    final market = _selectedMarket;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: market != null ? 90 : 0,
      child: market == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected: ${market['name']}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.send_rounded, size: 17),
                      label: const Text('Confirm Market'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7A3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmSelection() {
    final market = _selectedMarket;
    if (market == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Listed at ${market['name']}!'),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}