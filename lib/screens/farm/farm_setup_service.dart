import '../../services/api_service.dart';
import '../home_service.dart';
import '../../l10n/tr.dart';

/// What My farm and "What are you adding?" read and write: the farm, what it
/// runs (GET /navigation), its plots, buildings and herds, and the start calls
/// (POST /herds, /batches, /seasons, /plots, /structures, /animals, /suppliers,
/// /invitations).
class FarmSetupService {
  /// The main farm and the types it keeps; null farm when there is none yet.
  static Future<({Map<String, dynamic>? farm, List<String> types, String? error})> load() async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return (farm: null, types: <String>[], error: null);
    final farm = farms.first;
    final nav = await ApiService.get('/navigation?farm_id=${farm['id']}');
    final types = nav.data is Map ? [for (final t in (nav.data['types'] as List? ?? [])) '$t'] : <String>[];
    return (farm: farm, types: types, error: nav.error ? (nav.message ?? 'Check your connection and try again.'.tr) : null);
  }

  static Future<List<Map<String, dynamic>>> _rows(String endpoint) async {
    final res = await ApiService.get(endpoint);
    if (res.error || res.data is! Map) return [];
    return [for (final r in (res.data['results'] as List? ?? [])) Map<String, dynamic>.from(r as Map)];
  }

  static Future<List<Map<String, dynamic>>> plots(String farmId) => _rows('/plots?farm_id=$farmId');
  static Future<List<Map<String, dynamic>>> structures(String farmId) => _rows('/structures?farm_id=$farmId');

  /// Active herds of one kind of animal, newest first.
  static Future<List<Map<String, dynamic>>> herds(String farmId, String type) async =>
      (await _rows('/enterprises?farm_id=$farmId&module=livestock&status=active')).where((e) => e['type'] == type).toList();

  static Future<ApiResponse> startHerd(Map<String, dynamic> body) => ApiService.post('/herds', body);
  static Future<ApiResponse> addAnimal(Map<String, dynamic> body) => ApiService.post('/animals', body);
  static Future<ApiResponse> startBatch(Map<String, dynamic> body) => ApiService.post('/batches', body);
  static Future<ApiResponse> startSeason(Map<String, dynamic> body) => ApiService.post('/seasons', body);
  static Future<ApiResponse> addPlot(Map<String, dynamic> body) => ApiService.post('/plots', body);
  static Future<ApiResponse> addStructure(Map<String, dynamic> body) => ApiService.post('/structures', body);
  static Future<ApiResponse> addSupplier(Map<String, dynamic> body) => ApiService.post('/suppliers', body);
  static Future<ApiResponse> invite(Map<String, dynamic> body) => ApiService.post('/invitations', body);
}
