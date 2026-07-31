import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lozenge_flutter_example/main.dart';

void main() {
  testWidgets('kitchen sink pumps', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LozengeDemoApp());
    // Repeating shimmer/spinner animations: pump a fixed duration instead of
    // settling.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Buttons'), findsOneWidget);
    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Skeletons'), findsOneWidget);
  });
}
