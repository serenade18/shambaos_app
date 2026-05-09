import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_colors.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  final List<Map<String, String>> animals = [
    {
      'title': 'Maize',
      'subtitle': 'Manage your maize',
      'image': 'images/assets/icons/corn.png',
    },
    {
      'title': 'Beans',
      'subtitle': 'Manage your beans',
      'image': 'images/assets/icons/beans.png',
    },
    {
      'title': 'Bananas',
      'subtitle': 'Manage your bananas',
      'image': 'images/assets/icons/banana.png',
    },
    {
      'title': 'Avocados',
      'subtitle': 'Manage your avocados',
      'image': 'images/assets/icons/avocado.png',
    },
    {
      'title': 'Rice',
      'subtitle': 'Manage your rice',
      'image': 'images/assets/icons/rice.png',
    },
    {
      'title': 'Wheat',
      'subtitle': 'Manage your wheat',
      'image': 'images/assets/icons/wheat.png',
    },
    {
      'title': 'Tomatoes',
      'subtitle': 'Manage your tomatoes',
      'image': 'images/assets/icons/tomato.png',
    },
    {
      'title': 'Spinach',
      'subtitle': 'Manage your spinach',
      'image': 'images/assets/icons/spinach.png',
    },
    {
      'title': 'Sukuma (Kales)',
      'subtitle': 'Manage your kales',
      'image': 'images/assets/icons/kale.png',
    },
  ];

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, String>> get _filteredAnimals {
    if (_searchQuery.isEmpty) return animals;
    final query = _searchQuery.toLowerCase();
    return animals.where((item) {
      return item['title']!.toLowerCase().contains(query) ||
          item['subtitle']!.toLowerCase().contains(query);
    }).toList();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    // Delay focus to allow the widget to build first
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(child: _buildList(colors)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _circleButton(Icons.arrow_back_ios_new, () {
                if (_isSearching) {
                  _stopSearch();
                } else {
                  Navigator.pop(context);
                }
              }),
              const SizedBox(width: 12),
              if (!_isSearching)
                Expanded(
                  child: Text(
                    'Plant Husbandry',
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
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search plants...',
                      hintStyle: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              if (_isSearching && _searchQuery.isNotEmpty)
                _circleButton(Icons.close, () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _searchFocusNode.requestFocus();
                }),
              if (!_isSearching)
                _circleButton(Icons.search, _startSearch),
            ],
          ),
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
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6FA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LIST VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildList(AppColors colors) {
    final items = _filteredAnimals;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 12),
            Text(
              'No plants found for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    item['image']!,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightText(
                      item['title']!,
                      _searchQuery,
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle']!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFBBBBBB),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // HIGHLIGHT MATCHING TEXT
  // ══════════════════════════════════════════════════════════
  Widget _highlightText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: baseStyle.copyWith(
              color: const Color(0xFF4CAF50),
              backgroundColor: const Color(0xFFE8F5E9),
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }
}