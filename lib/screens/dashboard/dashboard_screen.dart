import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import 'dashboard_service.dart';

/// The farm at a glance (GET /dashboard): profit by enterprise, money owed both
/// ways, stock bought, alerts, today's records and stock levels.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _periods = {7: '7 days', 30: '30 days', 90: '90 days'};
  static const _red = Color(0xFFE53935);
  static const _amber = Color(0xFFF59E0B);

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
    final colors = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(AppColors colors) {
    final data = _result?.data;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: colors.cardBackground,
      child: Row(
        children: [
          _circleButton(colors, Icons.arrow_back_ios_new, () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                if (data != null)
                  Text(data.farmName, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
              ],
            ),
          ),
          _circleButton(colors, Icons.refresh_rounded, _load),
        ],
      ),
    );
  }

  Widget _circleButton(AppColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: colors.surfaceMuted, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BODY
  // ══════════════════════════════════════════════════════════
  Widget _buildBody(AppColors colors) {
    if (_loading && _result == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
    }
    final result = _result!;
    if (result.noFarm) {
      return _message(colors, Icons.agriculture_rounded, 'No farm yet',
          'Set up your farm to see its profit, alerts and stock here.');
    }
    if (result.data == null) {
      return _message(colors, Icons.cloud_off_rounded, 'Could not load the dashboard',
          result.error ?? 'Check your connection and try again.', retry: true);
    }

    final d = result.data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand,
      backgroundColor: colors.cardBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildPeriodPicker(colors, d),
          const SizedBox(height: 12),
          if (d.showsMoney) ...[
            _buildProfitCard(colors, d),
            const SizedBox(height: 12),
            _buildMoneyTiles(colors, d),
            const SizedBox(height: 12),
            if ((d.profit!['monthly'] as List?)?.isNotEmpty ?? false) ...[
              _buildMonthly(colors, d),
              const SizedBox(height: 12),
            ],
            _buildEnterprises(colors, d),
            const SizedBox(height: 12),
          ] else ...[
            _card(colors, child: Text('Money figures are only shown to members who can see the farm\'s money.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary))),
            const SizedBox(height: 12),
          ],
          _buildAlerts(colors, d),
          const SizedBox(height: 12),
          _buildToday(colors, d),
          const SizedBox(height: 12),
          _buildStock(colors, d),
        ],
      ),
    );
  }

  Widget _message(AppColors colors, IconData icon, String title, String body, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colors.textHint),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            if (retry) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }

  // ── Period ────────────────────────────────────────────────
  Widget _buildPeriodPicker(AppColors colors, DashboardData d) {
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
                showCheckmark: false,
                selectedColor: colors.brandSoft,
                backgroundColor: colors.cardBackground,
                side: BorderSide(color: _days == e.key ? AppColors.brand : colors.border),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _days == e.key ? colors.brandText : colors.textSecondary,
                ),
                onSelected: (_) {
                  setState(() => _days = e.key);
                  _load();
                },
              ),
            if (_loading)
              const SizedBox(
                  width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
          ],
        ),
        const SizedBox(height: 6),
        Text(range, style: TextStyle(fontSize: 11.5, color: colors.textHint)),
      ],
    );
  }

  // ── Profit ────────────────────────────────────────────────
  Widget _buildProfitCard(AppColors colors, DashboardData d) {
    final p = d.profit!;
    final profit = num.tryParse('${p['profit']}') ?? 0;
    final previous = num.tryParse('${p['previous_profit']}') ?? 0;
    final change = profit - previous;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D5A27), Color(0xFF109641)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(DashboardService.money(profit, d.currency),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            change == 0
                ? 'Same as the previous $_days days'
                : '${DashboardService.money(change, d.currency, signed: true)} vs the previous $_days days',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _profitStat('Revenue', DashboardService.money(p['revenue'], d.currency)),
              const SizedBox(width: 12),
              _profitStat('Costs', DashboardService.money(p['cost'], d.currency)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profitStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── Customers owe, owed to suppliers, stock bought ───────────
  Widget _buildMoneyTiles(AppColors colors, DashboardData d) {
    final r = d.receivables!;
    final pay = d.payables!;
    final s = d.stockBought!;
    String oldest(dynamic days, dynamic who) =>
        days == null ? 'Nothing outstanding' : 'Oldest: $who, $days days';

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile(colors, Icons.call_received_rounded, AppColors.brand, 'Customers owe you',
                DashboardService.money(r['total'], d.currency),
                '${r['customers']} customer${r['customers'] == 1 ? '' : 's'}\n${oldest(r['oldest_days'], r['oldest_customer'])}'),
            const SizedBox(width: 12),
            _tile(colors, Icons.call_made_rounded, _red, 'You owe suppliers',
                DashboardService.money(pay['total'], d.currency),
                '${pay['suppliers']} supplier${pay['suppliers'] == 1 ? '' : 's'}\n${oldest(pay['oldest_days'], pay['oldest_supplier'])}'),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          colors,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconBadge(Icons.shopping_basket_rounded, const Color(0xFF1565C0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock bought', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                    Text(DashboardService.money(s['total'], d.currency),
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    Text('${s['purchases']} purchase${s['purchases'] == 1 ? '' : 's'} in this period',
                        style: TextStyle(fontSize: 11.5, color: colors.textHint)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill('Paid ${DashboardService.money(s['paid'], d.currency)}', colors.brandText),
                        _pill('Owed ${DashboardService.money(s['owed'], d.currency)}', _red),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(AppColors colors, IconData icon, Color accent, String label, String value, String note) {
    return Expanded(
      child: _card(
        colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBadge(icon, accent),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text(note, style: TextStyle(fontSize: 11.5, color: colors.textHint, height: 1.35)),
          ],
        ),
      ),
    );
  }

  // ── Profit by month ─────────────────────────────────────────
  Widget _buildMonthly(AppColors colors, DashboardData d) {
    final months = (d.profit!['monthly'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final values = months.map((m) => num.tryParse('${m['profit']}') ?? 0).toList();
    final peak = values.fold<num>(0, (a, v) => v.abs() > a ? v.abs() : a);

    return _section(
      colors,
      'Profit by month',
      SizedBox(
        height: 130,
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
                          style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        height: peak == 0 ? 2 : 4 + 80 * values[i].abs() / peak,
                        decoration: BoxDecoration(
                          color: values[i] < 0 ? _red : AppColors.brand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(DateFormat('MMM').format(DateTime.parse('${months[i]['month']}-01')),
                          style: TextStyle(fontSize: 11, color: colors.textHint)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Profit by enterprise ────────────────────────────────────
  Widget _buildEnterprises(AppColors colors, DashboardData d) {
    final rows = (d.profit!['enterprises'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    return _section(
      colors,
      'Profit by enterprise',
      rows.isEmpty
          ? _empty(colors, 'No enterprises yet.')
          : Column(
              children: [
                for (final e in rows)
                  _row(
                    colors,
                    title: e['name'] ?? '',
                    subtitle: 'Revenue ${DashboardService.money(e['revenue'], d.currency)} · '
                        'Costs ${DashboardService.money(e['cost'], d.currency)}',
                    trailing: Text(
                      DashboardService.money(e['profit'], d.currency),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: (num.tryParse('${e['profit']}') ?? 0) < 0 ? _red : colors.textPrimary,
                      ),
                    ),
                    bold: e['enterprise_id'] == null, // the whole-farm total
                  ),
              ],
            ),
    );
  }

  // ── Alerts ──────────────────────────────────────────────────
  Widget _buildAlerts(AppColors colors, DashboardData d) {
    Color tone(Map<String, dynamic> a) => a['type'] == 'heavy_rain'
        ? const Color(0xFF1565C0)
        : a['severity'] == 'critical'
            ? _red
            : _amber;
    IconData icon(String? type) => switch (type) {
          'heavy_rain' => Icons.thunderstorm_rounded,
          'vaccination_due' => Icons.vaccines_rounded,
          'breeding_due' => Icons.favorite_rounded,
          'crop_stress' => Icons.grass_rounded,
          'low_stock' || 'negative_stock' => Icons.inventory_2_rounded,
          'overdue_debt' => Icons.payments_rounded,
          'mortality_spike' => Icons.monitor_heart_rounded,
          _ => Icons.notifications_rounded,
        };

    return _section(
      colors,
      'Alerts${d.alerts.isEmpty ? '' : ' (${d.alerts.length})'}',
      d.alerts.isEmpty
          ? _empty(colors, 'No alerts. Everything looks fine.')
          : Column(
              children: [
                for (final a in d.alerts)
                  _row(
                    colors,
                    leading: _iconBadge(icon(a['type']), tone(a), size: 34),
                    title: DashboardService.alertText(a, d.currency),
                  ),
              ],
            ),
    );
  }

  // ── Today's records ─────────────────────────────────────────
  Widget _buildToday(AppColors colors, DashboardData d) {
    return _section(
      colors,
      "Today's records",
      d.today.isEmpty
          ? _empty(colors, 'No active enterprises.')
          : Column(
              children: [
                for (final e in d.today)
                  _row(
                    colors,
                    title: e['name'] ?? '',
                    subtitle: '${e['type']}'.replaceAll('_', ' '),
                    trailing: _pill(
                      e['recorded'] == true ? 'Done' : 'Not recorded',
                      e['recorded'] == true ? colors.brandText : _amber,
                    ),
                  ),
              ],
            ),
    );
  }

  // ── Stock levels ────────────────────────────────────────────
  Widget _buildStock(AppColors colors, DashboardData d) {
    return _section(
      colors,
      'Stock levels',
      d.stock.isEmpty
          ? _empty(colors, 'No stock recorded yet.')
          : Column(
              children: [
                for (final s in d.stock)
                  _row(
                    colors,
                    title: DashboardService.name(s['item_name']),
                    subtitle: [
                      if (s['location'] != null && '${s['location']}'.isNotEmpty) '${s['location']}',
                      if (s['value'] != null) DashboardService.money(s['value'], d.currency),
                    ].join(' · '),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_stockQty(s),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        if (s['status'] != 'ok') ...[
                          const SizedBox(height: 3),
                          _pill(s['status'] == 'negative' ? 'Below zero' : 'Running low',
                              s['status'] == 'negative' ? _red : _amber),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  /// Stock is counted in base units; show it in the item's display unit (bags, trays).
  String _stockQty(Map<String, dynamic> s) {
    final base = num.tryParse('${s['qty_base']}') ?? 0;
    final factor = (s['display_factor'] as num?) ?? 1;
    return '${DashboardService.qty(base / (factor == 0 ? 1 : factor))} ${s['display_unit'] ?? s['base_unit'] ?? ''}';
  }

  // ══════════════════════════════════════════════════════════
  // BUILDING BLOCKS
  // ══════════════════════════════════════════════════════════
  Widget _card(AppColors colors, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _section(AppColors colors, String title, Widget child) {
    return _card(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(AppColors colors,
      {Widget? leading, required String title, String? subtitle, Widget? trailing, bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.divider))),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: colors.textPrimary)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing],
        ],
      ),
    );
  }

  Widget _empty(AppColors colors, String text) =>
      Text(text, style: TextStyle(fontSize: 13, color: colors.textSecondary));

  Widget _iconBadge(IconData icon, Color color, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size / 3.2)),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
