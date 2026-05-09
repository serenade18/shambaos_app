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
            'Plant Husbandry',
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