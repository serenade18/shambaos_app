import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shambaOS/services/app_theme.dart';
import 'package:shambaOS/widgets/skeleton.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme, bool still = false}) => tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
      ),
    ));

void main() {
  testWidgets('a loading screen is read out once, as Loading', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Column(children: [SkeletonBlocks([120, 88]), SkeletonLedger(rows: 4, title: true, figure: true)]));
    expect(find.bySemanticsLabel('Loading…'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('the skeletons lay out in both themes, and hold still with animations off', (tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await _pump(tester, const Column(children: [SkeletonLedger(rows: 5), SkeletonText()]), theme: theme);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(FadeTransition), findsWidgets);
    }
    await _pump(tester, const SkeletonLedger(), still: true);
    expect(find.descendant(of: find.byType(Skeleton), matching: find.byType(FadeTransition)), findsNothing);
  });
}
