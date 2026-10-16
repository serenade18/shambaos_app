import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../fields/field_service.dart';
import '../home_service.dart';
import '../../l10n/tr.dart';

/// Something the farm buys, uses or produces, from GET /items. Units are what it can be
/// counted in: a bag of 70 kg, a kg.
class Item {
  final Map<String, dynamic> raw;
  Item(this.raw);

  String get id => raw['id'];
  String get name => raw['name'] is Map ? '${raw['name'][ApiService.locale] ?? raw['name']['en'] ?? ''}' : '${raw['name'] ?? ''}';
  String get kind => raw['kind'] ?? ''; // input | output
  String get category => raw['category'] ?? '';
  String get displayUnit => raw['display_unit'] ?? '';
  List<String> get units => [
        for (final u in (raw['units'] as List? ?? const []))
          if (u is Map) '${u['code']}',
      ];
  List<String> get producedBy => [for (final t in (raw['produced_by'] as List? ?? const [])) '$t'];
}

/// An input not added to the farm yet, from GET /items/suggestions. Choosing one adds it.
class Suggestion {
  final Map<String, dynamic> raw;
  Suggestion(this.raw);

  String get code => raw['code'];
  String get name => raw['name'] is Map ? '${raw['name'][ApiService.locale] ?? raw['name']['en'] ?? ''}' : '${raw['name'] ?? ''}';
  String get category => raw['category'] ?? '';
}

/// One animal in a herd, from GET /animals.
class Animal {
  final Map<String, dynamic> raw;
  Animal(this.raw);

  String get id => raw['id'];
  String get tag => raw['tag'] ?? '';
  String get name => raw['name'] ?? '';
  String get sex => raw['sex'] ?? '';
  bool get isFemale => sex == 'female';
  bool get isActive => raw['status'] == 'active';
  String get label => name.isEmpty ? tag : '$tag · $name';
}

/// A customer or a supplier: someone the farm sells to or buys from.
class Party {
  final String id;
  final String name;
  final String phone;
  const Party(this.id, this.name, this.phone);

  factory Party.from(Map<String, dynamic> m) => Party('${m['id']}', '${m['name'] ?? ''}', '${m['phone'] ?? ''}');
}

/// The ways a sale can be paid for here. An M-Pesa prompt needs the payments set up, so
/// the app takes the code from the customer's SMS instead.
List<(String, String)> get paymentMethods => [('cash', 'Cash'.tr), ('mpesa_code', 'M-Pesa code'.tr), ('credit', 'On credit'.tr)];

/// Crop work, as the API names it.
List<(String, String)> get activityTypes => [
  ('land_preparation', 'Land preparation'.tr),
  ('planting', 'Planting'.tr),
  ('transplanting', 'Transplanting'.tr),
  ('weeding', 'Weeding'.tr),
  ('spraying', 'Spraying'.tr),
  ('fertilising', 'Fertilising'.tr),
  ('irrigation', 'Irrigation'.tr),
  ('pruning', 'Pruning or staking'.tr),
  ('other', 'Other work'.tr),
];

/// What money in or out is for, when it isn't a sale or a purchase.
List<(String, String)> get costCategories => [
  ('labour', 'Labour'.tr),
  ('transport', 'Transport'.tr),
  ('rent', 'Rent or lease'.tr),
  ('services', 'Services (tractor, vet)'.tr),
  ('utilities', 'Water and power'.tr),
  ('repairs', 'Repairs and tools'.tr),
  ('other', 'Other'.tr),
];
List<(String, String)> get revenueCategories => [
  ('grant', 'Grant or support'.tr),
  ('hire', 'Hiring out'.tr),
  ('other', 'Other'.tr),
];

/// Pigs and rabbits give birth to litters, raised as a batch; other herds name each young one.
bool givesLitters(String type) => type == 'pigs' || type == 'rabbits';

/// Dairy cows and goats are milked.
bool isMilked(String type) => type == 'dairy_cattle' || type == 'dairy_goats';

class RecordService {
  static String day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// A number as the farmer typed it, for the API: "1,500" is 1500. Null if it isn't one.
  static String? number(String text) {
    final t = text.trim().replaceAll(',', '').replaceAll(' ', '');
    if (t.isEmpty) return null;
    return num.tryParse(t) == null ? null : t;
  }

  /// Every page of a list the API pages with a cursor.
  static Future<List<Map<String, dynamic>>> _all(String path) async {
    final out = <Map<String, dynamic>>[];
    String? next = path;
    for (var page = 0; next != null && page < 20; page++) {
      final res = await ApiService.get(next);
      if (res.error) throw FieldLoadError(res.message ?? 'Could not load the list. Check your connection.'.tr);
      final data = res.data;
      if (data is! Map) break;
      out.addAll([for (final r in (data['results'] as List? ?? const [])) Map<String, dynamic>.from(r)]);
      final n = data['next'];
      if (n is! String || n.isEmpty) break;
      final q = Uri.parse(n).query;
      next = '${path.split('?').first}?$q';
    }
    return out;
  }

  // ================= LOOKUPS =================

  static List<Item>? _items;

  /// The farm's items. Kept for the session, and dropped when one is added.
  static Future<List<Item>> items({bool refresh = false}) async {
    if (_items != null && !refresh) return _items!;
    return _items = (await _all('/items')).map(Item.new).toList();
  }

  static Future<List<Suggestion>> suggestions() async {
    final res = await ApiService.get('/items/suggestions');
    if (res.error || res.data is! Map) return [];
    return [for (final r in (res.data['results'] as List? ?? const [])) Suggestion(Map<String, dynamic>.from(r))];
  }

  /// Adds a suggested input to the farm, and returns it.
  static Future<(Item?, String?)> addSuggestion(Suggestion s) async {
    final res = await ApiService.post('/items', {'suggestion': s.code});
    if (res.error || res.data is! Map) return (null, res.message ?? 'Could not add {name}.'.trArgs({'name': s.name}));
    _items = null;
    return (Item(Map<String, dynamic>.from(res.data)), null);
  }

  /// What the field produces: milk, eggs, maize grain.
  static Future<Item?> outputOf(Field f) async {
    for (final i in await items()) {
      if (i.kind == 'output' && i.producedBy.contains(f.type)) return i;
    }
    return null;
  }

  static Future<List<Animal>> animals(Field f) async =>
      (await _all('/animals?enterprise_id=${f.id}')).map(Animal.new).where((a) => a.isActive).toList();

  /// The open service on a female: served and not yet born, or checked not pregnant.
  static Future<Map<String, dynamic>?> openService(Animal a) async {
    final res = await ApiService.get('/animals/${a.id}/breeding');
    final rows = res.data is Map ? (res.data['results'] as List? ?? const []) : const [];
    for (final r in rows) {
      if (r is Map && r['service_date'] != null && r['outcome'] == null) return Map<String, dynamic>.from(r);
    }
    return null;
  }

  static Future<List<Party>> customers() async => (await _all('/customers')).map(Party.from).toList();
  static Future<List<Party>> suppliers() async => (await _all('/suppliers')).map(Party.from).toList();

  static Future<ApiResponse> addCustomer(String name, String phone) =>
      ApiService.post('/customers', {'name': name, 'phone': phone});
  static Future<ApiResponse> addSupplier(String name, String phone) =>
      ApiService.post('/suppliers', {'name': name, 'phone': phone});

  /// The main farm, which money and sales are recorded against.
  static Future<Map<String, dynamic>?> farm() async {
    final farms = await HomeService.listFarms();
    return farms.isEmpty ? null : farms.first;
  }

  // ================= CROPS =================

  static Future<ApiResponse> activity(Field f, {
    required DateTime date,
    required String type,
    List<Map<String, String>> inputs = const [],
    String? labourCost,
    String? serviceCost,
    String note = '',
  }) =>
      ApiService.post('/seasons/${f.id}/activities', {
        'date': day(date),
        'type': type,
        'inputs': inputs,
        'labour_cost': ?labourCost,
        'service_cost': ?serviceCost,
        'note': note,
      });

  static Future<ApiResponse> harvest(Field f, {required DateTime date, required String qty, required String unit, String? moisture}) =>
      ApiService.post('/seasons/${f.id}/harvests', {
        'date': day(date),
        'qty': qty,
        'unit': unit,
        'moisture': ?moisture,
      });

  // ================= BATCHES =================

  static Future<ApiResponse> batchDay(Field f, {
    required DateTime date,
    String? feedItemId,
    String? feedQty,
    String feedUnit = '',
    int deaths = 0,
    String? eggsTrays,
    String note = '',
  }) =>
      ApiService.post('/batches/${f.id}/days', {
        'date': day(date),
        if (feedItemId != null && feedQty != null) ...{'feed_item_id': feedItemId, 'feed_qty': feedQty, 'feed_unit': feedUnit},
        'deaths': deaths,
        'eggs_trays': ?eggsTrays,
        'note': note,
      });

  static Future<ApiResponse> sampleWeight(Field f, {required DateTime date, required int sampleSize, required String avgKg}) =>
      ApiService.post('/batches/${f.id}/weights', {'date': day(date), 'sample_size': sampleSize, 'avg_kg': avgKg});

  // ================= HERDS AND BATCHES =================

  /// A treatment or vaccination. A step of the vaccination plan is marked done by its key
  /// (herds) or its day (batches).
  static Future<ApiResponse> treatment(Field f, {
    required DateTime date,
    required String itemId,
    required String qty,
    required String unit,
    String doseNote = '',
    String subject = '',
    String? animalId,
    String? scheduleKey,
    int? scheduleDay,
  }) =>
      ApiService.post('/treatments', {
        'enterprise_id': f.id,
        'date': day(date),
        'item_id': itemId,
        'qty': qty,
        'unit': unit,
        'dose_note': doseNote,
        'subject': subject,
        'animal_id': ?animalId,
        'schedule_key': ?scheduleKey,
        'schedule_day': ?scheduleDay,
      });

  static Future<ApiResponse> milk(Field f, {required DateTime date, required String litres, String? animalId}) =>
      ApiService.post('/milk-records', {
        'enterprise_id': f.id,
        'date': day(date),
        'litres': litres,
        'animal_id': ?animalId,
      });

  static Future<ApiResponse> feeding(Field f, {required DateTime date, required String itemId, required String qty, required String unit}) =>
      ApiService.post('/feeding-records', {'enterprise_id': f.id, 'date': day(date), 'item_id': itemId, 'qty': qty, 'unit': unit});

  // ================= ANIMALS =================

  static Future<ApiResponse> addAnimal(Field f, {
    required String tag,
    String name = '',
    required String sex,
    String breed = '',
    DateTime? birthDate,
    required String source,
    String? cost,
  }) =>
      ApiService.post('/animals', {
        'enterprise_id': f.id,
        'tag': tag,
        'name': name,
        'sex': sex,
        'breed': breed,
        'birth_date': birthDate == null ? null : day(birthDate),
        'source': source,
        'cost': ?cost,
      });

  static Future<ApiResponse> weigh(Animal a, {required DateTime date, required String kg}) =>
      ApiService.post('/animals/${a.id}/weights', {'date': day(date), 'kg': kg});

  static Future<ApiResponse> serve(Animal a, {required DateTime date, required String method, String sire = '', String note = ''}) =>
      ApiService.post('/animals/${a.id}/breeding', {'service_date': day(date), 'method': method, 'sire': sire, 'note': note});

  static Future<ApiResponse> pregnancyCheck(String serviceId, {required DateTime date, required bool pregnant}) =>
      ApiService.post('/breeding/$serviceId/check', {'date': day(date), 'pregnant': pregnant});

  static Future<ApiResponse> birth(Animal mother, {
    required DateTime date,
    List<Map<String, String>> offspring = const [],
    int? bornAlive,
    int bornDead = 0,
  }) =>
      ApiService.post('/animals/${mother.id}/births', {
        'date': day(date),
        'offspring': offspring,
        'born_alive': ?bornAlive,
        'born_dead': bornDead,
      });

  static Future<ApiResponse> exit(Animal a, {required DateTime date, required String reason, String? value}) =>
      ApiService.post('/animals/${a.id}/exit', {'date': day(date), 'reason': reason, 'value': ?value});

  // ================= MONEY =================

  static Future<ApiResponse> money({
    required String farmId,
    required String kind, // cost | revenue
    required String category,
    required String amount,
    required DateTime date,
    String? enterpriseId,
    String note = '',
  }) =>
      ApiService.post('/finance/entries', {
        'farm_id': farmId,
        'kind': kind,
        'category': category,
        'amount': amount,
        'occurred_on': day(date),
        'enterprise_id': enterpriseId,
        'note': note,
      });

  static Future<ApiResponse> sale({
    required String farmId,
    required String customerId,
    required DateTime date,
    required List<Map<String, dynamic>> lines,
    required String method,
    String code = '',
  }) =>
      ApiService.post('/sales', {
        'farm_id': farmId,
        'customer_id': customerId,
        'date': day(date),
        'lines': lines,
        'payment': {'method': method, if (code.isNotEmpty) 'code': code},
      });

  static Future<ApiResponse> purchase({
    required String farmId,
    required String supplierId,
    required DateTime date,
    required List<Map<String, dynamic>> lines,
    required bool paid,
  }) =>
      ApiService.post('/purchases', {
        'farm_id': farmId,
        'supplier_id': supplierId,
        'date': day(date),
        'lines': lines,
        'paid': paid ? 'full' : 'credit',
      });
}
