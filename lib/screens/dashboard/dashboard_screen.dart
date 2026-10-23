import 'package:flutter/material.dart';

import '../farm/setup_farm_screen.dart';
import 'package:flutter/services.dart';
import '../../widgets/phosphor_icons.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../customers/customer_screen.dart';
import 'dashboard_service.dart';
import '../../l10n/tr.dart';

/// Activity, as the design draws it (GET /dashboard): profit over the chosen
/// days on a green band, money in and out, profit by field, what needs the
/// farmer, then money owed and the store.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _periods = [7, 30, 90];

  int _days = 30;
  bool _loading = true;
  DashboardResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await DashboardService.load(days: _days);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  String _periodLabel(int days) => 'Last {days} days'.trArgs({'days': days});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);
    final bottom = AppBottomNav.scrollPadding(context);

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      extendBody: true, // the page scrolls under the nav bar
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          backgroundColor: c.cardBackground,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 24, 16, bottom),
            children: [
              _bar(c),
              const SizedBox(height: 16),
              ..._body(c),
            ],
          ),
        ),
      ),
    );
  }

  // ── The title, and the period as a chip that opens the choices ──
  Widget _bar(AppColors c) {
    return Row(
      children: [
        Expanded(
          child: Text('Activity'.tr,
              style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
        ),
        if (_loading && _result != null) ...[
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba)),
          const SizedBox(width: 10),
        ],
        SlChip(_periodLabel(_days), selected: true, onTap: _pickPeriod),
      ],
    );
  }

  Future<void> _pickPeriod() async {
    final c = context.appColors;
    final days = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: c.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Show activity for'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in _periods) SlChip(_periodLabel(d), selected: d == _days, onTap: () => Navigator.pop(context, d)),
            ]),
          ]),
        ),
      ),
    );
    if (days == null || days == _days) return;
    setState(() => _days = days);
    _load();
  }

  List<Widget> _body(AppColors c) {
    if (_loading && _result == null) {
      return [Padding(padding: const EdgeInsets.only(top: 64), child: Center(child: CircularProgressIndicator(color: c.shamba)))];
    }
    final result = _result!;
    if (result.noFarm) {
      return [
        SlLedger(children: [
          SlLedgerRow(title: 'No farm yet'.tr, meta: 'Set up your farm to see its profit, alerts and stock here.'.tr, status: Icon(PhosphorIconsRegular.caretRight, size: 18, color: context.appColors.textSecondary), onTap: () => setUpFarm(context).then((made) {
                    if (made) _load();
                  })),
        ]),
      ];
    }
    if (result.data == null) {
      return [
        SlLedger(children: [
          SlLedgerRow(
            title: 'Could not load the dashboard'.tr,
            meta: result.error ?? 'Check your connection and try again.'.tr,
            status: TextButton(onPressed: _load, child: Text('Try again'.tr)),
          ),
        ]),
      ];
    }

    final d = result.data!;
    return [
      if (d.showsMoney) ...[
        _profit(d),
        const SizedBox(height: 12),
        _moneyInOut(c, d),
        const SizedBox(height: 12),
        _byField(d),
        const SizedBox(height: 12),
      ] else ...[
        SlLedger(children: [
          SlLedgerRow(
            title: 'Money is hidden'.tr,
            meta: "Only members who can see the farm's money see profit and debts.".tr,
          ),
        ]),
        const SizedBox(height: 12),
      ],
      _alerts(c, d),
      if (d.showsMoney) ...[
        const SizedBox(height: 12),
        _moneyOwed(d),
      ],
      const SizedBox(height: 12),
      _buildStock(c, d),
    ];
  }

  // ── Profit on the green band ──────────────────────────────────
  Widget _profit(DashboardData d) {
    final p = d.profit!;
    final profit = num.tryParse('${p['profit']}') ?? 0;
    final previous = num.tryParse('${p['previous_profit']}') ?? 0;
    final change = profit - previous;

    return SlKeyFigure(
      band: true,
      label: 'PROFIT · LAST {days} DAYS'.trArgs({'days': _days}),
      currency: DashboardService.symbol(d.currency),
      value: DashboardService.amount(profit),
      deltaUp: change == 0 ? null : change > 0,
      delta: change == 0
          ? 'The same'.tr
          : change > 0
              ? '{amount} more'.trArgs({'amount': DashboardService.money(change.abs(), d.currency)})
              : '{amount} less'.trArgs({'amount': DashboardService.money(change.abs(), d.currency)}),
      deltaRest: 'than the {days} days before'.trArgs({'days': _days}),
    );
  }

  // ── Money in and money out, side by side ──────────────────────
  Widget _moneyInOut(AppColors c, DashboardData d) {
    final p = d.profit!;
    return Row(children: [
      Expanded(child: _metric(c, 'Money in'.tr, p['revenue'], d.currency, tint: c.goodTint)),
      const SizedBox(width: 10),
      Expanded(child: _metric(c, 'Money out'.tr, p['cost'], d.currency)),
    ]);
  }

  Widget _metric(AppColors c, String label, dynamic value, String currency, {Color? tint}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ?? c.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: tint == null ? const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: DashboardService.amount(value),
                style: TextStyle(
                    fontFamily: AppType.text,
                    fontSize: 24,
                    height: 30 / 24,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            TextSpan(text: ' ${DashboardService.symbol(currency)}', style: AppType.caption.copyWith(color: c.textSecondary)),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  // ── Profit by field, closed by the whole farm ─────────────────
  Widget _byField(DashboardData d) {
    final rows = (d.profit!['enterprises'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final total = rows.where((e) => e['enterprise_id'] == null).toList();
    final parts = rows.where((e) => e['enterprise_id'] != null).toList();
    bool isLoss(Map e) => (num.tryParse('${e['profit']}') ?? 0) < 0;

    return SlLedger(
      title: 'Profit by field'.tr,
      trailing: SlEyebrow(_periodLabel(_days)),
      children: [
        if (parts.isEmpty) SlLedgerRow(title: 'No animals or crops yet'.tr),
        for (final e in parts)
          SlLedgerRow(
            title: e['name'] ?? '',
            meta: 'Sales {sales} · Costs {costs}'.trArgs({
              'sales': DashboardService.money(e['revenue'], d.currency),
              'costs': DashboardService.money(e['cost'], d.currency),
            }),
            figure: DashboardService.money(e['profit'], d.currency),
            loss: isLoss(e),
            status: isLoss(e) ? SlTag('Loss so far'.tr, tone: SlTone.danger, icon: _minusCircle) : null,
          ),
        for (final e in total)
          SlLedgerRow(
            title: 'Whole farm'.tr,
            figure: DashboardService.money(e['profit'], d.currency),
            loss: isLoss(e),
            total: true,
          ),
      ],
    );
  }

  static const _minusCircle = '<circle cx="12" cy="12" r="9"/><path d="M8 12h8"/>';

  // ── What needs the farmer ─────────────────────────────────────
  Widget _alerts(AppColors c, DashboardData d) {
    void customers() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
    void fields() => Navigator.pushNamed(context, '/fields');

    (IconData, SlStatus, Widget?, String?, VoidCallback?) look(Map<String, dynamic> a) {
      final critical = a['severity'] == 'critical';
      final p = Map<String, dynamic>.from(a['params'] ?? {});
      return switch (a['type']) {
        'heavy_rain' => (PhosphorIconsRegular.cloudRain, SlStatus.info, SlTag('Heavy rain'.tr, tone: SlTone.info), null, null),
        'vaccination_due' => (PhosphorIconsRegular.syringe, critical ? SlStatus.danger : SlStatus.warn,
            SlTag('Due'.tr, tone: critical ? SlTone.danger : SlTone.warn), 'See fields'.tr, fields),
        'breeding_due' => (PhosphorIconsRegular.heart, critical ? SlStatus.danger : SlStatus.warn, null, null, null),
        'crop_stress' => (PhosphorIconsRegular.plant, SlStatus.warn, null, 'See fields'.tr, fields),
        'low_stock' => (PhosphorIconsRegular.package, critical ? SlStatus.danger : SlStatus.warn,
            SlTag('Running low'.tr, tone: SlTone.warn), null, null),
        'negative_stock' => (PhosphorIconsRegular.package, SlStatus.danger, SlTag('Below zero'.tr, tone: SlTone.danger), null, null),
        'overdue_debt' => (PhosphorIconsRegular.coins, SlStatus.warn,
            p['days'] == null ? null : SlTag('{days} days'.trArgs({'days': p['days']}), tone: SlTone.warn), 'See customers'.tr, customers),
        _ => (PhosphorIconsRegular.bell, critical ? SlStatus.danger : SlStatus.warn, null, null, null),
      };
    }

    return SlLedger(
      title: 'Needs you'.tr,
      trailing: SlEyebrow(d.alerts.isEmpty
          ? 'All clear'.tr
          : d.alerts.length == 1
              ? '1 alert'.tr
              : '{n} alerts'.trArgs({'n': d.alerts.length})),
      children: [
        if (d.alerts.isEmpty)
          SlLedgerRow(title: 'Nothing needs you today'.tr, meta: 'Alerts about weather, vaccinations and stock show here.'.tr),
        for (final a in d.alerts.take(5))
          () {
            final (icon, status, tag, action, onAction) = look(a);
            return SlAlertRow(
              icon: icon,
              status: status,
              text: DashboardService.alertText(a, d.currency),
              tag: tag,
              actionLabel: action,
              onAction: onAction,
            );
          }(),
      ],
    );
  }

  // ── Money owed, both ways ─────────────────────────────────────
  Widget _moneyOwed(DashboardData d) {
    final r = d.receivables!;
    final pay = d.payables!;
    String? oldest(dynamic days, dynamic who) => days == null ? null : 'oldest {who}, {days} days'.trArgs({'who': who, 'days': days});

    return SlLedger(
      title: 'Money owed'.tr,
      trailing: SlEyebrow('Today'.tr),
      children: [
        SlLedgerRow(
          title: 'Customers owe you'.tr,
          meta: [(r['customers'] == 1 ? '{n} customer'.trArgs({'n': 1}) : '{n} customers'.trArgs({'n': r['customers']})), oldest(r['oldest_days'], r['oldest_customer'])]
              .whereType<String>()
              .join(' · '),
          figure: DashboardService.money(r['total'], d.currency),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())),
        ),
        SlLedgerRow(
          title: 'You owe suppliers'.tr,
          meta: [(pay['suppliers'] == 1 ? '{n} supplier'.trArgs({'n': 1}) : '{n} suppliers'.trArgs({'n': pay['suppliers']})), oldest(pay['oldest_days'], pay['oldest_supplier'])]
              .whereType<String>()
              .join(' · '),
          figure: DashboardService.money(pay['total'], d.currency),
        ),
      ],
    );
  }

  // ── Stock levels ────────────────────────────────────────────
  Widget _buildStock(AppColors c, DashboardData d) {
    return SlLedger(
      title: 'Stock in the store'.tr,
      trailing: SlEyebrow(d.stock.length == 1 ? '1 item'.tr : '{n} items'.trArgs({'n': d.stock.length})),
      children: [
        if (d.stock.isEmpty) SlLedgerRow(title: 'No stock recorded yet'.tr),
        for (final s in d.stock)
          SlLedgerRow(
            title: DashboardService.name(s['item_name']),
            meta: [
              if (s['location'] != null && '${s['location']}'.isNotEmpty) '${s['location']}',
              if (s['value'] != null) DashboardService.money(s['value'], d.currency),
            ].join(' · '),
            figure: _stockQty(s),
            unit: _stockUnit(s),
            loss: s['status'] == 'negative',
            status: switch (s['status']) {
              'negative' => SlStatusTag('Below zero'.tr, status: SlStatus.danger),
              'low' => SlStatusTag('Running low'.tr, status: SlStatus.warn, icon: PhosphorIconsBold.warning),
              _ => null,
            },
          ),
      ],
    );
  }

  num _stockAmount(Map<String, dynamic> s) {
    final base = num.tryParse('${s['qty_base']}') ?? 0;
    final factor = (s['display_factor'] as num?) ?? 1;
    return base / (factor == 0 ? 1 : factor);
  }

  /// Stock is counted in base units; show it in the item's display unit (bags, trays).
  String _stockQty(Map<String, dynamic> s) {
    final q = _stockAmount(s);
    return q < 0 ? '−${DashboardService.qty(q.abs())}' : DashboardService.qty(q);
  }

  /// Farmers count in trays and bags: plural unless exactly one.
  String _stockUnit(Map<String, dynamic> s) {
    final unit = '${s['display_unit'] ?? s['base_unit'] ?? ''}';
    final one = _stockAmount(s).abs() == 1;
    return one || unit.endsWith('s') || unit.length <= 2 ? unit : '${unit}s';
  }
}
