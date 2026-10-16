import '../services/api_service.dart';
import 'fr.dart';
import 'sw.dart';

// The app is written in English; each English text is looked up in the chosen
// language's table. A text with no translation shows in English.
const _tables = <String, Map<String, String>>{'sw': sw, 'fr': fr};

extension Tr on String {
  /// This English text in the language the person chose.
  String get tr => _tables[ApiService.locale]?[this] ?? this;

  /// The same, then {name} placeholders filled in.
  String trArgs(Map<String, Object?> args) {
    var text = tr;
    args.forEach((name, value) => text = text.replaceAll('{$name}', '${value ?? ''}'));
    return text;
  }
}
