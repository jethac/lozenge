import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lozenge_flutter/lozenge_flutter.dart';

Widget harness(Widget child) {
  final data = LzThemeData.light();
  return LzTheme(
    data: data,
    child: MaterialApp(
      theme: data.toMaterialTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  final t = LzThemeData.light();

  group('LzButton', () {
    testWidgets('fires onPressed and paints interaction-bg', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(LzButton(onPressed: () => taps++, child: const Text('Save'))),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(taps, 1);

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(LzButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((container.decoration as BoxDecoration?)?.color, t.interactionBg);
    });

    testWidgets('primary variant paints accent-bold', (tester) async {
      await tester.pumpWidget(harness(LzButton(
        variant: LzButtonVariant.primary,
        onPressed: () {},
        child: const Text('Create'),
      )));
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(LzButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((container.decoration as BoxDecoration?)?.color, t.accentBold);
    });

    testWidgets('disabled button ignores taps', (tester) async {
      await tester.pumpWidget(
        harness(const LzButton(child: Text('Nope'))),
      );
      await tester.tap(find.text('Nope'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // No throw and still present — disabled state renders.
      expect(find.text('Nope'), findsOneWidget);
    });

    testWidgets('LzButtonGroup renders all members', (tester) async {
      await tester.pumpWidget(harness(LzButtonGroup([
        LzButton(onPressed: () {}, child: const Text('Board')),
        LzButton(onPressed: () {}, child: const Text('Backlog')),
        LzButton(onPressed: () {}, child: const Text('Timeline')),
      ])));
      expect(find.text('Board'), findsOneWidget);
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
    });
  });

  group('fields', () {
    testWidgets('LzTextField shows label/helper and reports changes',
        (tester) async {
      String? changed;
      await tester.pumpWidget(harness(SizedBox(
        width: 320,
        child: LzTextField(
          label: 'Name',
          helper: 'Your display name',
          onChanged: (v) => changed = v,
        ),
      )));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Your display name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Jetha');
      expect(changed, 'Jetha');

      final label = tester.widget<Text>(find.text('Name'));
      expect(label.style?.color, t.textSubtle);
    });

    testWidgets('LzSearchField shows magnifier and kbd chip', (tester) async {
      await tester.pumpWidget(harness(const SizedBox(
        width: 320,
        child: LzSearchField(hint: 'Search', kbdHint: '/'),
      )));
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('/'), findsOneWidget);
    });
  });

  group('controls', () {
    testWidgets('LzCheckbox toggles and paints accent-bold when checked',
        (tester) async {
      bool? value = false;
      await tester.pumpWidget(harness(StatefulBuilder(
        builder: (context, setState) => LzCheckbox(
          value: value,
          onChanged: (v) => setState(() => value = v),
          label: const Text('Done'),
        ),
      )));
      await tester.tap(find.byType(LzCheckbox));
      await tester.pumpAndSettle();
      expect(value, isTrue);

      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(LzCheckbox),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((box.decoration as BoxDecoration?)?.color, t.accentBold);
    });

    testWidgets('LzRadio selects its value', (tester) async {
      int? group = 1;
      await tester.pumpWidget(harness(StatefulBuilder(
        builder: (context, setState) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LzRadio<int>(
              value: 1,
              groupValue: group,
              onChanged: (v) => setState(() => group = v),
              label: const Text('One'),
            ),
            const SizedBox(width: 16),
            LzRadio<int>(
              value: 2,
              groupValue: group,
              onChanged: (v) => setState(() => group = v),
              label: const Text('Two'),
            ),
          ],
        ),
      )));
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(group, 2);
    });

    testWidgets('LzToggle flips its value on tap', (tester) async {
      var value = false;
      await tester.pumpWidget(harness(StatefulBuilder(
        builder: (context, setState) => LzToggle(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      )));
      await tester.tap(find.byType(LzToggle));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('overlays', () {
    testWidgets('showLzModal displays the title over a blanket barrier',
        (tester) async {
      await tester.pumpWidget(harness(Builder(
        builder: (context) => LzButton(
          onPressed: () => showLzModal<void>(
            context,
            builder: (_) => const LzModal(
              title: 'Delete issue?',
              danger: true,
              body: Text('This cannot be undone.'),
            ),
          ),
          child: const Text('Open'),
        ),
      )));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete issue?'), findsOneWidget);
      final barrier =
          tester.widgetList<ModalBarrier>(find.byType(ModalBarrier)).last;
      expect(barrier.color, t.blanket);
    });

    testWidgets('showLzDrawer slides in a side panel', (tester) async {
      await tester.pumpWidget(harness(Builder(
        builder: (context) => LzButton(
          onPressed: () => showLzDrawer<void>(
            context,
            builder: (_) => const Center(child: Text('Issue details')),
          ),
          child: const Text('Open drawer'),
        ),
      )));
      await tester.tap(find.text('Open drawer'));
      await tester.pumpAndSettle();
      expect(find.text('Issue details'), findsOneWidget);
    });

    testWidgets('LzMenuButton opens on trigger tap and closes on item tap',
        (tester) async {
      var moved = false;
      await tester.pumpWidget(harness(LzMenuButton(
        trigger: const Text('Status'),
        items: [
          const LzMenuHeading('Move to'),
          LzMenuItem(child: const Text('To do'), onTap: () => moved = true),
          const LzMenuDivider(),
          const LzMenuItem(selected: true, child: Text('Done')),
        ],
      )));
      expect(find.text('To do'), findsNothing);

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();
      expect(find.text('To do'), findsOneWidget);
      expect(find.text('MOVE TO'), findsOneWidget);

      await tester.tap(find.text('To do'));
      await tester.pumpAndSettle();
      expect(moved, isTrue);
      expect(find.text('To do'), findsNothing);
    });

    testWidgets('LzTooltip appears after the hover delay in tooltip colors',
        (tester) async {
      await tester.pumpWidget(harness(const LzTooltip(
        message: 'Assign to me',
        child: SizedBox(width: 40, height: 40),
      )));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(LzTooltip)));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Assign to me'), findsOneWidget);

      final bubble = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Assign to me'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((bubble.decoration as BoxDecoration).color, t.tooltipBg);

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('Assign to me'), findsNothing);
    });
  });
}
