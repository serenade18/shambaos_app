import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shambaOS/screens/farm/farm_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const farm = {'id': 'f1', 'name': 'Wanjiku Farm', 'county': 'Nyeri', 'location': null, 'boundary': null};

  Future<void> openMap(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => TextButton(onPressed: () => FarmMapScreen.open(context, farm), child: const Text('open'))),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  testWidgets('"Later" stops sign-in offering the map for that farm', (t) async {
    SharedPreferences.setMockInitialValues({});
    expect(await FarmMapScreen.putOff('f1'), isFalse);
    await openMap(t);
    await t.tap(find.text('Later. Use Nyeri county for now'));
    await t.pumpAndSettle();
    expect(find.byType(FarmMapScreen), findsNothing);
    expect(await FarmMapScreen.putOff('f1'), isTrue);
    expect(await FarmMapScreen.putOff('another farm'), isFalse);
  });

  testWidgets('backing out of the start screen counts as "Later"', (t) async {
    SharedPreferences.setMockInitialValues({});
    await openMap(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(FarmMapScreen), findsNothing);
    expect(await FarmMapScreen.putOff('f1'), isTrue);
  });

  testWidgets('choosing a way to map does not put it off', (t) async {
    SharedPreferences.setMockInitialValues({});
    await openMap(t);
    await t.tap(find.text('Draw it on the map'));
    await t.pumpAndSettle();
    expect(find.text('Tap each corner in order'), findsOneWidget);
    expect(await FarmMapScreen.putOff('f1'), isFalse);
  });
}
