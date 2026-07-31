// Lozenge for Flutter — kitchen-sink demo mirroring the web demo pages.
//
// Every color on screen comes from the Lozenge token engine; the floating
// theme panel drives the scheme / contrast / accent / materials axes and
// AnimatedLzTheme sweeps the whole UI between states.
import 'package:flutter/material.dart';
import 'package:lozenge_flutter/lozenge_flutter.dart';

void main() => runApp(const LozengeDemoApp());

class LozengeDemoApp extends StatefulWidget {
  const LozengeDemoApp({super.key});

  @override
  State<LozengeDemoApp> createState() => _LozengeDemoAppState();
}

class _LozengeDemoAppState extends State<LozengeDemoApp> {
  LzThemeData _theme = LzThemeData.light();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lozenge for Flutter',
      debugShowCheckedModeBanner: false,
      theme: _theme.toMaterialTheme(),
      home: AnimatedLzTheme(
        data: _theme,
        child: DemoScreen(
          themeData: _theme,
          onThemeChanged: (t) => setState(() => _theme = t),
        ),
      ),
    );
  }
}

/// The demo shell: navbar over a scrolling widget gallery, with the theme
/// panel floating bottom-right.
class DemoScreen extends StatefulWidget {
  /// The target theme (the panel edits this; [LzTheme.of] animates toward it).
  final LzThemeData themeData;
  final ValueChanged<LzThemeData> onThemeChanged;

  const DemoScreen({
    super.key,
    required this.themeData,
    required this.onThemeChanged,
  });

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _tab = 0;
  int _page = 5;
  bool _subscribed = true;
  bool _notifications = false;
  bool? _agreed = false;
  bool _starred = true;
  String _priority = 'medium';
  final GlobalKey _menuAnchor = GlobalKey();
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Scaffold(
      backgroundColor: theme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                LzNavbar.height + 24,
                24,
                96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _breadcrumbs(),
                      _section('Buttons', _buttons(context)),
                      _section('Lozenges', _lozenges()),
                      _section('Badges, tags & avatars', _badges(theme)),
                      _section('Board', _board()),
                      _section('Messages', _messages()),
                      _section('Flags (toasts)', _flags(context)),
                      _section('Forms', _forms(theme)),
                      _section('Tabs', _tabs(theme)),
                      _section('Progress', _progress(theme)),
                      _section(
                        'Tracker',
                        const LzTracker(
                          steps: [
                            'Project details',
                            'Permissions',
                            'Invite team',
                            'Confirm',
                          ],
                          current: 2,
                        ),
                      ),
                      _section('Tree', _tree()),
                      _section('Sidebar & pagination', _navigation()),
                      _section('Comments', _comments()),
                      _section('Empty state', _emptyState(context)),
                      _section('Skeletons', _skeletons()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Navbar last so content scrolls behind its glass.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LzNavbar(
              brand: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hexagon_outlined),
                  SizedBox(width: 8),
                  Text('Lozenge'),
                ],
              ),
              items: [
                const LzNavLink(label: 'Your work', selected: true),
                LzNavLink(label: 'Projects', onTap: () {}),
                LzNavLink(label: 'Filters', onTap: () {}),
                LzNavLink(label: 'Dashboards', onTap: () {}),
              ],
              actions: [
                LzIconButton(
                  icon: const Icon(Icons.search),
                  variant: LzButtonVariant.subtle,
                  onPressed: () {},
                ),
                const LzAvatar(
                  initials: 'JC',
                  size: LzAvatarSize.sm,
                  presence: LzPresence.online,
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _ThemePanel(
              data: widget.themeData,
              onChanged: widget.onThemeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Builder(
      builder: (context) {
        final theme = LzTheme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 24 / 20,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _breadcrumbs() {
    return LzBreadcrumbs([
      LzBreadcrumb('Projects', onTap: () {}),
      LzBreadcrumb('Lozenge', onTap: () {}),
      const LzBreadcrumb('Kitchen sink'),
    ]);
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LzButton(
          variant: LzButtonVariant.primary,
          onPressed: () => _openModal(context),
          child: const Text('Create issue'),
        ),
        LzButton(
          onPressed: () => _openDrawer(context),
          child: const Text('Open drawer'),
        ),
        LzButton(
          variant: LzButtonVariant.subtle,
          onPressed: () {},
          child: const Text('Subtle'),
        ),
        LzButton(
          variant: LzButtonVariant.warning,
          onPressed: () {},
          child: const Text('Warning'),
        ),
        LzButton(
          variant: LzButtonVariant.danger,
          onPressed: () {},
          child: const Text('Delete'),
        ),
        LzButton(
          variant: LzButtonVariant.link,
          onPressed: () {},
          child: const Text('Link'),
        ),
        LzButton(
          variant: LzButtonVariant.subtleLink,
          onPressed: () {},
          child: const Text('Subtle link'),
        ),
        const LzButton(child: Text('Disabled')),
        LzButton(
          icon: const Icon(Icons.add),
          onPressed: () {},
          child: const Text('With icon'),
        ),
        LzButton(loading: true, onPressed: () {}, child: const Text('Loading')),
        LzButton(compact: true, onPressed: () {}, child: const Text('Compact')),
        LzButton(
          key: _menuAnchor,
          icon: const Icon(Icons.expand_more),
          onPressed: () =>
              showLzMenu(context, anchorKey: _menuAnchor, items: _menuItems()),
          child: const Text('Menu'),
        ),
      ],
    );
  }

  List<LzMenuEntry> _menuItems() {
    return [
      const LzMenuHeading('Move to'),
      LzMenuItem(child: const Text('To do'), onTap: () {}),
      LzMenuItem(
        selected: true,
        onTap: () {},
        child: const Text('In progress'),
      ),
      LzMenuItem(child: const Text('Done'), onTap: () {}),
      const LzMenuDivider(),
      LzMenuItem(
        description: 'This cannot be undone',
        danger: true,
        onTap: () {},
        child: const Text('Delete'),
      ),
    ];
  }

  Widget _lozenges() {
    const labels = {
      LzStatus.neutral: 'To do',
      LzStatus.info: 'In progress',
      LzStatus.warning: 'Moved',
      LzStatus.danger: 'Removed',
      LzStatus.success: 'Done',
      LzStatus.discovery: 'New',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in labels.entries) LzLozenge(e.value, status: e.key),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in labels.entries)
              LzLozenge(e.value, status: e.key, bold: true),
          ],
        ),
      ],
    );
  }

  Widget _badges(LzThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const LzBadge('25'),
        const LzBadge('4', appearance: LzBadgeAppearance.primary),
        const LzBadge('99+', appearance: LzBadgeAppearance.important),
        const LzBadge('+8', appearance: LzBadgeAppearance.added),
        const LzBadge('-5', appearance: LzBadgeAppearance.removed),
        LzTag('design-system', onRemove: () {}),
        const LzTag('flutter'),
        LzTag('rounded', rounded: true, onRemove: () {}),
        const LzAvatar(initials: 'JC', size: LzAvatarSize.xs),
        const LzAvatar(initials: 'DK', size: LzAvatarSize.sm),
        const LzAvatar(initials: 'RC', presence: LzPresence.online),
        const LzAvatar(
          initials: 'AM',
          size: LzAvatarSize.lg,
          presence: LzPresence.busy,
        ),
        const LzAvatar(initials: 'LZ', size: LzAvatarSize.lg, square: true),
        const LzAvatarGroup([
          LzAvatar(initials: 'JC'),
          LzAvatar(initials: 'DK'),
          LzAvatar(initials: 'RC'),
          LzAvatar(initials: 'AM'),
          LzAvatar(initials: 'TS'),
        ], max: 4),
      ],
    );
  }

  Widget _board() {
    return LzBoard([
      LzBoardColumn(
        title: 'To do',
        count: 3,
        cards: [
          LzIssueCard(
            summary: 'Port the token engine to Flutter',
            type: LzIssueType.epic,
            issueKey: 'LOZ-40',
            meta: const [LzLozenge('To do')],
            trailing: const LzAvatar(initials: 'JC', size: LzAvatarSize.xs),
            onTap: () {},
          ),
          LzIssueCard(
            summary: 'Skeleton shimmer respects reduced motion',
            type: LzIssueType.task,
            issueKey: 'LOZ-41',
            meta: const [LzLozenge('To do')],
            onTap: () {},
          ),
          LzIssueCard(
            summary: 'Navbar glass loses backdrop blur on web',
            type: LzIssueType.bug,
            issueKey: 'LOZ-42',
            meta: const [LzLozenge('To do'), LzBadge('3')],
            onTap: () {},
          ),
        ],
      ),
      LzBoardColumn(
        title: 'In progress',
        count: 2,
        cards: [
          LzIssueCard(
            summary: 'Structure widgets: navbar, sidebar, tabs, tracker',
            type: LzIssueType.story,
            issueKey: 'LOZ-43',
            meta: const [LzLozenge('In progress', status: LzStatus.info)],
            trailing: const LzAvatar(initials: 'DK', size: LzAvatarSize.xs),
            onTap: () {},
          ),
          LzIssueCard(
            summary: 'Kitchen-sink example app',
            type: LzIssueType.story,
            issueKey: 'LOZ-44',
            meta: const [LzLozenge('In progress', status: LzStatus.info)],
            onTap: () {},
          ),
        ],
      ),
      LzBoardColumn(
        title: 'Done',
        count: 2,
        cards: [
          LzIssueCard(
            summary: 'OKLCH → sRGB conversion parity with CSS',
            type: LzIssueType.task,
            issueKey: 'LOZ-38',
            meta: const [LzLozenge('Done', status: LzStatus.success)],
            onTap: () {},
          ),
          LzIssueCard(
            summary: 'Contrast dial coefficients',
            type: LzIssueType.task,
            issueKey: 'LOZ-39',
            meta: const [LzLozenge('Done', status: LzStatus.success)],
            trailing: const LzAvatar(initials: 'RC', size: LzAvatarSize.xs),
            onTap: () {},
          ),
        ],
      ),
    ]);
  }

  Widget _messages() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LzMessage(
          title: 'Heads up',
          status: LzStatus.neutral,
          child: Text('Sprint 14 starts on Monday.'),
        ),
        SizedBox(height: 8),
        LzMessage(
          title: 'Editing is limited',
          child: Text('This board is read-only while the sprint is active.'),
        ),
        SizedBox(height: 8),
        LzMessage(
          title: 'Storage almost full',
          status: LzStatus.warning,
          child: Text('You have used 90% of your attachment quota.'),
        ),
        SizedBox(height: 8),
        LzMessage(
          title: "We couldn't save your changes",
          status: LzStatus.danger,
          child: Text('Check your connection and try again.'),
        ),
        SizedBox(height: 8),
        LzMessage(
          title: 'Issue created',
          status: LzStatus.success,
          child: Text('LOZ-45 was added to the backlog.'),
        ),
        SizedBox(height: 8),
        LzMessage(
          title: 'Try the new board view',
          status: LzStatus.discovery,
          child: Text('Group issues by epic with the layout switcher.'),
        ),
      ],
    );
  }

  Widget _flags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LzButton(
          onPressed: () => showLzFlag(
            context,
            title: 'Issue created',
            description: 'LOZ-45 was added to the backlog.',
          ),
          child: const Text('Show flag'),
        ),
        LzButton(
          onPressed: () => showLzFlag(
            context,
            title: 'Sprint completed',
            description: '12 issues done, 2 rolled over.',
            boldStatus: LzStatus.success,
          ),
          child: const Text('Bold success'),
        ),
        LzButton(
          onPressed: () => showLzFlag(
            context,
            title: 'Connection lost',
            description: 'Retrying in 10 seconds…',
            boldStatus: LzStatus.danger,
          ),
          child: const Text('Bold danger'),
        ),
      ],
    );
  }

  Widget _forms(LzThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LzSearchField(hint: 'Search issues', kbdHint: '/'),
          const SizedBox(height: 16),
          const LzTextField(
            label: 'Summary',
            hint: 'What needs doing?',
            helper: 'Keep it short and scannable.',
          ),
          const SizedBox(height: 16),
          const LzTextField(
            label: 'Description',
            hint: 'Add more detail…',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const LzTextField(
            label: 'Story points',
            hint: 'e.g. 3',
            compact: true,
            error: 'Story points must be a number.',
          ),
          const SizedBox(height: 16),
          LzCheckbox(
            value: _agreed,
            tristate: true,
            onChanged: (v) => setState(() => _agreed = v),
            label: const Text('Notify watchers (tristate)'),
          ),
          const SizedBox(height: 8),
          LzCheckbox(
            value: _starred,
            onChanged: (v) => setState(() => _starred = v ?? false),
            label: const Text('Star this project'),
          ),
          const SizedBox(height: 12),
          for (final p in const ['low', 'medium', 'high'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LzRadio<String>(
                value: p,
                groupValue: _priority,
                onChanged: (v) => setState(() => _priority = v),
                label: Text('${p[0].toUpperCase()}${p.substring(1)} priority'),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              LzToggle(
                value: _subscribed,
                onChanged: (v) => setState(() => _subscribed = v),
              ),
              const SizedBox(width: 8),
              Text('Watch this issue', style: TextStyle(color: theme.text)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              LzToggle(
                value: _notifications,
                large: true,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              const SizedBox(width: 8),
              Text('Email notifications', style: TextStyle(color: theme.text)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabs(LzThemeData theme) {
    return LzTabs(
      tabs: const ['Details', 'Comments', 'History'],
      index: _tab,
      onChanged: (i) => setState(() => _tab = i),
      panes: [
        Text(
          'All the issue fields live here.',
          style: TextStyle(color: theme.textSubtle),
        ),
        Text(
          '3 comments, most recent first.',
          style: TextStyle(color: theme.textSubtle),
        ),
        Text(
          'Changelog of status transitions.',
          style: TextStyle(color: theme.textSubtle),
        ),
      ],
    );
  }

  Widget _progress(LzThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LzProgressBar(value: 0.6),
        const SizedBox(height: 8),
        const LzProgressBar(value: 0.9, status: LzStatus.success),
        const SizedBox(height: 8),
        const LzProgressBar(value: 0.35, status: LzStatus.warning),
        const SizedBox(height: 8),
        const LzProgressBar(value: 0.15, status: LzStatus.danger),
        const SizedBox(height: 16),
        Row(
          children: [
            const LzSpinner(),
            const SizedBox(width: 12),
            const LzSpinner(size: 32),
            const SizedBox(width: 12),
            Text('Loading…', style: TextStyle(color: theme.textSubtle)),
          ],
        ),
      ],
    );
  }

  Widget _tree() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: LzTree([
        LzTreeNode(
          label: 'scss',
          icon: const Icon(Icons.folder_outlined),
          initiallyExpanded: true,
          children: [
            LzTreeNode(
              label: 'components',
              icon: const Icon(Icons.folder_outlined),
              children: [
                LzTreeNode(label: '_navbar.scss', onTap: () {}),
                LzTreeNode(label: '_tracker.scss', onTap: () {}),
              ],
            ),
            LzTreeNode(label: '_tokens.scss', selected: true, onTap: () {}),
            LzTreeNode(label: '_mixins.scss', onTap: () {}),
          ],
        ),
        LzTreeNode(
          label: 'packages',
          icon: const Icon(Icons.folder_outlined),
          children: [LzTreeNode(label: 'lozenge_flutter', onTap: () {})],
        ),
        LzTreeNode(label: 'package.json', onTap: () {}),
      ]),
    );
  }

  Widget _navigation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 320,
          child: LzSidebar(
            header: const Row(
              children: [
                LzAvatar(initials: 'LZ', size: LzAvatarSize.sm, square: true),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lozenge',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Software project', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              LzSidebarGroup(
                title: 'Planning',
                children: [
                  const LzSidebarItem(
                    label: 'Board',
                    icon: Icons.view_kanban_outlined,
                    selected: true,
                  ),
                  LzSidebarItem(
                    label: 'Backlog',
                    icon: Icons.list_alt_outlined,
                    onTap: () {},
                  ),
                  LzSidebarItem(
                    label: 'Timeline',
                    icon: Icons.timeline_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              LzSidebarGroup(
                title: 'Development',
                children: [
                  LzSidebarItem(label: 'Code', icon: Icons.code, onTap: () {}),
                  LzSidebarItem(
                    label: 'Releases',
                    icon: Icons.rocket_launch_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LzPagination(
          page: _page,
          pageCount: 12,
          onChanged: (p) => setState(() => _page = p),
        ),
      ],
    );
  }

  Widget _comments() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: LzCommentThread([
        LzComment(
          author: 'Dana Kim',
          time: '2 hours ago',
          avatarInitials: 'DK',
          body: const Text(
            'The tracker connectors should pick up the success color for '
            'completed segments — matches the web build now.',
          ),
          actions: [
            _commentAction('Reply'),
            _commentAction('Edit'),
            _commentAction('Like'),
          ],
          replies: [
            LzComment(
              author: 'Jetha Chan',
              time: '1 hour ago',
              avatarInitials: 'JC',
              body: const Text(
                'Confirmed, shipping it with the next token '
                'regen.',
              ),
              actions: [_commentAction('Reply')],
            ),
          ],
        ),
        LzComment(
          author: 'Riley Chen',
          time: '30 minutes ago',
          avatarInitials: 'RC',
          body: const Text('Glass navbar looks great with the new blur.'),
          actions: [_commentAction('Reply')],
        ),
        LzCommentEditor(controller: _comment, avatarInitials: 'JC'),
      ]),
    );
  }

  Widget _commentAction(String label) {
    return Builder(
      builder: (context) {
        final theme = LzTheme.of(context);
        return GestureDetector(
          onTap: () {},
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              label,
              style: TextStyle(color: theme.textSubtle, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return LzEmptyState(
      media: const Text('∅'),
      title: 'The backlog is empty',
      description:
          'Create issues to plan your next sprint, or import them from '
          'another tracker.',
      actions: [
        LzButton(
          variant: LzButtonVariant.primary,
          onPressed: () => _openModal(context),
          child: const Text('Create issue'),
        ),
        LzButton(onPressed: () {}, child: const Text('Import issues')),
      ],
    );
  }

  Widget _skeletons() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LzSkeleton.avatar(size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LzSkeleton(width: 160, height: 20),
                SizedBox(height: 8),
                LzSkeleton.text(),
                SizedBox(height: 8),
                LzSkeleton.text(width: 220),
                SizedBox(height: 16),
                LzSkeleton.card(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openModal(BuildContext context) {
    showLzModal<void>(
      context,
      builder: (context) => LzModal(
        title: 'Create issue',
        body: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LzTextField(label: 'Summary', hint: 'What needs doing?'),
            SizedBox(height: 16),
            LzTextField(
              label: 'Description',
              hint: 'Add more detail…',
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          LzButton(
            variant: LzButtonVariant.subtle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          LzButton(
            variant: LzButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showLzDrawer<void>(
      context,
      builder: (context) {
        final theme = LzTheme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Issue details',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  LzIconButton(
                    icon: const Icon(Icons.close),
                    variant: LzButtonVariant.subtle,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const LzLozenge('In progress', status: LzStatus.info),
              const SizedBox(height: 16),
              Text(
                'A glass side sheet sliding in from the edge — the same '
                'panel recipe as the modal, full height.',
                style: TextStyle(color: theme.textSubtle),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The floating theme panel: every control writes a new [LzThemeData] and
/// [AnimatedLzTheme] sweeps the whole page toward it.
class _ThemePanel extends StatelessWidget {
  final LzThemeData data;
  final ValueChanged<LzThemeData> onChanged;

  const _ThemePanel({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final label = TextStyle(
      color: theme.textSubtle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
    return SizedBox(
      width: 280,
      child: LzCard(
        header: const Text('Theme'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DARK', style: label),
                LzToggle(
                  value: data.dark,
                  onChanged: (v) => onChanged(data.copyWith(dark: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('CONTRAST', style: label),
            _slider(
              value: data.contrast,
              min: -1,
              max: 1,
              onChanged: (v) => onChanged(data.copyWith(contrast: v)),
            ),
            Text('ACCENT HUE', style: label),
            _slider(
              value: data.accentHue,
              min: 0,
              max: 360,
              onChanged: (v) => onChanged(data.copyWith(accentHue: v)),
            ),
            Text('CHROMA', style: label),
            _slider(
              value: data.accentChroma,
              min: 0,
              max: 1.4,
              onChanged: (v) => onChanged(data.copyWith(accentChroma: v)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GLASS', style: label),
                LzToggle(
                  value: data.glass > 0,
                  onChanged: (v) => onChanged(data.copyWith(glass: v ? 1 : 0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 4,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}
