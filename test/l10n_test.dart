import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shambaOS/l10n/fr.dart';
import 'package:shambaOS/l10n/language_scope.dart';
import 'package:shambaOS/l10n/sw.dart';
import 'package:shambaOS/l10n/tr.dart';
import 'package:shambaOS/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Every 'English text'.tr in lib/, as written in the source.
final _wrapped = RegExp(r"""('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")\s*\.(?:tr\b|trArgs)""");

// The demo markets' names, distances and hours stay as they are.
final _demo = RegExp(r'^(\d|.*Market$|.*Hub$|Nairobi CBD|Gikomba|Kilimani|Ngara|Industrial Area|Kangemi)');

String _unescape(String literal) => literal
    .substring(1, literal.length - 1)
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\$', r'$');

Set<String> _texts() {
  final texts = <String>{};
  for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('/l10n/')) continue;
    for (final m in _wrapped.allMatches(file.readAsStringSync())) {
      texts.add(_unescape(m.group(1)!));
    }
  }
  return texts..removeWhere(_demo.hasMatch);
}

void main() {
  final placeholder = RegExp(r'\{\w+\}');
  List<String> placeholders(String s) => placeholder.allMatches(s).map((m) => m[0]!).toList()..sort();

  for (final (name, table) in [('Kiswahili', sw), ('Français', fr)]) {
    test('every text in the app has a $name translation', () {
      final missing = _texts().where((t) => !table.containsKey(t)).toList()..sort();
      expect(missing, isEmpty, reason: 'Add these to lib/l10n/${name == 'Kiswahili' ? 'sw' : 'fr'}.dart');
    });

    test('$name translations keep their {placeholders}', () {
      final broken = [
        for (final e in table.entries)
          if (placeholders(e.key).join() != placeholders(e.value).join()) e.key,
      ];
      expect(broken, isEmpty);
    });
  }

  test('a text shows in the chosen language, and in English without a translation', () async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.setLocale('sw');
    expect('Save'.tr, 'Hifadhi');
    expect('Add {name}'.trArgs({'name': 'Mahindi'}), 'Ongeza Mahindi');
    expect('Not in any table'.tr, 'Not in any table');
    await ApiService.setLocale('fr');
    expect('Save'.tr, 'Enregistrer');
    await ApiService.setLocale('en');
    expect('Save'.tr, 'Save');
  });

  testWidgets('picking a language redraws open screens, keeping where you are', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.setLocale('en');
    await tester.pumpWidget(LanguageScope(builder: (_) => const MaterialApp(home: _Label())));
    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(builder: (_) => const _Label()));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    await ApiService.setLocale('sw');
    await tester.pump();
    expect(find.text('Hifadhi'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    // Back on the first screen, which was redrawn too.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Hifadhi'), findsOneWidget);
    await ApiService.setLocale('en');
  });
}

class _Label extends StatelessWidget {
  const _Label();

  @override
  Widget build(BuildContext context) => Text('Save'.tr);
}
