import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../dashboard/dashboard_service.dart';
import '../home_service.dart';
import '../profile/notification_screen.dart';
import '../../l10n/tr.dart';

/// The farm's alerts: GET /alerts?farm_id= (open and seen, newest first), and
/// POST /alerts/{id}/seen for the ones the farmer has now looked at.
class AlertsService {
  static Future<({List<Map<String, dynamic>>? alerts, bool noFarm, String? error})> load() async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return (alerts: null, noFarm: true, error: null);
    final res = await ApiService.get('/alerts?farm_id=${farms.first['id']}', requiresAuth: true);
    if (res.error || res.data is! Map) {
      return (alerts: null, noFarm: false, error: res.message ?? 'Check your connection and try again.'.tr);
    }
    final rows = (res.data['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (alerts: rows, noFarm: false, error: null);
  }

  static Future<void> markSeen(String id) => ApiService.post('/alerts/$id/seen', {}, requiresAuth: true);

  /// The icon and colour for an alert, as on Activity.
  static (IconData, SlStatus) look(Map<String, dynamic> a) {
    final critical = a['severity'] == 'critical';
    return switch (a['type']) {
      'heavy_rain' => (PhosphorIconsRegular.cloudRain, SlStatus.info),
      'vaccination_due' => (PhosphorIconsRegular.syringe, critical ? SlStatus.danger : SlStatus.warn),
      'breeding_due' => (PhosphorIconsRegular.heart, critical ? SlStatus.danger : SlStatus.warn),
      'crop_stress' => (PhosphorIconsRegular.plant, SlStatus.warn),
      'low_stock' => (PhosphorIconsRegular.package, critical ? SlStatus.danger : SlStatus.warn),
      'negative_stock' => (PhosphorIconsRegular.package, SlStatus.danger),
      'overdue_debt' => (PhosphorIconsRegular.coins, SlStatus.warn),
      _ => (PhosphorIconsRegular.bell, critical ? SlStatus.danger : SlStatus.warn),
    };
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const _sliders = '<path d="M20 7h-9"/><path d="M14 17H5"/><circle cx="17" cy="17" r="3"/><circle cx="7" cy="7" r="3"/>';

  List<Map<String, dynamic>>? _alerts;
  NotificationPrefs? _prefs;
  bool _noFarm = false;
  String? _error;
  bool _loading = true;
  String _currency = 'KES';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (r, prefs, currency) = await (AlertsService.load(), NotificationPrefs.load(), ApiService.getOrgCurrency()).wait;
    if (!mounted) return;
    setState(() {
      _alerts = r.alerts;
      _noFarm = r.noFarm;
      _error = r.error;
      _prefs = prefs;
      _currency = currency;
      _loading = false;
    });
    // Opening the list counts as seeing what is new in it.
    for (final a in r.alerts ?? const <Map<String, dynamic>>[]) {
      if (a['status'] == 'open' && prefs.allows(a['type'])) AlertsService.markSeen('${a['id']}');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
    final prefs = await NotificationPrefs.load();
    if (mounted) setState(() => _prefs = prefs);
  }

  String _when(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (d == null) return '';
    final days = DateTime.now().difference(d).inDays;
    if (days == 0) return 'Today'.tr;
    if (days == 1) return 'Yesterday'.tr;
    return DateFormat('EEE d MMM', Localizations.localeOf(context).toString()).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final prefs = _prefs;
    final all = _alerts;
    final shown = all == null || prefs == null ? null : all.where((a) => prefs.allows(a['type'])).toList();
    final hidden = all == null || shown == null ? 0 : all.length - shown.length;

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Row(children: [
                _round(c, Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary), 'Back'.tr, () => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Alerts'.tr,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                ),
                _round(c, LineIcon(_sliders, size: 22, color: c.textPrimary), 'Notifications'.tr, _openSettings),
              ]),
              const SizedBox(height: 16),
              if (_loading && all == null)
                Padding(padding: const EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator(color: c.shamba)))
              else if (_noFarm)
                SlLedger(children: [SlLedgerRow(title: 'No farm yet'.tr, meta: 'Set up your farm to see its alerts here.'.tr)])
              else if (all == null)
                SlLedger(children: [
                  SlLedgerRow(
                    title: 'Could not load your alerts'.tr,
                    meta: _error,
                    status: TextButton(onPressed: _load, child: Text('Try again'.tr)),
                  ),
                ])
              else ...[
                if (prefs!.muteAll)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SlLedger(children: [
                      SlLedgerRow(
                        title: 'Notifications are muted'.tr,
                        meta: 'Turn them back on in Notifications.'.tr,
                        status: TextButton(onPressed: _openSettings, child: Text('Change'.tr)),
                      ),
                    ]),
                  ),
                SlLedger(
                  title: 'Needs you'.tr,
                  trailing: SlEyebrow(shown!.length == 1 ? '1 alert'.tr : '{n} alerts'.trArgs({'n': shown.length})),
                  children: [
                    if (shown.isEmpty)
                      SlLedgerRow(title: 'Nothing needs you today'.tr, meta: 'Alerts about weather, vaccinations and stock show here.'.tr),
                    for (final a in shown)
                      () {
                        final (icon, status) = AlertsService.look(a);
                        return SlAlertRow(
                          icon: icon,
                          status: status,
                          text: DashboardService.alertText(a, _currency),
                          tag: a['status'] == 'open'
                              ? SlTag('New'.tr, tone: SlTone.info)
                              : Text(_when(a['created_at']), style: AppType.caption.copyWith(color: c.textSecondary)),
                        );
                      }(),
                  ],
                ),
                if (hidden > 0 && !prefs.muteAll)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                    child: Text(
                        (hidden == 1 ? '1 alert is hidden by your notification choices.'.tr : '{n} alerts are hidden by your notification choices.'.trArgs({'n': hidden})),
                        style: AppType.caption.copyWith(color: c.textSecondary)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(AppColors c, Widget icon, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
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
              onTap: onTap,
              child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
            ),
          ),
        ),
      );
}
