import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../home_service.dart';
import '../../l10n/tr.dart';

/// The farm's dashboard, from GET /dashboard?farm_id=&from=&to=.
class DashboardData {
  final String farmName;
  final String currency;
  final DateTime from;
  final DateTime to;

  /// Null when the member can't see money (no money.read).
  final Map<String, dynamic>? profit;
  final Map<String, dynamic>? receivables;
  final Map<String, dynamic>? stockBought;
  final Map<String, dynamic>? payables;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> today;
  final List<Map<String, dynamic>> stock;

  DashboardData({
    required this.farmName,
    required this.currency,
    required this.from,
    required this.to,
    required this.profit,
    required this.receivables,
    required this.stockBought,
    required this.payables,
    required this.alerts,
    required this.today,
    required this.stock,
  });

  bool get showsMoney => profit != null;
}

class DashboardResult {
  final DashboardData? data;
  final String? error;
  final bool noFarm;

  DashboardResult({this.data, this.error, this.noFarm = false});
}

class DashboardService {
  static final _day = DateFormat('yyyy-MM-dd');

  /// The main farm's dashboard for the last [days] days, ending today.
  static Future<DashboardResult> load({int days = 30}) async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return DashboardResult(noFarm: true);
    final farm = farms.first;

    final to = DateTime.now();
    final from = to.subtract(Duration(days: days - 1));
    final response = await ApiService.get(
      '/dashboard?farm_id=${farm['id']}&from=${_day.format(from)}&to=${_day.format(to)}',
    );
    if (response.error || response.data is! Map) {
      return DashboardResult(error: response.message ?? 'Could not load the dashboard.'.tr);
    }

    final d = response.data as Map;
    List<Map<String, dynamic>> rows(dynamic v) =>
        v is List ? v.map((e) => Map<String, dynamic>.from(e)).toList() : [];
    Map<String, dynamic>? obj(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

    return DashboardResult(
      data: DashboardData(
        farmName: farm['name'] ?? 'Your farm'.tr,
        currency: await ApiService.getOrgCurrency(),
        from: DateTime.parse(d['from']),
        to: DateTime.parse(d['to']),
        profit: obj(d['profit']),
        receivables: obj(d['receivables']),
        stockBought: obj(d['stock_bought']),
        payables: obj(d['payables']),
        alerts: rows(d['alerts']),
        today: rows(d['today']),
        stock: rows(d['stock']),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FORMATTING
  // ─────────────────────────────────────────────

  /// How a currency is written on screen: Kenyan shillings as "KSh".
  static String symbol(String currency) => currency == 'KES' ? 'KSh'.tr : currency;

  /// A whole amount without its currency: "22,500", or "−1,200" for a loss.
  static String amount(dynamic value) {
    final v = num.tryParse('${value ?? 0}') ?? 0;
    final text = NumberFormat('#,##0').format(v.abs());
    return v < 0 ? '\u2212$text' : text;
  }

  static String money(dynamic amount, String currency, {bool signed = false}) {
    final value = num.tryParse('${amount ?? 0}') ?? 0;
    final text = '${symbol(currency)} ${NumberFormat('#,##0').format(value.abs())}';
    if (value < 0) return '\u2212$text';
    return signed && value > 0 ? '+$text' : text;
  }

  static String qty(num value) => NumberFormat('#,##0.##').format(value);

  /// An item name arrives in each language: {en, sw, fr}.
  static String name(dynamic names) {
    if (names is Map) {
      return (names[ApiService.locale] ?? names['en'] ?? names.values.first ?? '').toString();
    }
    return '${names ?? ''}';
  }

  static String _date(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}');
    return d == null ? '' : DateFormat('EEE d MMM').format(d);
  }

  /// Alerts are a type code plus parameters; this words them as the portal does.
  static String alertText(Map<String, dynamic> alert, String currency) {
    final p = Map<String, dynamic>.from(alert['params'] ?? {});
    final enterprise = p['enterprise'] ?? p['enterprise_name'] ?? 'an enterprise'.tr;
    final date = _date(p['date'] ?? p['due_on']);
    final product = p['product'] ?? p['vaccine'] ?? 'Vaccination'.tr;
    final unit = p['unit'] ?? '';

    switch (alert['type']) {
      case 'low_stock':
        return '{item} low: {qty} {unit} left'.trArgs({'item': p['item'], 'qty': p['qty'], 'unit': unit}).trim();
      case 'negative_stock':
        return '{item} is below zero: {qty} {unit}'.trArgs({'item': p['item'], 'qty': p['qty'], 'unit': unit}).trim();
      case 'mortality_spike':
        return 'Deaths up in {enterprise}: {deaths} on {date}'
            .trArgs({'enterprise': enterprise, 'deaths': p['deaths'], 'date': date});
      case 'vaccination_due':
        return p['animal_tag'] != null
            ? '{product} due for {tag} in {enterprise} by {date}'
                .trArgs({'product': product, 'tag': p['animal_tag'], 'enterprise': enterprise, 'date': date})
            : '{product} due for {enterprise} by {date}'.trArgs({'product': product, 'enterprise': enterprise, 'date': date});
      case 'breeding_due':
        return 'Breeding step due for {tag} on {date}'
            .trArgs({'tag': p['animal_tag'] ?? 'an animal'.tr, 'date': date});
      case 'heavy_rain':
        final rain = num.tryParse('${p['rain_mm'] ?? ''}')?.round();
        return rain != null
            ? 'Heavy rain expected {date}, about {rain} mm'.trArgs({'date': date, 'rain': rain})
            : 'Heavy rain expected {date}'.trArgs({'date': date});
      case 'overdue_debt':
        return '{customer} has owed you {amount} for {days} days'
            .trArgs({'customer': p['customer'], 'amount': money(p['amount'], currency), 'days': p['days']});
      case 'sync_conflict':
        return 'Records to review in {enterprise}'.trArgs({'enterprise': enterprise});
      case 'crop_stress':
        String f(dynamic v) => (num.tryParse('$v') ?? 0).toStringAsFixed(2);
        return 'Crops look less green: {before} to {now} since {date}'
            .trArgs({'before': f(p['previous']), 'now': f(p['ndvi']), 'date': _date(p['since'])});
      default:
        return '${alert['type']}'.replaceAll('_', ' ');
    }
  }
}
