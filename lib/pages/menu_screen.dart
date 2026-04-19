import 'package:flutter/material.dart';
import '../services/app_colors.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        elevation: 0,
        title: const Text(
          'App Menu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSection(
              context,
              title: "Farm Management",
              items: [
                _MenuItem(Icons.dashboard_outlined, "Dashboard"),
                _MenuItem(Icons.pets_outlined, "Animal Husbandry"),
                _MenuItem(Icons.grass_outlined, "Plant Husbandry"),
                _MenuItem(Icons.inventory_2_outlined, "Inventory"),
                _MenuItem(Icons.thermostat_outlined, "Weather"),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: "Sales & Operations",
              items: [
                _MenuItem(Icons.monetization_on_outlined, "Sales & Revenue"),
                _MenuItem(Icons.people_outline, "Customers"),
                _MenuItem(Icons.shopping_cart_outlined, "Procurement"),
                _MenuItem(Icons.receipt_long_outlined, "Payments"),
                _MenuItem(Icons.analytics_outlined, "Analytics"),
              ],
            ),
            const SizedBox(height: 20),
            _buildExpandableSection(
              context,
              title: "Team & Settings",
              icon: Icons.settings_outlined,
              children: [
                _ListTileItem(Icons.person_outline, "Profile Settings"),
                _ListTileItem(Icons.admin_panel_settings_outlined, "Roles"),
                _ListTileItem(Icons.key_outlined, "API Keys"),
                _ListTileItem(Icons.group_outlined, "Team Personnel"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<_MenuItem> items}) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(items[index].icon, color: AppColors.brand, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    items[index].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(BuildContext context,
      {required String title, required IconData icon, required List<Widget> children}) {
    final colors = context.appColors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: colors.textSecondary),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

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
    final colors = context.appColors;
    return ListTile(
      leading: Icon(icon, size: 20, color: colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: colors.textSecondary),
      ),
      onTap: () {},
    );
  }
}