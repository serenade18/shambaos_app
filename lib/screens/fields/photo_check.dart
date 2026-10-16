import '../../services/api_service.dart';
import 'field_service.dart';
import '../../l10n/tr.dart';

/// One thing the AI found in the photo.
class PhotoFinding {
  final String title;
  final String detail;
  final String severity; // good | watch | act

  PhotoFinding(Map<String, dynamic> j)
      : title = '${j['title'] ?? ''}',
        detail = '${j['detail'] ?? ''}',
        severity = '${j['severity'] ?? 'watch'}';
}

/// The AI's answer about a photo, from POST /enterprises/{id}/scan.
class PhotoCheck {
  final String subject;
  final bool matchesField;
  final String condition; // healthy | watch | act_now | unclear
  final String summary;
  final List<PhotoFinding> findings;
  final List<String> actions;
  final String confidence; // low | medium | high

  PhotoCheck(Map<String, dynamic> j)
      : subject = '${j['subject'] ?? ''}',
        matchesField = j['matches_field'] != false,
        condition = '${j['condition'] ?? 'unclear'}',
        summary = '${j['summary'] ?? ''}',
        findings = [for (final f in (j['findings'] as List? ?? const [])) PhotoFinding(Map<String, dynamic>.from(f))],
        actions = [for (final a in (j['actions'] as List? ?? const [])) '$a'],
        confidence = '${j['confidence'] ?? 'low'}';
}

class PhotoCheckService {
  /// Sends the photo for the field to the AI check.
  static Future<PhotoCheck> check(Field field, List<int> jpeg, {String note = ''}) async {
    final res = await ApiService.postFile(
      '/enterprises/${field.id}/scan',
      field: 'image',
      bytes: jpeg,
      filename: 'scan.jpg',
      fields: {if (note.isNotEmpty) 'note': note},
    );
    if (res.error || res.data is! Map) {
      throw FieldLoadError(res.statusCode == 500 && res.data == null
          ? 'No connection. Check your internet and try again.'.tr
          : res.message ?? 'Could not check the photo. Try again.'.tr);
    }
    return PhotoCheck(Map<String, dynamic>.from(res.data));
  }
}
