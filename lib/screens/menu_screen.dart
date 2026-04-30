import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_colors.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      // ── AppBar — white, dark text, green back arrow ──────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        title: const Text(
          'App Menu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2E7D32), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'Animal Management',
              items: [
                _MenuItem(Icons.dashboard_outlined, 'Dashboard'),
                _MenuItem(Icons.pets_outlined, 'Animal Husbandry'),
                _MenuItem(Icons.grass_outlined, 'Plant Husbandry'),
                _MenuItem(Icons.inventory_2_outlined, 'Inventory'),
                _MenuItem(Icons.thermostat_outlined, 'Weather'),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Sales & Operations',
              items: [
                _MenuItem(Icons.monetization_on_outlined, 'Sales & Revenue'),
                _MenuItem(Icons.people_outline, 'Customers'),
                _MenuItem(Icons.shopping_cart_outlined, 'Procurement'),
                _MenuItem(Icons.receipt_long_outlined, 'Payments'),
                _MenuItem(Icons.analytics_outlined, 'Analytics'),
              ],
            ),
            const SizedBox(height: 20),
            _buildExpandableSection(
              context,
              title: 'Team & Settings',
              icon: Icons.settings_outlined,
              children: [
                _ListTileItem(Icons.person_outline, 'Profile Settings'),
                _ListTileItem(Icons.admin_panel_settings_outlined, 'Roles'),
                _ListTileItem(Icons.key_outlined, 'API Keys'),
                _ListTileItem(Icons.group_outlined, 'Team Personnel'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Section with grid of icon tiles ──────────────────────
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.1,
            ),
          ),
        ),

        // Card container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        items[index].icon,
                        color: const Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      items[index].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Expandable settings section ───────────────────────────
  Widget _buildExpandableSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
              ),
              title: const Text(
                'Team & Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              iconColor: const Color(0xFF4CAF50),
              collapsedIconColor: const Color(0xFFAAAAAA),
              children: [
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                ...children,
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  _MenuItem(this.icon, this.label);
}

class _ListTileItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ListTileItem(this.icon, this.title);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Color(0xFFCCCCCC),
      ),
      onTap: () {},
    );
  }
}