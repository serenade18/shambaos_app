import 'package:intl/intl.dart';

import '../../models/weather_model.dart';
import '../../services/api_service.dart';
import '../home_service.dart';

/// One field, herd or flock on the farm: an enterprise from GET /enterprises.
class Field {
  final Map<String, dynamic> raw;
  Field(this.raw);

  String get id => raw['id'];
  String get farmId => raw['farm_id'];
  String get name => raw['name'] ?? '';
  String get type => raw['type'] ?? '';
  String get module => raw['module'] ?? '';
  bool get isCrop => module == 'crops';
  bool get isActive => raw['status'] == 'active';
  DateTime get startedOn => DateTime.parse(raw['started_on']);
  int? get headCount => raw['head_count'];
  num? get acres => num.tryParse('${raw['area_acres'] ?? ''}');

  /// What the farmer calls the field's size: "2 acres", "300 birds", "5 cows".
  String get size {
    if (isCrop) {
      final a = acres;
      if (a == null) return '';
      final n = NumberFormat('#,##0.##').format(a);
      return '$n acre${a == 1 ? '' : 's'}';
    }
    final n = headCount ?? 0;
    final unit = switch (type) {
      'layers' || 'broilers' => 'bird',
      'fish' => 'fish',
      'dairy_cattle' || 'beef_cattle' => 'cow',
      'dairy_goats' => 'goat',
      'sheep' => 'sheep',
      'pigs' => 'pig',
      'rabbits' => 'rabbit',
      _ => 'animal',
    };
    final plural = n == 1 || unit == 'fish' || unit == 'sheep' ? unit : '${unit}s';
    return '${NumberFormat('#,##0').format(n)} $plural';
  }

  /// "Planted on 3 Oct 2026", "Started on 3 Oct 2026".
  String get startedLine =>
      '${isCrop ? 'Planted' : 'Started'} on ${DateFormat('d MMM yyyy').format(startedOn)}';
}

/// A field's category on the home screen.
enum FieldCategory { animals, poultry, crops, orchards }

extension FieldCategoryOf on Field {
  FieldCategory get category => switch (type) {
        'layers' || 'broilers' || 'fish' => FieldCategory.poultry,
        'bananas' || 'avocados' => FieldCategory.orchards,
        _ => isCrop ? FieldCategory.crops : FieldCategory.animals,
      };
}

/// A job in the field's plan, done or still to do.
class FieldTask {
  final String title;
  final String? code; // the activity type to record, for crop jobs
  final DateTime? date; // when it was done, or when it is due
  final bool done;
  final String? status; // overdue | due | upcoming, for vaccinations

  const FieldTask({required this.title, this.code, this.date, required this.done, this.status});
}

/// A figure in the field's analysis.
class FieldMetric {
  final String label;
  final String value;
  final String? note;
  const FieldMetric(this.label, this.value, {this.note});
}

/// A field's data could not be loaded (offline, signed out, server error).
class FieldLoadError implements Exception {
  final String message;
  const FieldLoadError(this.message);
}

class FieldService {
  static ApiResponse _ok(ApiResponse r) {
    if (r.error) throw FieldLoadError(r.message ?? 'Could not load this field. Check your connection.');
    return r;
  }

  static List<Map<String, dynamic>> _rows(dynamic data) =>
      data is Map && data['results'] is List
          ? (data['results'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : [];

  /// The main farm's active fields, herds and flocks.
  static Future<(Map<String, dynamic>?, List<Field>)> load() async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return (null, <Field>[]);
    final farm = farms.first;
    final res = await ApiService.get('/enterprises?farm_id=${farm['id']}&status=active');
    return (farm, _rows(res.data).map(Field.new).toList());
  }

  static Future<List<WeatherModel>> forecast(String farmId) => HomeService.getForecast(farmId: farmId);

  /// The season's field jobs for a crop, ticked when an activity of that kind is recorded.
  static const cropPlan = [
    ('land_preparation', 'Prepare the land'),
    ('planting', 'Plant the seed'),
    ('weeding', 'Weed the field'),
    ('fertilising', 'Top-dress with fertiliser'),
    ('spraying', 'Spray against pests'),
  ];

  static Future<List<FieldTask>> tasks(Field f) async {
    if (f.isCrop) {
      final res = _ok(await ApiService.get('/seasons/${f.id}/activities'));
      final done = <String, DateTime>{};
      for (final a in _rows(res.data)) {
        final date = DateTime.tryParse('${a['date']}');
        if (date != null) done.putIfAbsent('${a['type']}', () => date);
      }
      return [
        for (final (code, title) in cropPlan)
          FieldTask(title: title, code: code, date: done[code], done: done.containsKey(code)),
      ];
    }
    final path = f.module == 'batches' ? '/batches/${f.id}/vaccinations' : '/herds/${f.id}/vaccinations';
    final res = _ok(await ApiService.get(path));
    final steps = res.data is Map && res.data['steps'] is List ? res.data['steps'] as List : const [];
    return [
      for (final s in steps)
        FieldTask(
          title: '${s['vaccine']}',
          date: DateTime.tryParse('${s['done_on'] ?? s['due_on'] ?? ''}'),
          done: s['status'] == 'done',
          status: s['status'],
        ),
    ];
  }

  /// Records a crop job as done today.
  static Future<ApiResponse> recordTask(Field f, FieldTask t) => ApiService.post('/seasons/${f.id}/activities', {
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'type': t.code,
      });

  /// Three figures that say how the field is doing. Crops: satellite plant health and
  /// the rain coming. Animals: the herd or flock's own figures from its records.
  static Future<List<FieldMetric>> analyse(Field f) async {
    if (f.isCrop) {
      final results = await Future.wait([
        ApiService.get('/crop-health?farm_id=${f.farmId}'),
        forecast(f.farmId),
      ]);
      final health = (results[0] as ApiResponse).data;
      final days = results[1] as List<WeatherModel>;
      final latest = health is Map ? health['latest'] : null;
      final ndvi = latest is Map && latest['ndvi'] is Map ? num.tryParse('${latest['ndvi']['mean']}') : null;
      final rain5 = days.take(5).fold<double>(0, (a, d) => a + d.precipitation);
      return [
        FieldMetric('Plant health', ndvi == null ? '—' : '${(ndvi * 100).round()}%',
            note: ndvi == null ? _healthWhy(health) : '${latest['health'] ?? ''}'.replaceAll('_', ' ')),
        FieldMetric('Rain, 5 days', days.isEmpty ? '—' : '${rain5.round()} mm',
            note: days.isEmpty ? 'No forecast yet' : 'Expected'),
        FieldMetric('Rain today', days.isEmpty ? '—' : '${days.first.rainProbability}%', note: 'Chance'),
      ];
    }
    final res = _ok(await ApiService.get('/enterprises/${f.id}'));
    final kpis = res.data is Map && res.data['kpis'] is List ? res.data['kpis'] as List : const [];
    return [
      for (final k in kpis.take(3))
        FieldMetric(
          _kpiLabel('${k['code']}'),
          k['money'] == true
              ? 'KSh ${k['value']}'
              : k['unit'] == '%'
                  ? '${k['value']}%'
                  : '${k['value']}${'${k['unit'] ?? ''}'.isEmpty ? '' : ' ${k['unit']}'}',
          note: 'From your records',
        ),
    ];
  }

  static String _healthWhy(dynamic health) => switch (health is Map ? health['status'] : null) {
        'no_boundary' => 'Draw the field on the map',
        'pending' => 'First image coming',
        _ => 'No satellite image yet',
      };

  static String _kpiLabel(String code) => switch (code) {
        'laying_rate' => 'Laying rate',
        'feed_per_tray' => 'Feed per tray',
        'cost_per_tray' => 'Cost per tray',
        'mortality' => 'Deaths',
        'alive' => 'Alive',
        'age' => 'Age',
        'feed_used' => 'Feed used',
        'milk_per_day' => 'Milk a day',
        'animals' => 'Animals',
        'cost_per_litre' => 'Cost per litre',
        'milk_30d' => 'Milk, 30 days',
        'cost_to_date' => 'Cost so far',
        _ => code.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase()),
      };
}
