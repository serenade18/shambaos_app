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
      'subtitle': 'Managed milk production',
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
      child: Row(
        children: [
          _circleButton(Icons.arrow_back_ios_new, () {
            Navigator.pop(context);
          }),
          const SizedBox(width: 12),
          Text(
            'Animal Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          _circleButton(Icons.search, () {
            // TODO: search action
          }),
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
          color: const Color(0xFFF5F6FA),
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: animals.length,
      itemBuilder: (_, i) {
        final item = animals[i];

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
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    item['image']!,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets,
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
                    Text(
                      item['title']!,
                      style: TextStyle(
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
}