// Add an animal (screens 29–30): the next tag, stage, mother, steer and weight.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shambaOS/screens/farm/add_to_farm.dart';
import 'package:shambaOS/screens/records/record_form.dart';
import 'package:shambaOS/widgets/sl_form.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final posted = <String, Map<String, dynamic>>{};

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Future<http.Response> api(http.Request r) async {
  final path = r.url.path.replaceFirst('/api/v1', '');
  if (r.method == 'POST') {
    posted[path] = jsonDecode(r.body) as Map<String, dynamic>;
    return json({'id': 'a-new', ...posted[path]!}, 201);
  }
  return switch (path) {
    '/enterprises' => json({'results': [
          {'id': 'h-dairy', 'name': 'Dairy herd', 'type': 'dairy_cattle', 'head_count': 2},
          {'id': 'h-beef', 'name': 'Fattening herd', 'type': 'beef_cattle', 'head_count': 0},
        ]}),
    '/animals' => r.url.queryParameters['enterprise_id'] == 'h-dairy'
        ? json({'results': [
            {'id': 'a-29', 'tag': 'KE-029', 'name': 'Njeri', 'sex': 'female', 'status': 'active'},
            {'id': 'a-47', 'tag': 'KE-047', 'name': '', 'sex': 'male', 'status': 'active'},
          ]})
        : json({'results': []}),
    _ => json({'message': 'not found'}, 404),
  };
}

Future<void> show(WidgetTester tester, Widget form) async {
  tester.view.physicalSize = const Size(360 * 3, 2000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => openRecord(context, form), child: const Text('open')))),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    posted.clear();
  });
  Future<void> run(Future<void> Function() body) => http.runWithClient(body, () => MockClient(api));

  testWidgets('a cow born on the farm: next tag, stage and mother', (tester) => run(() async {
        await show(tester, AnimalForm(farmId: 'farm', kind: FarmKind.of('dairy_cattle')!));
        expect(find.text('KE-048'), findsOneWidget);
        expect(find.text('Next after KE-047. Change it if the ear tag says otherwise.'), findsOneWidget);
        expect(find.text('Adding several cows at once?'), findsOneWidget);
        await tap(tester, 'Milking');
        await tap(tester, 'Friesian');
        await tap(tester, 'Born on the farm');
        await tap(tester, 'Choose');
        await tap(tester, 'KE-029 · Njeri');
        await tester.enterText(find.widgetWithText(TextField, 'KE-012'), 'KE-012');
        await tap(tester, 'Next');
        expect(find.text('KE-049'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('READY TO SAVE'), 300, scrollable: find.byType(Scrollable).first);
        expect(find.textContaining('Tag and sex are in.'), findsOneWidget);
        await tap(tester, 'Save animal');
        final body = posted['/animals']!;
        expect(
            {for (final k in ['tag', 'sex', 'stage', 'breed', 'source', 'mother_id', 'sire', 'castrated']) k: body[k]},
            {'tag': 'KE-049', 'sex': 'female', 'stage': 'milking', 'breed': 'Friesian', 'source': 'born', 'mother_id': 'a-29',
             'sire': 'KE-012', 'castrated': false});
      }));

  testWidgets('a steer bought by weight', (tester) => run(() async {
        await show(tester, AnimalForm(farmId: 'farm', kind: FarmKind.of('beef_cattle')!));
        expect(find.text('KE-1'), findsOneWidget);
        expect(find.text('Stage'), findsNothing);
        await tap(tester, 'Steer');
        await tester.enterText(find.descendant(of: find.byType(SlStepper), matching: find.byType(TextField)), '275');
        await tester.ensureVisible(find.bySemanticsLabel('5 kg more'));
        await tester.tap(find.bySemanticsLabel('5 kg more'));
        await tester.pumpAndSettle();
        await tap(tester, 'Save animal');
        expect(posted['/animals'], allOf(containsPair('sex', 'male'), containsPair('castrated', true), containsPair('stage', '')));
        expect(posted['/animals/a-new/weights'], containsPair('kg', '280'));
        expect(posted['/animals'], containsPair('stage', ''));
      }));
}
