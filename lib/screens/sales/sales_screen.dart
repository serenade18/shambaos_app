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
import '../records/record_form.dart';
import '../records/record_forms.dart';
import '../../l10n/tr.dart';

/// The farm's sales over a period (GET /sales?farm_id=&from=&to=).
class SalesPeriod {
  final List<Map<String, dynamic>> sales; // newest first
  final String currency;
  const SalesPeriod(this.sales, this.currency);

  static num _n(dynamic v) => num.tryParse('${v ?? 0}') ?? 0;
  num get total => sales.fold<num>(0, (a, s) => a + _n(s['total']));
  num get paid => sales.fold<num>(0, (a, s) => a + _n(s['paid']));
  num get owed => sales.fold<num>(0, (a, s) => a + _n(s['balance_due']));
  int get customers => sales.map((s) => s['customer_id']).toSet().length;
}

class SalesService {
  static final _day = DateFormat('yyyy-MM-dd');

  /// Null with [noFarm] when there is no farm yet; null with an error otherwise.
  static Future<({SalesPeriod? period, bool noFarm, String? error})> load({required int days}) async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return (period: null, noFarm: true, error: null);
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days - 1));
    final (res, currency) = await (
      ApiService.get('/sales?farm_id=${farms.first['id']}&from=${_day.format(from)}&to=${_day.format(to)}&limit=200'),
      ApiService.getOrgCurrency(),
    ).wait;
    if (res.error || res.data is! Map) {
      return (period: null, noFarm: false, error: res.message ?? 'Check your connection and try again.'.tr);
    }
    final rows = (res.data['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (period: SalesPeriod(rows, currency), noFarm: false, error: null);
  }
}

/// The design's Sales: what was sold over the period on a green band, what is
/// paid and still owed, the recent sales with how each was paid, and Record a sale.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const _periods = [7, 30, 90];
  static const _plus = '<path d="M5 12h14"/><path d="M12 5v14"/>';

  int _days = 30;
  bool _loading = true;
  SalesPeriod? _period;
  bool _noFarm = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await SalesService.load(days: _days);
    if (!mounted) return;
    setState(() {
      _period = r.period ?? _period;
      _noFarm = r.noFarm;
      _error = r.error;
      _loading = false;
    });
  }

  Future<void> _record() async {
    if (await openRecord(context, const SaleForm())) _load();
  }

  String _periodLabel(int days) => 'Last {days} days'.trArgs({'days': days});

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
            Text('Show sales for'.tr,
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            color: c.shamba,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 20, 16, 112 + bottom),
              children: [
                _bar(c),
                const SizedBox(height: 16),
                ..._body(c),
              ],
            ),
          ),
        ),
        if (!_noFarm)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.3],
                  colors: [c.scaffoldBackground.withValues(alpha: 0), c.scaffoldBackground],
                ),
              ),
              child: LedgerButton(
                label: 'Record a sale'.tr,
                icon: const LineIcon(_plus, size: 20, color: Colors.white),
                onPressed: _record,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _bar(AppColors c) => Row(children: [
        _roundBack(context, c),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Sales'.tr,
              style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
        ),
        if (_loading && _period != null) ...[
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba)),
          const SizedBox(width: 10),
        ],
        SlChip(_periodLabel(_days), selected: true, onTap: _pickPeriod),
      ]);

  List<Widget> _body(AppColors c) {
    final p = _period;
    if (_noFarm) {
      return [SlLedger(children: [SlLedgerRow(title: 'No farm yet'.tr, meta: 'Set up your farm to record and see its sales.'.tr)])];
    }
    if (p == null && _loading) {
      return [Padding(padding: const EdgeInsets.only(top: 64), child: Center(child: CircularProgressIndicator(color: c.shamba)))];
    }
    if (p == null) {
      return [
        SlLedger(children: [
          SlLedgerRow(title: 'Could not load your sales'.tr, meta: _error, status: TextButton(onPressed: _load, child: Text('Try again'.tr))),
        ]),
      ];
    }
    final cur = p.currency;
    return [
      SlKeyFigure(
        band: true,
        label: 'SOLD · LAST {days} DAYS'.trArgs({'days': _days}),
        currency: DashboardService.symbol(cur),
        value: DashboardService.amount(p.total),
        caption: p.sales.isEmpty
            ? 'No sales in these days'.tr
            : '{n} sales to {c} customers'.trArgs({'n': p.sales.length, 'c': p.customers}),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _metric(c, 'Paid'.tr, p.paid, cur, c.goodTint, c.goodInk)),
        const SizedBox(width: 10),
        Expanded(child: _metric(c, 'Still owed'.tr, p.owed, cur, c.warnTint, c.warnInk)),
      ]),
      const SizedBox(height: 12),
      SlLedger(
        title: 'Recent sales'.tr,
        trailing: SlEyebrow(_periodLabel(_days)),
        children: [
          if (p.sales.isEmpty) SlLedgerRow(title: 'No sales yet'.tr, meta: 'Sales you record show here, with how each was paid.'.tr),
          for (final s in p.sales.take(25))
            SlLedgerRow(
              title: '${s['customer_name'] ?? ''}',
              meta: [_what(s), _when(s['date'])].where((x) => x.isNotEmpty).join(' · '),
              figure: DashboardService.money(s['total'], cur),
              status: _tag(s, cur),
            ),
        ],
      ),
    ];
  }

  Widget _metric(AppColors c, String label, num value, String currency, Color tint, Color ink) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppType.caption.copyWith(color: ink)),
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

  /// "30 trays of eggs", or the first line and how many more.
  String _what(Map<String, dynamic> s) {
    final lines = (s['lines'] as List? ?? []).whereType<Map>().toList();
    if (lines.isEmpty) return '';
    final l = lines.first;
    final qty = num.tryParse('${l['qty']}');
    final first = '${qty == null ? '' : '${DashboardService.qty(qty)} ${l['unit'] ?? ''} '}${DashboardService.name(l['item_name'])}'.trim();
    return lines.length == 1 ? first : '{first} and {n} more'.trArgs({'first': first, 'n': lines.length - 1});
  }

  String _when(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}');
    if (d == null) return '';
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(d);
    if (day == today) return 'Today'.tr;
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday'.tr;
    return DateFormat('EEE d MMM', Localizations.localeOf(context).toString()).format(d);
  }

  /// How the sale stands: paid, waiting for an M-Pesa payment, part paid or on credit.
  Widget _tag(Map<String, dynamic> s, String cur) => switch (s['status']) {
        'paid' => SlTag('Paid'.tr, tone: SlTone.good, icon: SlTag.check),
        'awaiting_payment' => SlTag('Waiting for M-Pesa'.tr, tone: SlTone.info),
        'partial' => SlTag('{amount} owed'.trArgs({'amount': DashboardService.money(s['balance_due'], cur)}), tone: SlTone.warn),
        _ => SlTag('On credit'.tr, tone: SlTone.warn),
      };
}

Widget _roundBack(BuildContext context, AppColors c) => Semantics(
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
