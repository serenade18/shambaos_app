// The record forms send what the API expects, against a fake API.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shambaOS/screens/fields/field_service.dart';
import 'package:shambaOS/screens/records/record_form.dart';
import 'package:shambaOS/screens/records/record_forms.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> item(String id, String name, String kind, String cat, List<String> units, String display, [List<String> by = const []]) =>
    {
      'id': id,
      'name': {'en': name},
      'kind': kind,
      'category': cat,
      'produced_by': by,
      'base_unit': units.last,
      'display_unit': display,
      'units': [for (final u in units) {'code': u, 'factor': 1}],
    };

final items = [
  item('i-dap', 'DAP fertiliser', 'input', 'fertiliser', ['bag', 'kg'], 'bag'),
  item('i-meal', 'Dairy meal', 'input', 'feed', ['bag', 'kg'], 'bag'),
  item('i-maize', 'Maize grain', 'output', 'produce', ['bag', 'debe', 'kg'], 'bag', ['maize']),
  item('i-milk', 'Milk', 'output', 'produce', ['l'], 'l', ['dairy_cattle']),
  item('i-eggs', 'Eggs', 'output', 'produce', ['tray', 'piece'], 'tray', ['layers']),
];

final maize = Field({'id': 'e-maize', 'farm_id': 'farm', 'name': 'Shamba la juu', 'type': 'maize', 'module': 'crops', 'status': 'active', 'started_on': '2026-09-01', 'area_acres': '2.00'});
final dairy = Field({'id': 'e-dairy', 'farm_id': 'farm', 'name': 'Dairy', 'type': 'dairy_cattle', 'module': 'livestock', 'status': 'active', 'started_on': '2026-01-01', 'head_count': 2});
final layers = Field({'id': 'e-layers', 'farm_id': 'farm', 'name': 'Layers', 'type': 'layers', 'module': 'batches', 'status': 'active', 'started_on': '2026-01-01', 'head_count': 300});

final posted = <String, Map<String, dynamic>>{};

http.Response page(List rows) => json({'next': null, 'previous': null, 'results': rows});

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Future<http.Response> api(http.Request r) async {
  final path = r.url.path.replaceFirst('/api/v1', '');
  if (r.method == 'POST') {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    posted[path] = body;
    if (path == '/items') return json(item('i-newcastle', 'Newcastle vaccine', 'input', 'drug', ['vial', 'dose'], 'vial'), 201);
    if (path == '/customers') return json({'id': 'c-new', 'name': body['name'], 'phone': body['phone']}, 201);
    return json({'id': 'new', ...body}, 201);
  }
  return switch (path) {
    '/items' => page(items),
    '/items/suggestions' => json({'results': [{'code': 'newcastle', 'name': {'en': 'Newcastle vaccine'}, 'category': 'drug'}]}),
    '/animals' => page([
        {'id': 'a-1', 'tag': 'KE-1', 'name': 'Daisy', 'sex': 'female', 'status': 'active'},
        {'id': 'a-2', 'tag': 'KE-9', 'name': '', 'sex': 'male', 'status': 'active'},
      ]),
    '/animals/a-1/breeding' => page([{'id': 'b-1', 'service_date': '2026-08-01', 'expected_due': '2027-05-10', 'outcome': null}]),
    '/customers' => page([{'id': 'c-1', 'name': 'Wanjiru', 'phone': ''}]),
    '/suppliers' => page([{'id': 's-1', 'name': 'Agrovet', 'phone': ''}]),
    '/farms' => page([{'id': 'farm', 'name': 'Kamau Farm'}]),
    '/enterprises' => page([maize.raw, dairy.raw, layers.raw]),
    _ => json({'message': 'not found'}, 404),
  };
}

Future<void> show(WidgetTester tester, Widget form) async {
  tester.view.physicalSize = const Size(360 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(child: ElevatedButton(onPressed: () => openRecord(context, form), child: const Text('open'))),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String label, String option) async {
  final box = find.widgetWithText(DropdownButtonFormField<String>, label);
  await tester.ensureVisible(box);
  await tester.tap(box);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester, [String label = 'Save']) async {
  await tester.tap(find.widgetWithText(ElevatedButton, label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    posted.clear();
  });

  Future<void> run(WidgetTester tester, Future<void> Function() body) =>
      http.runWithClient(body, () => MockClient(api));

  testWidgets('field work with an input', (tester) => run(tester, () async {
        await show(tester, ActivityForm(field: maize, type: 'fertilising'));
        await tester.tap(find.text('Add an input'));
        await tester.pumpAndSettle();
        await choose(tester, 'Seed, fertiliser or spray', 'DAP fertiliser');
        await tester.enterText(find.widgetWithText(TextField, 'How much'), '2');
        await tester.enterText(find.widgetWithText(TextField, 'Labour paid'), '1,500');
        await save(tester);
        final body = posted['/seasons/e-maize/activities']!;
        expect(body['type'], 'fertilising');
        expect(body['inputs'], [{'item_id': 'i-dap', 'qty': '2', 'unit': 'bag'}]);
        expect(body['labour_cost'], '1500');
        expect(body.containsKey('service_cost'), isFalse);
        expect(find.textContaining('Fertilising recorded'), findsOneWidget);
      }));

  testWidgets('harvest in a chosen unit', (tester) => run(tester, () async {
        await show(tester, HarvestForm(field: maize));
        await tester.enterText(find.widgetWithText(TextField, 'Maize grain harvested'), '30');
        await tester.tap(find.text('kg'));
        await tester.pumpAndSettle();
        await save(tester);
        expect(posted['/seasons/e-maize/harvests'], containsPair('unit', 'kg'));
        expect(posted['/seasons/e-maize/harvests'], containsPair('moisture', 'dry'));
      }));

  testWidgets('a vaccine added from the suggestions marks a step done', (tester) => run(tester, () async {
        await show(tester, TreatmentForm(
            field: layers, step: const FieldTask(title: 'Newcastle', done: false, vaccine: 'Newcastle', scheduleDay: 7)));
        await choose(tester, 'Medicine or vaccine', 'Add Newcastle vaccine');
        expect(posted['/items'], {'suggestion': 'newcastle'});
        await tester.enterText(find.widgetWithText(TextField, 'How much was given'), '1');
        await save(tester);
        final body = posted['/treatments']!;
        expect(body['item_id'], 'i-newcastle');
        expect(body['unit'], 'vial');
        expect(body['schedule_day'], 7);
      }));

  testWidgets('milk from one cow', (tester) => run(tester, () async {
        await show(tester, MilkForm(field: dairy));
        await tester.enterText(find.widgetWithText(TextField, 'Milk'), '12.5');
        await choose(tester, 'From', 'KE-1 · Daisy');
        expect(find.text('KE-9'), findsNothing); // only females are milked
        await save(tester);
        expect(posted['/milk-records'], {'enterprise_id': 'e-dairy', 'date': posted['/milk-records']!['date'], 'litres': '12.5', 'animal_id': 'a-1'});
      }));

  testWidgets('pregnancy check finds the open service', (tester) => run(tester, () async {
        await show(tester, PregnancyCheckForm(field: dairy));
        await choose(tester, 'Female', 'KE-1 · Daisy');
        expect(find.textContaining('Served 1 Aug 2026'), findsOneWidget);
        await tester.tap(find.text('Pregnant'));
        await tester.pumpAndSettle();
        await save(tester);
        expect(posted['/breeding/b-1/check'], containsPair('pregnant', true));
      }));

  testWidgets('a calf is born', (tester) => run(tester, () async {
        await show(tester, BirthForm(field: dairy));
        await choose(tester, 'Mother', 'KE-1 · Daisy');
        await tester.enterText(find.widgetWithText(TextField, 'Tag'), 'KE-2');
        await save(tester);
        expect(find.text('Choose female or male.'), findsOneWidget);
        await tester.tap(find.text('Male').last);
        await tester.pumpAndSettle();
        await save(tester);
        expect(posted['/animals/a-1/births']!['offspring'], [{'tag': 'KE-2', 'sex': 'male', 'name': ''}]);
      }));

  testWidgets('a sale from a field, to a new customer, by M-Pesa code', (tester) => run(tester, () async {
        await show(tester, SaleForm(field: layers));
        await tester.tap(find.text('New customer'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Otieno');
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '5');
        await tester.enterText(find.widgetWithText(TextField, 'Price'), '400');
        await tester.pumpAndSettle();
        expect(find.text('Save sale · KES 2,000'), findsOneWidget);
        await tester.tap(find.text('M-Pesa code'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'M-Pesa code'), 'rjk4xy1234');
        await save(tester, 'Save sale · KES 2,000');
        final body = posted['/sales']!;
        expect(body['customer_id'], 'c-new');
        expect(body['lines'], [{'item_id': 'i-eggs', 'qty': '5', 'unit': 'tray', 'unit_price': '400', 'enterprise_id': 'e-layers'}]);
        expect(body['payment'], {'method': 'mpesa_code', 'code': 'RJK4XY1234'});
      }));

  testWidgets('an expense for a field', (tester) => run(tester, () async {
        await show(tester, MoneyForm(field: dairy));
        await tester.tap(find.text('Labour'));
        await tester.enterText(find.widgetWithText(TextField, 'Amount'), '800');
        await tester.pumpAndSettle();
        await save(tester);
        final body = posted['/finance/entries']!;
        expect(body['farm_id'], 'farm');
        expect(body['enterprise_id'], 'e-dairy');
        expect(body['category'], 'labour');
      }));

  testWidgets('server field errors show on the field', (tester) => http.runWithClient(() async {
        await show(tester, SampleWeightForm(field: layers));
        await tester.enterText(find.widgetWithText(TextField, 'How many were weighed'), '10');
        await tester.enterText(find.widgetWithText(TextField, 'Average weight'), '1.2');
        await save(tester);
        expect(find.text('Choose today or an earlier day.'), findsOneWidget);
        expect(find.text('Check the fields marked below.'), findsOneWidget);
      }, () => MockClient((r) async => json({'code': 'validation_error', 'message': 'Some fields are not valid.', 'params': {},
            'fields': {'date': ['Choose today or an earlier day.']}}, 400))));
}
