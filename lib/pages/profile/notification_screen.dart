import 'package:flutter/material.dart';
import 'profile_service.dart';

// --- Notification Model (Matches your API JSON) ---
class NotificationPrefs {
  final int id;
  bool lowStockAlerts;
  bool leaveRequests;
  bool paymentReminders;
  bool healthReminders;
  bool systemUpdates;

  NotificationPrefs({
    required this.id,
    required this.lowStockAlerts,
    required this.leaveRequests,
    required this.paymentReminders,
    required this.healthReminders,
    required this.systemUpdates,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      id: json['id'] ?? 0,
      lowStockAlerts: json['low_stock_alerts'] ?? false,
      leaveRequests: json['leave_requests'] ?? false,
      paymentReminders: json['payment_reminders'] ?? false,
      healthReminders: json['health_reminders'] ?? false,
      systemUpdates: json['system_updates'] ?? false,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationPrefs? _prefs;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // --- Logic: Fetching from API ---
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final response = await ProfileService.setNotification();
      
      if (response.success && response.data != null) {
        // Correctly accessing the nested 'data' object from your API response
        final rawData = response.data['data'];
        setState(() {
          _prefs = NotificationPrefs.fromJson(rawData);
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError("Connection error");
    }
  }

  // --- Logic: Updating API ---
  Future<void> _updatePref(String type, bool value) async {
    if (_prefs == null) return;

    setState(() {
      if (type == 'low') _prefs!.lowStockAlerts = value;
      if (type == 'leave') _prefs!.leaveRequests = value;
      if (type == 'payment') _prefs!.paymentReminders = value;
      if (type == 'health') _prefs!.healthReminders = value;
      if (type == 'system') _prefs!.systemUpdates = value;
      _isSaving = true;
    });

    try {
      await ProfileService.updateNotification(
        lowStockAlerts: _prefs!.lowStockAlerts,
        leaveRequests: _prefs!.leaveRequests,
        paymentReminders: _prefs!.paymentReminders,
        healthReminders: _prefs!.healthReminders,
        systemUpdates: _prefs!.systemUpdates,
      );
    } catch (e) {
      _handleError("Save error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : Column(
            children: [
              if (_isSaving) const LinearProgressIndicator(color: Colors.black, backgroundColor: Colors.white, minHeight: 2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tell us the types of push notifications you would like to get on this device. You can change this at any time.',
                      style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildToggleRow(
                      title: 'Add a Contribution',
                      subtitle: "As a valued member of our travel community, we'll occasionally invite you to contribute your experiences.",
                      value: _prefs!.lowStockAlerts,
                      onChanged: (val) => _updatePref('low', val),
                    ),
                    _buildToggleRow(
                      title: 'Question Updates',
                      subtitle: 'Get notified when a traveller answers your question.',
                      value: _prefs!.leaveRequests,
                      onChanged: (val) => _updatePref('leave', val),
                    ),
                    _buildToggleRow(
                      title: 'Location-based Notifcations',
                      subtitle: 'Get tips and helpful information on places you visit.',
                      value: _prefs!.healthReminders,
                      onChanged: (val) => _updatePref('health', val),
                    ),
                    _buildToggleRow(
                      title: 'Price Drops & Booking Reminders',
                      subtitle: "Don't miss a price reduction or forget about booking your perfect trip.",
                      value: _prefs!.systemUpdates,
                      onChanged: (val) => _updatePref('system', val),
                    ),
                    _buildToggleRow(
                      title: 'Message and Booking Updates',
                      subtitle: 'Receive notifications when an owner sends you a message or there are requests.',
                      value: _prefs!.paymentReminders,
                      onChanged: (val) => _updatePref('payment', val),
                    ),
                    
                    // --- Master Mute Switch ---
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFF2F2F2), width: 10))
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Do not receive any notifications',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: false, // You can add logic here to turn everything off
                            onChanged: (val) {},
                            activeColor: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.black,
                activeTrackColor: Colors.black,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, "Explore", true),
          _navItem(Icons.search, "Search", false),
          _navItem(Icons.favorite_border, "Plan", false),
          _navItem(Icons.edit_outlined, "Review", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (active) Container(height: 3, width: 35, color: const Color(0xFF34E0A1)),
        const SizedBox(height: 6),
        Icon(icon, color: active ? Colors.black : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black : Colors.grey)),
      ],
    );
  }
}