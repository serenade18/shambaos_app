import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Customers',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
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
                  return const Center(
                    child: Text(
                      'No customers found',
                      style: TextStyle(color: Color(0xFF777777)),
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search customers...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
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
        color: Colors.white,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                if (town.isNotEmpty)
                  Text(
                    town,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFCCCCCC),
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