// Smoke tests for the structure widget families:
// navigation, progress, and content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lozenge_flutter/lozenge_flutter.dart';

Widget harness(Widget child, {LzThemeData? theme}) {
  return LzTheme(
    data: theme ?? LzThemeData.light(),
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  final theme = LzThemeData.light();

  group('navbar', () {
    testWidgets('renders brand, links and actions', (tester) async {
      await tester.pumpWidget(harness(
        const Column(
          children: [
            LzNavbar(
              brand: Text('Lozenge'),
              items: [
                LzNavLink(label: 'Your work', selected: true),
                LzNavLink(label: 'Projects'),
              ],
              actions: [Icon(Icons.settings)],
            ),
          ],
        ),
      ));
      expect(find.text('Lozenge'), findsOneWidget);
      expect(find.text('Your work'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      // 56px tall.
      expect(tester.getSize(find.byType(LzNavbar)).height, 56);
    });

    testWidgets('primary variant paints the accent color', (tester) async {
      await tester.pumpWidget(harness(
        const Column(
          children: [LzNavbar(primary: true, brand: Text('Lozenge'))],
        ),
      ));
      final container = tester.widget<Container>(
        find
            .descendant(
                of: find.byType(LzNavbar), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, theme.accentBold);
    });
  });

  group('sidebar', () {
    testWidgets('items show selection colors and groups collapse',
        (tester) async {
      await tester.pumpWidget(harness(
        SizedBox(
          height: 400,
          child: LzSidebar(
            header: const Text('Project'),
            children: [
              const LzSidebarItem(
                  label: 'Board', icon: Icons.view_kanban, selected: true),
              const LzSidebarItem(label: 'Backlog'),
              LzSidebarGroup(
                title: 'Development',
                children: const [LzSidebarItem(label: 'Code')],
              ),
            ],
          ),
        ),
      ));
      expect(tester.getSize(find.byType(LzSidebar)).width, 240);

      // Color assertion: the selected item is painted selected-bg.
      final selected = tester.widget<Container>(
        find.descendant(
          of: find.widgetWithText(LzSidebarItem, 'Board'),
          matching: find.byType(Container),
        ),
      );
      expect((selected.decoration as BoxDecoration).color, theme.selectedBg);

      // Group starts expanded; tapping the title collapses it.
      expect(find.text('Code'), findsOneWidget);
      await tester.tap(find.text('DEVELOPMENT'));
      await tester.pumpAndSettle();
      expect(find.text('Code'), findsNothing);
    });
  });

  group('tabs', () {
    testWidgets('switching tabs fires onChanged and swaps panes',
        (tester) async {
      var index = 0;
      await tester.pumpWidget(harness(
        StatefulBuilder(
          builder: (context, setState) => LzTabs(
            tabs: const ['Details', 'Comments'],
            index: index,
            onChanged: (i) => setState(() => index = i),
            panes: const [Text('Pane one'), Text('Pane two')],
          ),
        ),
      ));
      expect(find.text('Pane one'), findsOneWidget);
      await tester.tap(find.text('Comments'));
      await tester.pump();
      expect(index, 1);
      expect(find.text('Pane two'), findsOneWidget);
      expect(find.text('Pane one'), findsNothing);
    });
  });

  group('breadcrumbs', () {
    testWidgets('interleaves "/" separators', (tester) async {
      await tester.pumpWidget(harness(
        LzBreadcrumbs([
          LzBreadcrumb('Projects', onTap: () {}),
          LzBreadcrumb('Lozenge', onTap: () {}),
          const LzBreadcrumb('LOZ-1'),
        ]),
      ));
      expect(find.text('/'), findsNWidgets(2));
      expect(find.text('LOZ-1'), findsOneWidget);
    });
  });

  group('pagination', () {
    testWidgets('elides pages and fires onChanged', (tester) async {
      int? tapped;
      await tester.pumpWidget(harness(
        LzPagination(
          page: 5,
          pageCount: 9,
          onChanged: (p) => tapped = p,
        ),
      ));
      // 1 … 4 5 6 … 9
      expect(find.text('…'), findsNWidgets(2));
      expect(find.text('2'), findsNothing);
      await tester.tap(find.text('6'));
      expect(tapped, 6);
      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(tapped, 4);
    });
  });

  group('progress', () {
    testWidgets('bar paints track and accent fill', (tester) async {
      await tester.pumpWidget(harness(
        const SizedBox(width: 200, child: LzProgressBar(value: 0.5)),
      ));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(LzProgressBar)).height, 6);
      // Color assertion: the fill is accent-bold.
      final fill = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(LzProgressBar),
            matching: find.byType(Container),
          ))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .toList();
      expect(fill, contains(theme.accentBold));
    });

    testWidgets('spinner spins', (tester) async {
      await tester.pumpWidget(harness(const LzSpinner()));
      expect(tester.getSize(find.byType(LzSpinner)).width, 16);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LzSpinner), findsOneWidget);
    });

    testWidgets('skeleton variants render', (tester) async {
      await tester.pumpWidget(harness(
        const Column(
          children: [
            SizedBox(width: 200, child: LzSkeleton.text()),
            LzSkeleton.avatar(size: 24),
            SizedBox(width: 200, child: LzSkeleton.card()),
          ],
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LzSkeleton), findsNWidgets(3));
      expect(
        tester.getSize(find.byType(LzSkeleton).at(2)).height,
        84,
      );
    });

    testWidgets('tracker marks done, current and upcoming steps',
        (tester) async {
      await tester.pumpWidget(harness(
        const SizedBox(
          width: 500,
          child: LzTracker(
            steps: ['Details', 'Permissions', 'Confirm'],
            current: 1,
          ),
        ),
      ));
      // Done step swaps its number for a check.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('content', () {
    testWidgets('empty state centers title, description and actions',
        (tester) async {
      await tester.pumpWidget(harness(
        LzEmptyState(
          media: const Text('∅'),
          title: 'The backlog is empty',
          description: 'Create issues to plan your next sprint.',
          actions: [TextButton(onPressed: () {}, child: const Text('Create'))],
        ),
      ));
      expect(find.text('The backlog is empty'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      // Color assertion: the media circle is surface-sunken.
      final media = tester.widget<Container>(
        find
            .ancestor(of: find.text('∅'), matching: find.byType(Container))
            .first,
      );
      expect((media.decoration as BoxDecoration).color, theme.surfaceSunken);
    });

    testWidgets('comment thread nests replies and shows the editor',
        (tester) async {
      await tester.pumpWidget(harness(
        SingleChildScrollView(
          child: LzCommentThread([
            LzComment(
              author: 'Dana Kim',
              time: '2 hours ago',
              avatarInitials: 'DK',
              body: const Text('Looks good to me.'),
              actions: const [Text('Reply')],
              replies: const [
                LzComment(
                  author: 'Riley Chen',
                  time: '1 hour ago',
                  body: Text('Agreed.'),
                ),
              ],
            ),
            const LzCommentEditor(hint: 'Add a comment…'),
          ]),
        ),
      ));
      expect(find.text('Dana Kim'), findsOneWidget);
      expect(find.text('DK'), findsOneWidget);
      expect(find.text('Agreed.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tree expands branches on tap', (tester) async {
      await tester.pumpWidget(harness(
        const SizedBox(
          width: 300,
          child: LzTree([
            LzTreeNode(
              label: 'scss',
              children: [
                LzTreeNode(label: '_tokens.scss', selected: true),
              ],
            ),
            LzTreeNode(label: 'package.json'),
          ]),
        ),
      ));
      expect(find.text('_tokens.scss'), findsNothing);
      await tester.tap(find.text('scss'));
      await tester.pumpAndSettle();
      expect(find.text('_tokens.scss'), findsOneWidget);
    });
  });
}
