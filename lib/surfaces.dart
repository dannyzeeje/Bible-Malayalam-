part of 'main.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final tone = toneOf(context);
    return ColoredBox(color: tone.background, child: child);
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool? dark;
  final bool translucent;
  final double? glassOpacity;
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.dark,
    this.translucent = false,
    this.glassOpacity,
  });
  @override
  Widget build(BuildContext context) {
    final tone = toneOf(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: tone.mode == 2
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: tone.mode == 2 ? 0.08 : 0.018,
                  ),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tone.border, width: .7),
            color: translucent
                ? null
                : Color.alphaBlend(tone.panelA, tone.background),
            gradient: !translucent
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: translucent
                        ? [
                            tone.panelA.withValues(
                              alpha: glassOpacity ?? tone.panelA.a,
                            ),
                            tone.panelB.withValues(
                              alpha: glassOpacity ?? tone.panelB.a,
                            ),
                          ]
                        : [
                            Color.alphaBlend(tone.panelA, tone.background),
                            Color.alphaBlend(tone.panelB, tone.background),
                          ],
                  ),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

Widget glassIcon(
  IconData icon,
  String label,
  VoidCallback? onTap, {
  bool dark = false,
}) => Builder(
  builder: (context) => SizedBox.square(
    dimension: 44,
    child: FloatingGlass(
      radius: 999,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: 44, height: 44),
        icon: AppIcon(icon, size: 19, color: uiInk(context)),
      ),
    ),
  ),
);
Widget primaryPill(String label, VoidCallback? onTap, {IconData? icon}) =>
    Builder(
      builder: (context) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: uiAccent(context),
          foregroundColor: uiOnAccent(context),
          shape: StadiumBorder(),
          minimumSize: Size(44, 44),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[AppIcon(icon, size: 16), SizedBox(width: 7)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
Widget pageHeader(BuildContext context, String title, {Widget? trailing}) =>
    Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          glassIcon(
            CupertinoIcons.chevron_left,
            'Back',
            () => Navigator.pop(context),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -.6,
              ),
            ),
          ),
          trailing ?? SizedBox.square(dimension: 44),
        ],
      ),
    );

class PlanDetail extends StatelessWidget {
  final BibleStore store;
  final ReadingPlan plan;
  const PlanDetail({super.key, required this.store, required this.plan});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final done = store.planCompleted[plan.id] ?? <int>{};
      return Scaffold(
        body: AppBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                pageHeader(
                  context,
                  plan.title,
                  trailing: plan.custom
                      ? glassIcon(
                          CupertinoIcons.trash,
                          'Delete plan',
                          () => deleteCustomPlan(context, store, plan),
                        )
                      : null,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: GlassPanel(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${done.length} of ${plan.days} days complete',
                            style: TextStyle(
                              fontSize: 13,
                              color: uiMuted(context),
                            ),
                          ),
                        ),
                        primaryPill(
                          store.activePlan == plan.id ? 'Resume' : 'Start plan',
                          () {
                            store.activePlan = plan.id;
                            store.changed();
                            save(context, store);
                            final day = store.nextPlanDay(plan);
                            if (day < plan.days) {
                              showPlanDay(context, store, plan, day);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.days,
                    padding: EdgeInsets.fromLTRB(22, 0, 22, 24),
                    itemBuilder: (context, day) => dayTile(context, day, done),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget dayTile(BuildContext context, int day, Set<int> done) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: GlassPanel(
      radius: 20,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(8, 6, 14, 6),
        leading: IconButton(
          tooltip: done.contains(day)
              ? 'Mark day ${day + 1} unread'
              : 'Complete day ${day + 1}',
          onPressed: () {
            store.activePlan = plan.id;
            store.completePlanDay(plan, day, !done.contains(day));
            save(context, store);
          },
          icon: AppIcon(
            done.contains(day)
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: uiAccent(context),
            size: 23,
          ),
        ),
        title: Text(
          'Day ${day + 1}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            store.planChapters(plan, day).map(chapterLabel).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: uiMuted(context),
            ),
          ),
        ),
        trailing: AppIcon(
          CupertinoIcons.chevron_right,
          size: 13,
          color: uiMuted(context),
        ),
        onTap: () => showPlanDay(context, store, plan, day),
      ),
    ),
  );
}

Future<void> showPlanDay(
  BuildContext context,
  BibleStore s,
  ReadingPlan plan,
  int day,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (sheet) {
    final keys = s.planChapters(plan, day);
    final maximum = MediaQuery.sizeOf(sheet).height * .78;
    final height = (keys.length * 56.0 + 144).clamp(220.0, maximum);
    return GlassPanel(
      radius: 30,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              children: [
                sheetGrip(context),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${plan.title} · Day ${day + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: uiInk(sheet),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('plan-day-chapters'),
                    padding: EdgeInsets.zero,
                    itemCount: keys.length,
                    itemBuilder: (context, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        chapterLabel(keys[i]),
                        style: TextStyle(fontSize: 15, color: uiInk(context)),
                      ),
                      onTap: () => openReader(
                        sheet,
                        s,
                        verse: s.chapters[keys[i]]!.first,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: primaryPill('Mark day complete', () {
                    s.activePlan = plan.id;
                    s.completePlanDay(plan, day, true);
                    save(context, s);
                    Navigator.pop(sheet);
                  }, icon: CupertinoIcons.checkmark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);

class SettingsPage extends StatelessWidget {
  final BibleStore store;
  const SettingsPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final s = store;
      void update(VoidCallback apply) {
        apply();
        s.changed();
        save(context, s);
      }

      return Scaffold(
        body: AppBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                pageHeader(context, 'Settings'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    children: [
                      settingsGroup(context, 'Appearance', [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: ThemeTiles(store: s),
                        ),
                        settingsRow(
                          context,
                          CupertinoIcons.textformat,
                          'Text & layout',
                          value:
                              '${readingFonts[s.fontFamily]} · ${s.fontSize.round()}',
                          onTap: () => appearance(context, s),
                        ),
                      ]),
                      settingsGroup(context, 'Reader', [
                        iosSwitchRow(
                          'Verse numbers',
                          s.numbers,
                          (v) => update(() => s.numbers = v),
                        ),
                        iosSwitchRow(
                          'Hide controls on scroll',
                          s.autoHide,
                          (v) => update(() => s.autoHide = v),
                        ),
                        iosSwitchRow(
                          'Keep screen awake',
                          s.keepAwake,
                          (v) => update(() => s.keepAwake = v),
                        ),
                      ]),
                      settingsGroup(context, 'Highlight color', [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < highlightPalette.length; i++)
                                colorChoice(
                                  i,
                                  s.defaultHighlight == i,
                                  () => update(() => s.defaultHighlight = i),
                                ),
                            ],
                          ),
                        ),
                      ]),
                      settingsGroup(context, 'Saved data', [
                        settingsRow(
                          context,
                          CupertinoIcons.tag,
                          'Manage tags',
                          onTap: () => manageTags(context, s),
                        ),
                        settingsRow(
                          context,
                          CupertinoIcons.square_arrow_up,
                          'Back up saved data',
                          onTap: () => backupData(context, s, false),
                        ),
                        settingsRow(
                          context,
                          CupertinoIcons.square_arrow_down,
                          'Restore saved data',
                          onTap: () => backupData(context, s, true),
                        ),
                      ]),
                      settingsGroup(context, 'General', [
                        iosSwitchRow(
                          'Book names in Malayalam',
                          s.malayalamNames,
                          (v) => update(() => s.malayalamNames = v),
                        ),
                        iosSwitchRow(
                          'Selection haptics',
                          s.haptics,
                          (v) => update(() => s.haptics = v),
                        ),
                        settingsRow(
                          context,
                          CupertinoIcons.calendar,
                          'Reading plans',
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute<void>(
                              builder: (_) => PlanCatalog(store: s),
                            ),
                          ),
                        ),
                        settingsRow(
                          context,
                          CupertinoIcons.info_circle,
                          'About Bible',
                          onTap: () => showAbout(context),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget settingsGroup(
  BuildContext context,
  String title,
  List<Widget> children,
) => Padding(
  padding: const EdgeInsets.only(bottom: 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: uiMuted(context),
          ),
        ),
      ),
      GlassPanel(
        radius: 24,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1, thickness: .5),
                ),
              children[i],
            ],
          ],
        ),
      ),
    ],
  ),
);

Widget settingsRow(
  BuildContext context,
  IconData icon,
  String title, {
  String? value,
  required VoidCallback onTap,
}) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(24),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    child: Row(
      children: [
        AppIcon(icon, size: 20, color: uiInk(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, color: uiInk(context)),
          ),
        ),
        if (value != null)
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: uiMuted(context)),
            ),
          ),
        const SizedBox(width: 10),
        AppIcon(
          CupertinoIcons.chevron_right,
          size: 12,
          color: uiMuted(context),
        ),
      ],
    ),
  ),
);

Widget iosSwitchRow(String title, bool value, ValueChanged<bool> callback) =>
    Builder(
      builder: (context) => InkWell(
        onTap: () => callback(!value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, color: uiInk(context)),
                ),
              ),
              SizedBox(width: 12),
              CupertinoSwitch(
                value: value,
                thumbColor: Colors.white,
                onChanged: callback,
                activeTrackColor: uiAccent(context),
              ),
            ],
          ),
        ),
      ),
    );

Future<void> backupData(
  BuildContext context,
  BibleStore s,
  bool restore,
) async {
  try {
    if (restore) {
      final source = await BibleStore.storage.invokeMethod<String>(
        'importBackup',
      );
      if (source == null || !context.mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Restore saved data?'),
          content: const Text(
            'Merge bookmarks, highlights, notes and tags from this backup. Matching entries will use the backup version. Other saved entries stay on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await s.restoreBackup(source);
    } else {
      final done = await BibleStore.storage.invokeMethod<bool>(
        'exportBackup',
        s.exportBackup(),
      );
      if (done != true) return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restore ? 'Saved data restored' : 'Backup saved'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to complete backup or restore. Choose a valid Bible backup file and try again.',
          ),
        ),
      );
    }
  }
}

Future<void> manageTags(
  BuildContext context,
  BibleStore s,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheet) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: SheetShell(
        title: 'Manage tags',
        child: Expanded(
          child: s.knownTags.isEmpty
              ? const Center(
                  child: Text('No tags yet. Add tags to a saved verse.'),
                )
              : ListView(
                  children: [
                    for (final tag in s.knownTags)
                      ListTile(
                        title: Text(tag),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Rename $tag',
                              icon: const Icon(CupertinoIcons.pencil),
                              onPressed: () async {
                                var edited = tag;
                                final name = await showDialog<String>(
                                  context: context,
                                  builder: (dialog) => AlertDialog(
                                    title: const Text('Rename tag'),
                                    content: TextFormField(
                                      initialValue: tag,
                                      onChanged: (v) => edited = v,
                                      maxLength: 32,
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialog),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialog, edited),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (name != null &&
                                    name.trim().isNotEmpty &&
                                    context.mounted) {
                                  s.renameTag(tag, name);
                                  await save(context, s);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete $tag',
                              icon: const Icon(CupertinoIcons.trash),
                              onPressed: () async {
                                final yes = await showDialog<bool>(
                                  context: context,
                                  builder: (dialog) => AlertDialog(
                                    title: const Text('Delete tag?'),
                                    content: Text(
                                      'Remove “$tag” from all bookmarks? Your bookmarks will stay saved.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialog),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialog, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (yes == true && context.mounted) {
                                  s.deleteTag(tag);
                                  await save(context, s);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    ),
  ),
);
