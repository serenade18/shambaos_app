import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shambaOS/services/api_service.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shambaOS/screens/home_screen.dart';
import 'package:shambaOS/screens/fields/field_service.dart';
import 'package:shambaOS/screens/fields/fields_screen.dart';
import 'package:shambaOS/screens/fields/field_scan_screen.dart';
import 'package:shambaOS/screens/fields/field_detail_screen.dart';

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

final ents = jsonDecode("{\"bananas\": {\"id\": \"01a1411a-1b9a-75f2-8670-3d24e534b5cf\", \"farm_id\": \"01a1411a-1b25-7156-a38c-91d268249728\", \"type\": \"bananas\", \"module\": \"crops\", \"name\": \"Bananas orchard\", \"status\": \"active\", \"started_on\": \"2026-10-15\", \"closed_on\": null, \"structure_id\": null, \"plot_id\": \"01a1411a-1b98-74b9-b363-f4a6d49bd7d1\", \"head_count\": null, \"start_count\": null, \"variety\": null, \"area_acres\": \"1.00\", \"plant_count\": null}, \"dairy_cattle\": {\"id\": \"01a1411a-1b7f-71e2-9d82-6616c19ddcbb\", \"farm_id\": \"01a1411a-1b25-7156-a38c-91d268249728\", \"type\": \"dairy_cattle\", \"module\": \"livestock\", \"name\": \"Dairy herd\", \"status\": \"active\", \"started_on\": \"2026-10-15\", \"closed_on\": null, \"structure_id\": null, \"plot_id\": null, \"head_count\": 5, \"start_count\": 5, \"variety\": null, \"area_acres\": null, \"plant_count\": null}, \"layers\": {\"id\": \"01a1411a-1b88-749e-856d-3be5e61507d5\", \"farm_id\": \"01a1411a-1b25-7156-a38c-91d268249728\", \"type\": \"layers\", \"module\": \"batches\", \"name\": \"Layers, batch 1\", \"status\": \"active\", \"started_on\": \"2026-10-15\", \"closed_on\": null, \"structure_id\": null, \"plot_id\": null, \"head_count\": 300, \"start_count\": 300, \"variety\": null, \"area_acres\": null, \"plant_count\": null}, \"maize\": {\"id\": \"01a1411a-1b94-7261-88fd-fff37fede957\", \"farm_id\": \"01a1411a-1b25-7156-a38c-91d268249728\", \"type\": \"maize\", \"module\": \"crops\", \"name\": \"Maize, short rains\", \"status\": \"active\", \"started_on\": \"2026-10-15\", \"closed_on\": null, \"structure_id\": null, \"plot_id\": \"01a1411a-1b8d-74b0-8d1a-c45bdea2e671\", \"head_count\": null, \"start_count\": null, \"variety\": null, \"area_acres\": \"2.00\", \"plant_count\": null}}") as Map<String, dynamic>;
Field field(String type) => Field(Map<String, dynamic>.from(ents[type]));

void main() {
  setUpAll(() async {
    await loadFont('ZillaSlab', ['fonts/ZillaSlab-Medium.ttf', 'fonts/ZillaSlab-SemiBold.ttf', 'fonts/ZillaSlab-Bold.ttf']);
    await loadFont('Atkinson', ['fonts/AtkinsonHyperlegibleNext-Regular.ttf', 'fonts/AtkinsonHyperlegibleNext-Bold.ttf']);
    await loadFont('AtkinsonMono', ['fonts/AtkinsonHyperlegibleMono-Regular.ttf', 'fonts/AtkinsonHyperlegibleMono-Medium.ttf']);
    await loadFont('PhosphorRegular', ['fonts/Phosphor-Regular.ttf']);
    await loadFont('PhosphorBold', ['fonts/Phosphor-Bold.ttf']);
    await loadFont('PhosphorFill', ['fonts/Phosphor-Fill.ttf']);
    final mi = File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    if (mi.existsSync()) await loadFont('MaterialIcons', [mi.path]);
  });

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'fields': () => const FieldsScreen(),
    'scan': () => FieldScanScreen(field: field('maize')),
    'detail_maize': () => FieldDetailScreen(field: field('maize')),
    'detail_layers': () => FieldDetailScreen(field: field('layers')),
  };
  for (final e in screens.entries) {
    for (final dark in [false, true]) {
      testWidgets('${e.key} ${dark ? 'dark' : 'light'}', (tester) async {
        HttpOverrides.global = null;
        SharedPreferences.setMockInitialValues({
          'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzkyMDk0NDkyLCJpYXQiOjE3OTIwOTM1OTIsImp0aSI6Ijk3MjhmNjgyN2JhYTQ0OGJiMjBiYWYwMTQyNGI1ZDg2IiwidXNlcl9pZCI6IjAxYTE0MTFhLTFhN2EtNzdmNS1hMmY5LWMxNWEwNjU3NWE1OSIsImRldmljZV9pZCI6IjAxYTE0MTFhLTFhOWUtNzZlNy05NzY4LWJiM2ZiNWIzMGNiOCJ9.jshwj2XS49_QDXhhp0lyZVJdyIamG4_aZql4g8-An4c', 'org_id': '01a1411a-1a84-71e2-b065-08fcbbd740f7', 'org_currency': 'KES', 'user': "{\"id\": \"01a1411a-1a7a-77f5-a2f9-c15a06575a59\", \"phone\": \"+254729956977\", \"name\": \"Wanjiku Kamau\", \"email\": null, \"email_verified\": false, \"username\": null, \"preferred_locale\": \"sw\", \"date_joined\": \"2026-10-15T22:46:32.186278+03:00\", \"is_staff\": false, \"has_password\": false}",
        });
        await ApiService.init();
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3;
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(), darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: e.value(),
        ));
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/${e.key}_${dark ? 'dark' : 'light'}.png'));
      });
    }
  }
}
