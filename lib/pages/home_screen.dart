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
                        const SizedBox(height: 28),
                        _buildMyFieldsHeader(colors),
                        const SizedBox(height: 16),
                        _buildCategoryChips(colors),
                        const SizedBox(height: 20),
                        _buildFieldCards(colors),
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