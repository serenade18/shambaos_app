import 'package:flutter/material.dart';
import 'profile_service.dart';

// --- Notification Model ---
class NotificationPrefs {
  final int id;
  bool lowStockAlerts; // Mapped to lowStockAlerts
  bool leaveRequests; // Mapped to leaveRequests
  bool healthReminders; // Mapped to healthReminders
  bool systemUpdates; // Mapped to systemUpdates

  NotificationPrefs({
    required this.id,
    required this.lowStockAlerts,
    required this.leaveRequests,
    required this.healthReminders,
    required this.systemUpdates,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      id: json['id'] ?? 0,
      lowStockAlerts: json['low_stock_alerts'] ?? false,
      leaveRequests: json['leave_requests'] ?? false,
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
        // Handling nested data structure commonly found in ApiResponses
        final Map<String, dynamic> rawData = response.data is Map && response.data.containsKey('data') 
            ? response.data['data'] 
            : response.data;

        setState(() {
          _prefs = NotificationPrefs.fromJson(rawData);
          _isLoading = false;
        });
      } else {
        _handleError("Failed to load settings");
      }
    } catch (e) {
      _handleError("Connection error");
    }
  }

  // --- Logic: Updating API ---
  Future<void> _savePreferences() async {
    if (_prefs == null) return;
    setState(() => _isSaving = true);

    try {
      final response = await ProfileService.updateNotification(
        lowStockAlerts: _prefs!.lowStockAlerts,
        leaveRequests: _prefs!.leaveRequests,
        paymentReminders: false, // Defaulting if not in current UI
        healthReminders: _prefs!.healthReminders,
        systemUpdates: _prefs!.systemUpdates,
      );

      if (!response.success) {
        _handleError("Update failed");
      }
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF9BCAFF)], // Screenshot Blue Gradient
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _buildWhiteCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect( // Ensures progress indicator respects corners
        borderRadius: BorderRadius.circular(30),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSaving) const LinearProgressIndicator(minHeight: 2),
              const Text(
                'Choose what brightens your day',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF0F0F0)),
              
              _buildToggleRow(
                title: 'Weekly Reminders',
                subtitle: 'Receive a summary of your personal progress and glowing achievements every Sunday.',
                value: _prefs!.lowStockAlerts,
                onChanged: (val) {
                  setState(() => _prefs!.lowStockAlerts = val);
                  _savePreferences();
                },
              ),
              _buildToggleRow(
                title: 'Motivation Messages',
                subtitle: 'Kind words and daily affirmations to keep your spirit high throughout the day.',
                value: _prefs!.leaveRequests,
                onChanged: (val) {
                  setState(() => _prefs!.leaveRequests = val);
                  _savePreferences();
                },
              ),
              _buildToggleRow(
                title: 'Wellness Check-ins',
                subtitle: 'Gentle nudges for mindful pauses, deep breathing, and self-care moments.',
                value: _prefs!.healthReminders,
                onChanged: (val) {
                  setState(() => _prefs!.healthReminders = val);
                  _savePreferences();
                },
              ),
              _buildToggleRow(
                title: 'Product Updates',
                subtitle: 'Be the first to hear about new features and improvements to your experience.',
                value: _prefs!.systemUpdates,
                isLast: true,
                onChanged: (val) {
                  setState(() => _prefs!.systemUpdates = val);
                  _savePreferences();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF4A90E2),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: Color(0xFFF0F0F0), thickness: 1),
      ],
    );
  }
}