import 'package:flutter/material.dart';
import '../../services/app_colors.dart';
import 'customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<dynamic>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _loadCustomers();
  }

  Future<List<dynamic>> _loadCustomers() async {
    final res = await CustomerService.getCustomers();

    if (!res.error && res.data != null) {
      return res.data;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        elevation: 0,
        leading: BackButton(color: context.appColors.textPrimary),
        title: Text(
          'Customers',
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _customersFuture,
              builder: (context, snapshot) {
                // ⏳ LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ❌ ERROR / EMPTY
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No customers found',
                      style: TextStyle(color: context.appColors.textSecondary),
                    ),
                  );
                }

                final customers = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return _buildCustomerTile(c);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 SEARCH UI (hook later to API filtering)
  Widget _buildSearch() {
    return Container(
      color: context.appColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.appColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search customers...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: context.appColors.brandText),
          ),
        ),
      ),
    );
  }

  // 📋 CUSTOMER TILE
  Widget _buildCustomerTile(Map<String, dynamic> customer) {
    final name = customer['name'] ?? 'No Name';
    final phone = customer['phone'] ?? '';
    final email = customer['email'] ?? '';
    final town = customer['town'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(name),
          const SizedBox(width: 12),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textHint,
                    ),
                  ),
                if (town.isNotEmpty)
                  Text(
                    town,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textHint,
                    ),
                  ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            color: context.appColors.textHint,
          ),
        ],
      ),
    );
  }

  // 🟢 AVATAR
  Widget _buildAvatar(String name) {
    final initials = _getInitials(name);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getColor(name),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getColor(String name) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }
}