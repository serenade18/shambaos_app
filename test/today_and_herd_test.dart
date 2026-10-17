// Home's Today and quick herd entry, against a fake API.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shambaOS/screens/farm/herd_entry.dart';
import 'package:shambaOS/screens/fields/field_service.dart';
import 'package:shambaOS/screens/home/today_section.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final posted = <String, List<Map<String, dynamic>>>{};

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

final todayRows = [
  {
    'id': 'e-dairy', 'name': 'Dairy herd', 'type': 'dairy_cattle', 'module': 'livestock', 'head_count': 5, 'today': null,
    'last': {'date': yesterday, 'produced': '42.5', 'produced_unit': 'l', 'feed_item_id': 'i-meal', 'feed_item': 'Dairy meal',
        'feed_qty': '1', 'feed_unit': 'bag', 'deaths': 0},
  },
  {
    'id': 'e-layers', 'name': 'Layers', 'type': 'layers', 'module': 'batches', 'head_count': 300,
    'today': {'date': 'x', 'produced': '8', 'produced_unit': 'tray', 'feed_item_id': null, 'feed_qty': null, 'deaths': 1},
    'last': null,
  },
];

Future<http.Response> api(http.Request r) async {
  final path = r.url.path.replaceFirst('/api/v1', '');
  if (r.method == 'POST') {
    (posted[path] ??= []).add(jsonDecode(r.body) as Map<String, dynamic>);
    return json({'id': 'new'}, 201);
  }
  return switch (path) {
    '/today' => json({'date': 'x', 'results': todayRows}),
    '/items' => json({'next': null, 'results': [
          {'id': 'i-meal', 'name': {'en': 'Dairy meal'}, 'kind': 'input', 'category': 'feed', 'base_unit': 'kg', 'display_unit': 'bag',
           'units': [{'code': 'bag', 'factor': 70}, {'code': 'kg', 'factor': 1}]},
        ]}),
    '/items/suggestions' => json({'results': []}),
    '/animals' => json({'next': null, 'results': [{'id': 'a', 'tag': 'KE-007'}, {'id': 'b', 'tag': 'KE-012'}]}),
    _ => json({'message': 'not found'}, 404),
  };
}

Future<void> pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: home));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    posted.clear();
  });

  Future<void> run(Future<void> Function() body) => http.runWithClient(body, () => MockClient(api));

  test('tags number on, keeping their zeros', () {
    expect(nextTag('KE-009'), 'KE-010');
    expect(nextTag('12'), '13');
    expect(nextTag('Daisy'), '');
    expect(firstTag(['KE-007', 'KE-012', 'Daisy']), 'KE-013');
    expect(firstTag([]), 'KE-1');
  });

  testWidgets("a herd's day opens with yesterday's milk and feed", (tester) => run(() async {
        final rows = (await TodayService.load('farm'))!;
        await pumpApp(tester, Scaffold(body: ListView(children: [TodaySection(rows: rows, fields: const <Field>[], onSaved: () {})])));
        expect(find.text('Yesterday: 42.5 litres · 1 bag Dairy meal'), findsOneWidget);
        expect(find.text('Today: 8 trays · 1 died'), findsOneWidget);
        expect(find.text('1 to record'), findsOneWidget);

        await tester.tap(find.text('Dairy herd'));
        await tester.pumpAndSettle();
        expect(find.text('Yesterday 42.5 litres'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, "Save today's record"));
        await tester.pumpAndSettle();
        expect(posted['/milk-records']!.single, containsPair('litres', '42.5'));
        expect(posted['/feeding-records']!.single, allOf(containsPair('item_id', 'i-meal'), containsPair('qty', '1'), containsPair('unit', 'bag')));
      }));

  testWidgets('quick herd entry saves every row in one go', (tester) => run(() async {
        await pumpApp(tester, const HerdEntryScreen(herdId: 'e-dairy', herdName: 'Dairy herd', type: 'dairy_cattle'));
        final tags = find.byType(TextField);
        expect(tags, findsNWidgets(3));
        expect((tester.widget<TextField>(tags.at(0))).controller!.text, 'KE-013');
        expect((tester.widget<TextField>(tags.at(2))).controller!.text, 'KE-015');

        // A tag typed by hand: the rows under it follow on from it.
        await tester.enterText(tags.at(1), 'KE-100');
        await tester.pump();
        expect((tester.widget<TextField>(tags.at(2))).controller!.text, 'KE-101');

        await tester.tap(find.text('Friesian').first);
        await tester.tap(find.text('Bull').last);
        await tester.tap(find.text('Add another cow'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(4));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save 4 cows'));
        await tester.pumpAndSettle();
        final body = posted['/animals/bulk']!.single;
        expect(body['enterprise_id'], 'e-dairy');
        expect(body['animals'], [
          {'tag': 'KE-013', 'sex': 'female', 'breed': 'Friesian'},
          {'tag': 'KE-100', 'sex': 'female', 'breed': 'Friesian'},
          {'tag': 'KE-101', 'sex': 'male', 'breed': 'Friesian'},
          {'tag': 'KE-102', 'sex': 'male', 'breed': 'Friesian'},
        ]);
      }));
}
