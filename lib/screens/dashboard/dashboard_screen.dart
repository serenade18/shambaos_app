import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../widgets/phosphor_icons.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import 'dashboard_service.dart';
import '../../l10n/tr.dart';

/// The farm at a glance (GET /dashboard): profit, money owed both ways, stock
/// bought, alerts, today's records and stock levels, kept as ledgers.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _periods = {7: '7 days', 30: '30 days', 90: '90 days'};

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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(AppColors c) {
    final data = _result?.data;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(color: c.cardBackground, border: Border(bottom: BorderSide(color: c.divider))),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back'.tr,
            onPressed: () => Navigator.pop(context),
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: c.textPrimary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard'.tr, style: AppType.titleL.copyWith(color: c.textPrimary)),
                if (data != null) Text(data.farmName, style: AppType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh'.tr,
            onPressed: _loading ? null : _load,
            icon: Icon(PhosphorIconsRegular.arrowClockwise, color: c.textPrimary),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════
  Widget _buildBody(AppColors c) {
    if (_loading && _result == null) {
      return Center(child: CircularProgressIndicator(color: c.shamba));
    }
    final result = _result!;
    if (result.noFarm) {
      return _message(c, PhosphorIconsRegular.barn, 'No farm yet'.tr,
          'Set up your farm to see its profit, alerts and stock here.'.tr);
    }
    if (result.data == null) {
      return _message(c, PhosphorIconsRegular.cloudSlash, 'Could not load the dashboard'.tr,
          result.error ?? 'Check your connection and try again.'.tr, retry: true);
    }

    final d = result.data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: c.shamba,
      backgroundColor: c.cardBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          _buildPeriodPicker(c, d),
          const SizedBox(height: 16),
          if (d.showsMoney) ...[
            _buildProfit(d),
            const SizedBox(height: 24),
            _buildMoneyOwed(c, d),
            const SizedBox(height: 24),
            if ((d.profit!['monthly'] as List?)?.isNotEmpty ?? false) ...[
              _buildMonthly(c, d),
              const SizedBox(height: 24),
            ],
            _buildEnterprises(d),
            const SizedBox(height: 24),
          ] else ...[
            SlLedger(children: [
              SlLedgerRow(
                title: 'Money is hidden'.tr,
                meta: "Only members who can see the farm's money see profit and debts.".tr,
              ),
            ]),
            const SizedBox(height: 24),
          ],
          _buildAlerts(c, d),
          const SizedBox(height: 24),
          _buildToday(c, d),
          const SizedBox(height: 24),
          _buildStock(c, d),
        ],
      ),
    );
  }

  Widget _message(AppColors c, IconData icon, String title, String body, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.textHint),
            const SizedBox(height: 12),
            Text(title, style: AppType.titleM.copyWith(color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: AppType.body.copyWith(color: c.textSecondary)),
            if (retry) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: Text('Try again'.tr)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Period ────────────────────────────────────────────────
  Widget _buildPeriodPicker(AppColors c, DashboardData d) {
    final range = '${DateFormat('d MMM').format(d.from)} – ${DateFormat('d MMM yyyy').format(d.to)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final e in _periods.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _days == e.key,
                side: BorderSide(color: _days == e.key ? c.brandText : c.border, width: 1.5),
                labelStyle: AppType.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _days == e.key ? c.brandText : c.textPrimary,
                ),
                onSelected: (_) {
                  setState(() => _days = e.key);
                  _load();
                },
              ),
            if (_loading)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba)),
          ],
        ),
        const SizedBox(height: 6),
        Text(range, style: AppType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }

  // ── Profit ────────────────────────────────────────────────
  Widget _buildProfit(DashboardData d) {
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

  // ── Money owed, both ways, and stock bought ───────────────
  Widget _buildMoneyOwed(AppColors c, DashboardData d) {
    final r = d.receivables!;
    final pay = d.payables!;
    final s = d.stockBought!;
    String? oldest(dynamic days, dynamic who) => days == null ? null : 'oldest {who}, {days} days'.trArgs({'who': who, 'days': days});
    final owedToSuppliers = (num.tryParse('${s['owed']}') ?? 0) > 0;

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
        ),
        SlLedgerRow(
          title: 'You owe suppliers'.tr,
          meta: [(pay['suppliers'] == 1 ? '{n} supplier'.trArgs({'n': 1}) : '{n} suppliers'.trArgs({'n': pay['suppliers']})), oldest(pay['oldest_days'], pay['oldest_supplier'])]
              .whereType<String>()
              .join(' · '),
          figure: DashboardService.money(pay['total'], d.currency),
        ),
        SlLedgerRow(
          title: 'Stock bought'.tr,
          meta: () {
            final a = {'n': s['purchases'], 'days': _days, 'amount': DashboardService.money(s['paid'], d.currency)};
            return s['purchases'] == 1
                ? '{n} purchase in the last {days} days · paid {amount}'.trArgs(a)
                : '{n} purchases in the last {days} days · paid {amount}'.trArgs(a);
          }(),
          figure: DashboardService.money(s['total'], d.currency),
          status: owedToSuppliers
              ? SlStatusTag('${DashboardService.money(s['owed'], d.currency)} owed', status: SlStatus.warn)
              : SlStatusTag('Paid'.tr, status: SlStatus.good),
        ),
      ],
    );
  }

  // ── Profit by month ─────────────────────────────────────────
  Widget _buildMonthly(AppColors c, DashboardData d) {
    final months = (d.profit!['monthly'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final values = months.map((m) => num.tryParse('${m['profit']}') ?? 0).toList();
    final peak = values.fold<num>(0, (a, v) => v.abs() > a ? v.abs() : a);

    return SlLedger(
      title: 'Profit by month'.tr,
      trailing: SlEyebrow(DashboardService.symbol(d.currency)),
      children: [
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(NumberFormat.compact().format(values[i]),
                            style: AppType.caption.copyWith(
                                fontSize: 11, color: values[i] < 0 ? c.dangerInk : c.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          height: peak == 0 ? 2 : 4 + 76 * values[i].abs() / peak,
                          decoration: BoxDecoration(
                            color: values[i] < 0 ? c.dangerInk : c.shamba,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(DateFormat('MMM').format(DateTime.parse('${months[i]['month']}-01')),
                            style: AppType.caption.copyWith(fontSize: 11, color: c.textHint)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Profit by enterprise ────────────────────────────────────
  Widget _buildEnterprises(DashboardData d) {
    final rows = (d.profit!['enterprises'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    // The whole-farm row is the sum, so it closes the ledger under a double rule.
    final total = rows.where((e) => e['enterprise_id'] == null).toList();
    final parts = rows.where((e) => e['enterprise_id'] != null).toList();
    bool isLoss(Map e) => (num.tryParse('${e['profit']}') ?? 0) < 0;

    return SlLedger(
      title: 'Profit by enterprise'.tr,
      trailing: SlEyebrow('Last {days} days'.trArgs({'days': _days})),
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
            status: isLoss(e) ? SlStatusTag('Loss so far'.tr, status: SlStatus.danger) : null,
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

  // ── Alerts ──────────────────────────────────────────────────
  Widget _buildAlerts(AppColors c, DashboardData d) {
    (IconData, SlStatus, String?) look(Map<String, dynamic> a) {
      final critical = a['severity'] == 'critical';
      return switch (a['type']) {
        'heavy_rain' => (PhosphorIconsRegular.cloudRain, SlStatus.info, 'See forecast'.tr),
        'vaccination_due' => (PhosphorIconsRegular.syringe, critical ? SlStatus.danger : SlStatus.warn, 'Record vaccination'.tr),
        'breeding_due' => (PhosphorIconsRegular.heart, critical ? SlStatus.danger : SlStatus.warn, null),
        'crop_stress' => (PhosphorIconsRegular.plant, SlStatus.warn, 'See field'.tr),
        'low_stock' || 'negative_stock' => (PhosphorIconsRegular.package, critical ? SlStatus.danger : SlStatus.warn, null),
        'overdue_debt' => (PhosphorIconsRegular.coins, SlStatus.warn, null),
        _ => (PhosphorIconsRegular.bell, critical ? SlStatus.danger : SlStatus.warn, null),
      };
    }

    return SlLedger(
      title: 'Needs you'.tr,
      trailing: SlEyebrow(d.alerts.isEmpty ? 'All clear'.tr : '${d.alerts.length} alerts'),
      children: [
        if (d.alerts.isEmpty)
          SlLedgerRow(
              title: 'Nothing needs you today'.tr, meta: 'Alerts about weather, vaccinations and stock show here.'.tr),
        for (final a in d.alerts.take(5))
          () {
            final (icon, status, action) = look(a);
            return SlAlertRow(
              icon: icon,
              status: status,
              text: DashboardService.alertText(a, d.currency),
              actionLabel: action,
              onAction: action == null ? null : () {},
            );
          }(),
      ],
    );
  }

  // ── Today's records ─────────────────────────────────────────
  Widget _buildToday(AppColors c, DashboardData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text("Today's records".tr, style: AppType.titleM.copyWith(color: c.textPrimary)),
        ),
        if (d.today.isEmpty) SlLedger(children: [SlLedgerRow(title: 'No animals or crops yet'.tr)]),
        for (final e in d.today) ...[
          SlEnterpriseTile(
            icon: SlEnterpriseTile.iconFor(e['type']),
            title: e['name'] ?? '',
            meta: '${e['type']}'.replaceAll('_', ' '),
            status: e['recorded'] == true
                ? SlStatusTag('Done'.tr, status: SlStatus.good)
                : SlStatusTag('Not recorded'.tr, status: SlStatus.warn),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ── Stock levels ────────────────────────────────────────────
  Widget _buildStock(AppColors c, DashboardData d) {
    return SlLedger(
      title: 'Stock in the store'.tr,
      trailing: SlEyebrow('${d.stock.length} items'),
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
