// Smoke tests for the content/status widget set: lozenge, badge, tag,
// avatar, card, board, message/banner/flag.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lozenge_flutter/lozenge_flutter.dart';

void main() {
  final theme = LzThemeData.light();

  Widget harness(Widget child) => LzTheme(
        data: theme,
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );

  group('LzLozenge', () {
    testWidgets('renders uppercase with bold status colors', (tester) async {
      await tester.pumpWidget(
        harness(const LzLozenge('Done', status: LzStatus.success, bold: true)),
      );
      final text = tester.widget<Text>(find.text('DONE'));
      expect(text.style!.color, theme.statusSuccessOnBold);
      expect(text.style!.fontWeight, FontWeight.w700);
      final container = tester.widget<Container>(find
          .ancestor(of: find.text('DONE'), matching: find.byType(Container))
          .first);
      expect(
        (container.decoration as BoxDecoration).color,
        theme.statusSuccessBoldBg,
      );
    });

    testWidgets('subtle variant uses subtle text color', (tester) async {
      await tester.pumpWidget(
        harness(const LzLozenge('In progress', status: LzStatus.info)),
      );
      expect(
        tester.widget<Text>(find.text('IN PROGRESS')).style!.color,
        theme.statusInfoSubtleText,
      );
    });
  });

  group('LzBadge', () {
    testWidgets('important appearance is danger-bold', (tester) async {
      await tester.pumpWidget(
        harness(const LzBadge('8', appearance: LzBadgeAppearance.important)),
      );
      final container = tester.widget<Container>(find
          .ancestor(of: find.text('8'), matching: find.byType(Container))
          .first);
      expect((container.decoration as BoxDecoration).color, theme.dangerBold);
      expect(
        tester.widget<Text>(find.text('8')).style!.color,
        theme.textOnBold,
      );
    });
  });

  group('LzTag', () {
    testWidgets('remove button fires onRemove', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        harness(LzTag('frontend', onRemove: () => removed = true)),
      );
      expect(find.text('frontend'), findsOneWidget);
      await tester.tap(find.text('×'));
      expect(removed, isTrue);
    });
  });

  group('LzAvatar', () {
    testWidgets('shows initials at md size', (tester) async {
      await tester.pumpWidget(
        harness(const LzAvatar(initials: 'JC', presence: LzPresence.online)),
      );
      expect(find.text('JC'), findsOneWidget);
      expect(tester.getSize(find.byType(LzAvatar)), const Size(32, 32));
      expect(
        tester.widget<Text>(find.text('JC')).style!.color,
        theme.textSubtle,
      );
    });

    testWidgets('group collapses past max into +N', (tester) async {
      await tester.pumpWidget(harness(const LzAvatarGroup(
        [
          LzAvatar(initials: 'AB'),
          LzAvatar(initials: 'CD'),
          LzAvatar(initials: 'EF'),
          LzAvatar(initials: 'GH'),
        ],
        max: 2,
      )));
      expect(find.text('AB'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
      expect(find.text('EF'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
      // 3 cells of 36 (32 avatar + 2px ring each side), overlapping by 12.
      expect(tester.getSize(find.byType(LzAvatarGroup)).width, 36 + 2 * 24);
    });
  });

  group('LzCard', () {
    testWidgets('renders header, body, footer on a raised surface',
        (tester) async {
      await tester.pumpWidget(harness(const LzCard(
        header: Text('Sprint 14'),
        footer: Text('Footer'),
        child: Text('Body'),
      )));
      expect(find.text('Sprint 14'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
      final outer = tester.widget<Container>(find
          .descendant(of: find.byType(LzCard), matching: find.byType(Container))
          .first);
      expect((outer.decoration as BoxDecoration).color, theme.surfaceRaised);
    });
  });

  group('LzIssueCard', () {
    testWidgets('renders meta row and handles taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(harness(SizedBox(
        width: 272,
        child: LzIssueCard(
          summary: 'Fix login redirect loop',
          type: LzIssueType.bug,
          issueKey: 'PROJ-42',
          meta: const [LzBadge('3')],
          trailing: const LzAvatar(initials: 'JC', size: LzAvatarSize.sm),
          onTap: () => tapped = true,
        ),
      )));
      expect(find.text('Fix login redirect loop'), findsOneWidget);
      expect(find.text('PROJ-42'), findsOneWidget);
      expect(find.byType(LzIssueTypeIcon), findsOneWidget);
      final square = tester.widget<Container>(find
          .descendant(
              of: find.byType(LzIssueTypeIcon),
              matching: find.byType(Container))
          .first);
      expect(
        (square.decoration as BoxDecoration).color,
        lzRamps['red']!['300']!.toColor(),
      );
      await tester.tap(find.byType(LzIssueCard));
      expect(tapped, isTrue);
    });
  });

  group('LzBoard', () {
    testWidgets('columns are 272 wide with uppercase headers and counts',
        (tester) async {
      await tester.pumpWidget(harness(LzBoard([
        LzBoardColumn(
          title: 'To do',
          count: 4,
          cards: const [LzIssueCard(summary: 'Ship the widget set')],
        ),
        const LzBoardColumn(title: 'Done', cards: []),
      ])));
      expect(find.text('TO DO'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Ship the widget set'), findsOneWidget);
      expect(tester.getSize(find.byType(LzBoardColumn).first).width, 272);
    });
  });

  group('LzMessage', () {
    testWidgets('fills with subtle bg and bold accent bar', (tester) async {
      await tester.pumpWidget(harness(const LzMessage(
        title: 'Heads up',
        status: LzStatus.warning,
        child: Text('Your trial expires in 3 days.'),
      )));
      expect(find.text('Heads up'), findsOneWidget);
      final colors = tester
          .widgetList<ColoredBox>(find.descendant(
              of: find.byType(LzMessage), matching: find.byType(ColoredBox)))
          .map((c) => c.color)
          .toList();
      expect(colors, contains(theme.statusWarningSubtleBg));
      expect(colors, contains(theme.statusWarningBoldBg));
    });
  });

  group('LzBanner', () {
    testWidgets('error appearance is danger-bold', (tester) async {
      await tester.pumpWidget(harness(const LzBanner(
        appearance: LzBannerAppearance.error,
        child: Text("Something's gone wrong"),
      )));
      final colors = tester
          .widgetList<ColoredBox>(find.descendant(
              of: find.byType(LzBanner), matching: find.byType(ColoredBox)))
          .map((c) => c.color);
      expect(colors, contains(theme.dangerBold));
    });
  });

  group('LzFlag', () {
    testWidgets('bold variant recolors all text to on-bold', (tester) async {
      await tester.pumpWidget(harness(LzFlag(
        title: 'Issue created',
        description: 'LOZ-42 has been added to the backlog.',
        boldStatus: LzStatus.success,
        onDismiss: () {},
      )));
      expect(tester.getSize(find.byType(LzFlag)).width, 400);
      expect(
        tester.widget<Text>(find.text('Issue created')).style!.color,
        theme.statusSuccessOnBold,
      );
      expect(
        tester
            .widget<Text>(find.text('LOZ-42 has been added to the backlog.'))
            .style!
            .color,
        theme.statusSuccessOnBold,
      );
    });

    testWidgets('default variant is a glass surface', (tester) async {
      await tester.pumpWidget(harness(const LzFlag(title: 'Saved')));
      expect(
        find.descendant(
            of: find.byType(LzFlag), matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
    });

    testWidgets('showLzFlag floats a toast and auto-dismisses',
        (tester) async {
      await tester.pumpWidget(harness(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showLzFlag(
            context,
            title: 'Issue created',
            duration: const Duration(seconds: 1),
          ),
          child: const Text('flag'),
        ),
      )));
      await tester.tap(find.text('flag'));
      await tester.pump();
      await tester.pump(LzMotion.slow);
      expect(find.text('Issue created'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(LzMotion.medium);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Issue created'), findsNothing);
    });
  });
}
