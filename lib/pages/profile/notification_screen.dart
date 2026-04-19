import 'package:flutter/material.dart';
import 'profile_service.dart';

// ===============================
// MODEL
// ===============================
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

// ===============================
// CONFIG (UI mapping layer)
// ===============================
class NotificationItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? badge;

  NotificationItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.badge,
  });
}

final List<NotificationItem> notificationItems = [
  NotificationItem(
    key: 'low_stock_alerts',
    title: 'Low Stock Alerts',
    subtitle:
        'Get notified when inventory drops below the configured threshold.',
    icon: Icons.inventory_2_rounded,
    iconColor: Color(0xFFB45309),
    iconBackground: Color(0xFFFFF4E0),
    badge: 'STOCK',
  ),
  NotificationItem(
    key: 'leave_requests',
    title: 'Leave Requests',
    subtitle: 'Alerts when staff submit leave requests requiring approval.',
    icon: Icons.badge_rounded,
    iconColor: Color(0xFF1A56DB),
    iconBackground: Color(0xFFE8F0FE),
  ),
  NotificationItem(
    key: 'health_reminders',
    title: 'Health & Vaccination',
    subtitle:
        'Scheduled health checks, vaccinations, and compliance reminders.',
    icon: Icons.favorite_rounded,
    iconColor: Color(0xFFDC2626),
    iconBackground: Color(0xFFFDEAEA),
  ),
  NotificationItem(
    key: 'system_updates',
    title: 'System Updates',
    subtitle: 'Platform updates, new features, and maintenance announcements.',
    icon: Icons.notifications_rounded,
    iconColor: Color(0xFF7C3AED),
    iconBackground: Color(0xFFF0EEFF),
  ),
  NotificationItem(
    key: 'payment_reminders',
    title: 'Payment Reminders',
    subtitle: 'Pending payments, due invoices, and financial actions.',
    icon: Icons.credit_card_rounded,
    iconColor: Color(0xFF109641),
    iconBackground: Color(0xFFE8F7EE),
  ),
];

// ===============================
// THEME CONSTANTS
// ===============================
const _kGreen = Color(0xFF109641);
const _kGreenLight = Color(0xFFE8F7EE);

// ===============================
// SCREEN
// ===============================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationPrefs? _prefs;
  bool _isLoading = true;

  /// Tracks which key is currently being saved.
  /// The toggle for that row is disabled until the request completes.
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ===============================
  // LOAD
  // ===============================
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final response = await ProfileService.setNotification();

      if (response.success && response.data != null) {
        setState(() {
          _prefs = NotificationPrefs.fromJson(response.data['data']);
          _isLoading = false;
        });
      } else {
        _handleError('Failed to load notifications');
      }
    } catch (_) {
      _handleError('Connection error');
    }
  }

  // ===============================
  // PATCH — sends only the changed key
  // Payload example: { "leave_requests": true }
  // ===============================
  Future<void> _updatePref(String key, bool value) async {
    if (_prefs == null || _savingKey != null) return;

    // 1. Optimistic local update so the toggle feels instant
    _applyLocal(key, value);
    setState(() => _savingKey = key);

    try {
      final response = await ProfileService.patchNotification(key, value);

      if (response.success && response.data != null) {
        // 2. Sync all fields from server response to stay consistent
        setState(() {
          _prefs = NotificationPrefs.fromJson(response.data['data']);
        });
      } else {
        // 3. Revert on API error
        _applyLocal(key, !value);
        _handleError('Failed to save. Please try again.');
      }
    } catch (_) {
      // 4. Revert on network error
      _applyLocal(key, !value);
      _handleError('Connection error');
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  /// Applies a single boolean field change to local [_prefs].
  /// Used for both optimistic updates and reverts.
  void _applyLocal(String key, bool value) {
    if (_prefs == null) return;
    setState(() {
      switch (key) {
        case 'low_stock_alerts':
          _prefs!.lowStockAlerts = value;
          break;
        case 'leave_requests':
          _prefs!.leaveRequests = value;
          break;
        case 'payment_reminders':
          _prefs!.paymentReminders = value;
          break;
        case 'health_reminders':
          _prefs!.healthReminders = value;
          break;
        case 'system_updates':
          _prefs!.systemUpdates = value;
          break;
      }
    });
  }

  void _handleError(String message) {
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : Column(
              children: [
                // Thin progress bar shown while any key is saving
                if (_savingKey != null)
                  LinearProgressIndicator(
                    color: _kGreen,
                    backgroundColor: _kGreenLight,
                    minHeight: 3,
                  ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      const SizedBox(height: 4),

                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0D0D),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                          children: [
                            TextSpan(text: 'Notifications'),
                            TextSpan(
                              text: '',
                              style: TextStyle(color: _kGreen),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Control the types of alerts you receive across your workspace.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ...notificationItems.map((item) {
                        return _buildToggleRow(
                          item: item,
                          value: _getValue(item.key),
                          isSaving: _savingKey == item.key,
                        );
                      }),

                      const SizedBox(height: 12),

                      // Master mute
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Color(0xFFF0F0F0), width: 8),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_off_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mute all notifications',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Silence everything at once',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAAAAAA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: false,
                              onChanged: (val) {},
                              activeColor: Colors.white,
                              activeTrackColor: _kGreen,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFE0E0E0),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ===============================
  // GET VALUE MAPPER
  // ===============================
  bool _getValue(String key) {
    if (_prefs == null) return false;
    switch (key) {
      case 'low_stock_alerts':
        return _prefs!.lowStockAlerts;
      case 'leave_requests':
        return _prefs!.leaveRequests;
      case 'payment_reminders':
        return _prefs!.paymentReminders;
      case 'health_reminders':
        return _prefs!.healthReminders;
      case 'system_updates':
        return _prefs!.systemUpdates;
      default:
        return false;
    }
  }

  // ===============================
  // ROW WIDGET
  // ===============================
  Widget _buildToggleRow({
    required NotificationItem item,
    required bool value,
    required bool isSaving,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111111),
                          ),
                        ),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kGreenLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kGreen,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle is disabled while its request is in-flight
              Switch(
                value: value,
                onChanged:
                    isSaving ? null : (val) => _updatePref(item.key, val),
                activeColor: Colors.white,
                activeTrackColor: _kGreen,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
      ],
    );
  }
}