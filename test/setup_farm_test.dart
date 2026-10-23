// A new farm: name and county, then the map, then "What are you adding?".
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shambaOS/screens/farm/add_to_farm.dart';
import 'package:shambaOS/screens/farm/farm_map_screen.dart';
import 'package:shambaOS/screens/farm/setup_farm_screen.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('setting up a farm creates it, then maps it, then asks what it runs', (tester) async {
    Map<String, dynamic>? sent;
    final client = MockClient((r) async {
      if (r.method == 'POST' && r.url.path.endsWith('/farms')) {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 'farm-1', ...sent!, 'boundary': null, 'location': null}), 201,
            headers: {'content-type': 'application/json'});
      }
      return http.Response(jsonEncode({'results': []}), 200, headers: {'content-type': 'application/json'});
    });
    await http.runWithClient(() async {
      tester.view.physicalSize = const Size(360 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      bool? made;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(child: ElevatedButton(onPressed: () async => made = await setUpFarm(context), child: const Text('go'))),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // Both are needed.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next: map your farm'));
      await tester.pumpAndSettle();
      expect(find.text("Enter the farm's name."), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Wanjiku Farm');
      await tester.tap(find.text('Choose the county'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Nyeri'), 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Nyeri'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next: map your farm'));
      await frames(tester);
      expect(sent, {'name': 'Wanjiku Farm', 'county': 'Nyeri'});
      expect(find.byType(FarmMapScreen), findsOneWidget);

      // Leaving the map goes on to what the farm runs; closing that ends the setup.
      Navigator.of(tester.element(find.byType(FarmMapScreen))).pop(false);
      await frames(tester);
      expect(find.byType(AddToFarmScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AddToFarmScreen))).pop(false);
      await frames(tester);
      expect(made, isTrue);
    }, () => client);
  });
}
