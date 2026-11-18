import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../../l10n/tr.dart';

/// Which of the farm's alerts this phone shows. The API has no notification
/// settings: alerts come from GET /alerts, and these choices are kept on the
/// phone, as the design says ("on this phone").
class NotificationPrefs {
  static const _mute = 'notify_mute_all';
  static String _key(String group) => 'notify_$group';

  /// The alert groups a farmer can turn off, and the alert types in each.
  /// Leave requests and app updates have no alerts in the API yet; their
  /// choices are kept for when they do.
  static const groups = <String, List<String>>{
    'low_stock': ['low_stock', 'negative_stock'],
    'health': ['vaccination_due', 'breeding_due', 'mortality_spike'],
    'payments': ['overdue_debt'],
    'leave_requests': [],
    'app_updates': [],
  };

  /// On until turned off, except the two the design starts off.
  static const _offAtFirst = {'leave_requests', 'app_updates'};

  final bool muteAll;
  final Map<String, bool> on;

  const NotificationPrefs({required this.muteAll, required this.on});

  static Future<NotificationPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return NotificationPrefs(
      muteAll: p.getBool(_mute) ?? false,
      on: {for (final g in groups.keys) g: p.getBool(_key(g)) ?? !_offAtFirst.contains(g)},
    );
  }

  static Future<void> setMuteAll(bool value) async => (await SharedPreferences.getInstance()).setBool(_mute, value);
  static Future<void> setGroup(String group, bool value) async => (await SharedPreferences.getInstance()).setBool(_key(group), value);

  /// Whether an alert of [type] is shown. Types in no group (weather, crop
  /// health, records to review) are always shown unless everything is muted.
  bool allows(String? type) {
    if (muteAll) return false;
    for (final e in groups.entries) {
      if (e.value.contains(type)) return on[e.key] ?? true;
    }
    return true;
  }
}

/// The design's Notifications: mute everything, or choose the kinds of alert.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationPrefs? _prefs;

  static const _bellOff = '<path d="M8.7 3A6 6 0 0 1 18 8a21.3 21.3 0 0 0 .6 5"/><path d="M17 17H3s3-2 3-9a4.67 4.67 0 0 1 .3-1.7"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/><path d="m2 2 20 20"/>';
  static const _box = '<path d="M16 16h6"/><path d="M21 10V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l2-1.14"/><path d="m7.5 4.27 9 5.15"/><path d="M3.29 7 12 12l8.71-5"/><path d="M12 22V12"/>';
  static const _syringe = '<path d="m18 2 4 4"/><path d="m17 7 3-3"/><path d="M19 9 8.7 19.3c-1 1-2.5 1-3.4 0l-.6-.6c-1-1-1-2.5 0-3.4L15 5"/><path d="m9 11 4 4"/><path d="m5 19-3 3"/><path d="m14 4 6 6"/>';
  static const _wallet = '<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"/><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/>';
  static const _calendar = '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>';
  static const _info = '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>';

  @override
  void initState() {
    super.initState();
    NotificationPrefs.load().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  Future<void> _mute(bool v) async {
    await NotificationPrefs.setMuteAll(v);
    final p = await NotificationPrefs.load();
    if (mounted) setState(() => _prefs = p);
  }

  Future<void> _group(String g, bool v) async {
    await NotificationPrefs.setGroup(g, v);
    final p = await NotificationPrefs.load();
    if (mounted) setState(() => _prefs = p);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final p = _prefs;
    final types = [
      ('low_stock', _box, SlTone.warn, 'Low stock'.tr, 'When feed or medicine runs low'.tr),
      ('health', _syringe, SlTone.info, 'Health and vaccination'.tr, 'Checks and vaccines that are due'.tr),
      ('payments', _wallet, SlTone.neutral, 'Payment reminders'.tr, 'Money owed to you and bills due'.tr),
      ('leave_requests', _calendar, SlTone.neutral, 'Leave requests'.tr, 'When staff ask for days off'.tr),
      ('app_updates', _info, SlTone.neutral, 'App updates'.tr, 'New features and maintenance'.tr),
    ];

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Row(children: [
              _backButton(context, c),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Notifications'.tr,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
              ),
            ]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Choose which alerts you get on this phone.'.tr,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 22 / 15, color: c.textSecondary)),
            ),
            const SizedBox(height: 16),
            if (p == null)
              Padding(padding: const EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator(color: c.shamba)))
            else ...[
              SlLedger(children: [
                SlIconRow(
                  icon: _bellOff,
                  tone: SlTone.danger,
                  title: 'Mute all notifications'.tr,
                  meta: 'Silence everything at once'.tr,
                  end: SlSwitch(value: p.muteAll, label: 'Mute all notifications'.tr, onChanged: _mute),
                ),
              ]),
              SlGroupLabel('Alert types'.tr),
              SlLedger(children: [
                for (final (i, (key, icon, tone, title, meta)) in types.indexed) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.divider),
                  SlIconRow(
                    icon: icon,
                    tone: tone,
                    title: title,
                    meta: meta,
                    // Muting everything wins; the choices stay as they were.
                    end: SlSwitch(value: !p.muteAll && p.on[key]!, label: title, onChanged: p.muteAll ? null : (v) => _group(key, v)),
                  ),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _backButton(BuildContext context, AppColors c) => Semantics(
      button: true,
      label: 'Back'.tr,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBackground,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.maybePop(context),
            child: SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
          ),
        ),
      ),
    );
