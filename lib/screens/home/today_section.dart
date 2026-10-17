import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../fields/field_service.dart';
import '../fields/field_widgets.dart';
import '../records/record_form.dart';
import '../records/record_forms.dart';
import '../../l10n/tr.dart';

/// A herd or batch on Home's Today, from GET /today: what is recorded today, and its
/// last day before, which the day's form starts from.
class TodayRow {
  final Map<String, dynamic> raw;
  TodayRow(this.raw);

  String get id => '${raw['id']}';
  String get name => '${raw['name'] ?? ''}';
  String get type => '${raw['type'] ?? ''}';
  bool get isBatch => raw['module'] == 'batches';
  Map<String, dynamic>? get today => raw['today'] is Map ? Map<String, dynamic>.from(raw['today']) : null;
  Map<String, dynamic>? get last => raw['last'] is Map ? Map<String, dynamic>.from(raw['last']) : null;
}

class TodayService {
  static Future<List<TodayRow>?> load(String farmId) async {
    final res = await ApiService.get('/today?farm_id=$farmId');
    if (res.error || res.data is! Map) return null;
    return [for (final r in (res.data['results'] as List? ?? const [])) TodayRow(Map<String, dynamic>.from(r as Map))];
  }
}

/// "42.5 litres · 1 bag Dairy meal", what a day's record says in a line.
String dayLine(Map<String, dynamic> day) {
  final parts = <String>[];
  final produced = day['produced'];
  if (produced != null) {
    parts.add(switch ('${day['produced_unit'] ?? ''}') {
      'l' => '{n} litres'.trArgs({'n': produced}),
      'tray' => '{n} trays'.trArgs({'n': produced}),
      final u => '$produced $u'.trim(),
    });
  }
  if (day['feed_qty'] != null) parts.add('${day['feed_qty']} ${day['feed_unit'] ?? ''} ${day['feed_item'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').trim());
  final deaths = day['deaths'] is int ? day['deaths'] as int : 0;
  if (deaths > 0) parts.add(deaths == 1 ? '1 died'.tr : '{n} died'.trArgs({'n': deaths}));
  return parts.join(' · ');
}

/// Home's Today: each herd and batch, a tap from its day's record, which starts from
/// yesterday's numbers. Shown when the farm keeps animals.
class TodaySection extends StatelessWidget {
  final List<TodayRow> rows;
  final List<Field> fields;
  final VoidCallback onSaved;
  const TodaySection({super.key, required this.rows, required this.fields, required this.onSaved});

  Field _field(TodayRow r) => fields.where((f) => f.id == r.id).firstOrNull ?? Field({...r.raw, 'status': 'active'});

  Future<void> _open(BuildContext context, TodayRow r) async {
    final f = _field(r);
    // Once today has a record, more is added to it, so the form starts empty.
    final start = r.today == null ? r.last : null;
    final form = r.isBatch ? BatchDayForm(field: f, yesterday: start) : HerdDayForm(field: f, yesterday: start);
    if (await openRecord(context, form)) onSaved();
  }

  String _meta(TodayRow r) {
    final today = r.today;
    if (today != null) {
      final line = dayLine(today);
      return line.isEmpty ? 'Recorded today'.tr : 'Today: {line}'.trArgs({'line': line});
    }
    final last = r.last;
    if (last == null) return 'Nothing recorded yet'.tr;
    final line = dayLine(last);
    final date = DateTime.tryParse('${last['date']}');
    final now = DateTime.now();
    final yesterday = date != null && DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)));
    if (line.isEmpty) return 'Nothing recorded yesterday'.tr;
    return yesterday
        ? 'Yesterday: {line}'.trArgs({'line': line})
        : '{date}: {line}'.trArgs({'date': date == null ? '' : DateFormat('d MMM').format(date), 'line': line});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final left = rows.where((r) => r.today == null).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Text('Today'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ),
          Text(left == 0 ? 'All recorded'.tr : (left == 1 ? '1 to record'.tr : '{n} to record'.trArgs({'n': left})),
              style: AppType.caption.copyWith(color: left == 0 ? c.brandText : c.textSecondary)),
        ]),
        const SizedBox(height: 10),
        SlLedger(children: [
          for (final r in rows)
            SlLedgerRow(
              title: r.name,
              meta: _meta(r),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: Center(child: Image.asset(fieldIcon(r.type), width: 24, height: 24, excludeFromSemantics: true)),
              ),
              status: r.today != null
                  ? SlTag('Done'.tr, tone: SlTone.good)
                  : Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.shamba, borderRadius: BorderRadius.circular(999)),
                      child: Text('Record'.tr,
                          style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: c.onShamba)),
                    ),
              onTap: () => _open(context, r),
            ),
        ]),
      ]),
    );
  }
}

