import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../dashboard/dashboard_service.dart';
import '../farm/add_to_farm.dart';
import '../records/record_form.dart';
import 'customer_service.dart';
import '../../l10n/tr.dart';

/// Everyone the farm sells to, as the design's Customers: a search, what they
/// owe altogether on a green band, then who owes what, most first (GET
/// /customers), and Add customer fixed at the bottom.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>>? _customers;
  bool _failed = false;

  static const _plus = '<path d="M5 12h14"/><path d="M12 5v14"/>';
  static const _magnifier = '<path d="m21 21-4.34-4.34"/><circle cx="11" cy="11" r="8"/>';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await CustomerService.getCustomers();
    if (!mounted) return;
    setState(() {
      _failed = res.error;
      if (!res.error && res.data is List) {
        _customers = [for (final c in res.data as List) Map<String, dynamic>.from(c as Map)];
      } else {
        _customers ??= res.error ? null : [];
      }
    });
  }

  Future<void> _add() async {
    if (await openRecord(context, const CustomerForm())) _load();
  }

  static num _owed(Map<String, dynamic> c) => num.tryParse('${c['balance'] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final all = _customers;
    final q = _search.text.trim().toLowerCase();
    final shown = all?.where((x) => q.isEmpty || '${x['name']} ${x['phone']}'.toLowerCase().contains(q)).toList();

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
              // Room for Add customer, fixed at the bottom.
              padding: EdgeInsets.fromLTRB(16, 20, 16, 112 + bottom),
              children: [
                _bar(c),
                const SizedBox(height: 16),
                _searchBox(c),
                const SizedBox(height: 14),
                if (all == null && !_failed)
                  Padding(padding: const EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator(color: c.shamba)))
                else if (all == null)
                  SlLedger(children: [
                    SlLedgerRow(
                      title: 'Could not load your customers'.tr,
                      meta: 'Check your connection and try again.'.tr,
                      status: TextButton(onPressed: _load, child: Text('Try again'.tr)),
                    ),
                  ])
                else ...[
                  _total(all),
                  const SizedBox(height: 14),
                  _list(c, shown!, searching: q.isNotEmpty),
                ],
              ],
            ),
          ),
        ),
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
              label: 'Add customer'.tr,
              icon: const LineIcon(_plus, size: 20, color: Colors.white),
              onPressed: _add,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _bar(AppColors c) => Row(children: [
        Semantics(
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Customers'.tr,
              style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
        ),
      ]);

  Widget _searchBox(AppColors c) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Row(children: [
          LineIcon(_magnifier, size: 22, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontFamily: AppType.text, fontSize: 17, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search customers'.tr,
                hintStyle: TextStyle(fontFamily: AppType.text, fontSize: 17, color: c.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear'.tr,
              onPressed: _search.clear,
              icon: Icon(PhosphorIconsRegular.x, size: 20, color: c.textSecondary),
            ),
        ]),
      );

  /// What everyone owes, and how many of them owe it.
  Widget _total(List<Map<String, dynamic>> all) {
    final owing = all.where((x) => _owed(x) > 0).toList();
    final total = owing.fold<num>(0, (a, x) => a + _owed(x));
    return SlKeyFigure(
      band: true,
      label: 'CUSTOMERS OWE YOU'.tr,
      currency: DashboardService.symbol('KES'),
      value: DashboardService.amount(total),
      caption: all.isEmpty
          ? 'No customers yet'.tr
          : owing.isEmpty
              ? 'Everyone has paid up'.tr
              : 'From {n} of {total} customers'.trArgs({'n': owing.length, 'total': all.length}),
    );
  }

  Widget _list(AppColors c, List<Map<String, dynamic>> shown, {required bool searching}) {
    return SlLedger(
      title: 'Who buys from you'.tr,
      trailing: Text('Owed'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
      children: [
        if (shown.isEmpty)
          SlLedgerRow(
            title: searching ? 'No customer matches'.tr : 'No customers yet'.tr,
            meta: searching ? 'Try another name or number.'.tr : 'Add the people and shops you sell to.'.tr,
          ),
        for (final x in shown)
          SlLedgerRow(
            title: '${x['name'] ?? ''}',
            meta: _phone('${x['phone'] ?? ''}'),
            figure: _owed(x) > 0 ? DashboardService.money(x['balance'], 'KES') : null,
            status: _tag(x),
          ),
      ],
    );
  }

  /// A Kenyan number as farmers write it: +254722118409 → 0722 118 409.
  static String _phone(String p) {
    final m = RegExp(r'^\+254(\d{3})(\d{3})(\d{3})$').firstMatch(p);
    return m == null ? p : '0${m[1]} ${m[2]} ${m[3]}';
  }

  /// Paid up, or how long the oldest unpaid sale has been waiting.
  Widget _tag(Map<String, dynamic> x) {
    if (_owed(x) <= 0) return SlTag('Paid up'.tr, tone: SlTone.good);
    final days = x['oldest_days'];
    if (days is! num) return SlTag('Owes'.tr, tone: SlTone.neutral);
    if (days == 0) return SlTag('Since today'.tr, tone: SlTone.neutral);
    final text = days == 1 ? '1 day'.tr : '{n} days'.trArgs({'n': days});
    // A sale left unpaid over a week is late.
    return SlTag(text, tone: days > 7 ? SlTone.warn : SlTone.neutral, icon: days > 7 ? SlTag.clock : null);
  }
}
