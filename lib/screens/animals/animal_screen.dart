import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_colors.dart';

class AnimalScreen extends StatefulWidget {
  const AnimalScreen({super.key});

  @override
  State<AnimalScreen> createState() => _AnimalScreenState();
}

class _AnimalScreenState extends State<AnimalScreen> {
  final List<Map<String, String>> animals = [
    {
      'title': 'Dairy Cow',
      'subtitle': 'Manage dairy cattle farming operations',
      'image': 'images/assets/icons/cow.png',
    },
    {
      'title': 'Goats',
      'subtitle': 'Manage goat farming operations',
      'image': 'images/assets/icons/goat.png',
    },
    {
      'title': 'Poultry',
      'subtitle': 'Manage egg & meat production',
      'image': 'images/assets/icons/chicken.png',
    },
    {
      'title': 'Rabbit Farming',
      'subtitle': 'Manage rabbit farming operations',
      'image': 'images/assets/icons/rabbit.png',
    },
    {
      'title': 'Pig Farming',
      'subtitle': 'Manage pig farming operations',
      'image': 'images/assets/icons/pig.png',
    },
    {
      'title': 'Fish Farming',
      'subtitle': 'Manage aquaculture operations',
      'image': 'images/assets/icons/fish.png',
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

    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
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
      color: context.appColors.cardBackground,
      child: Row(
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
                'Animal Husbandry',
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
                  hintText: 'Search animals...',
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
  // LIST VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildList(AppColors colors) {
    final items = _filteredAnimals;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'No animals found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textHint,
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
                decoration: BoxDecoration(
                  color: context.appColors.brandSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    item['image']!,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.pets,
                      color: context.appColors.brandText,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.appColors.textHint,
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
              color: context.appColors.brandText,
              backgroundColor: context.appColors.brandSoft,
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }
}