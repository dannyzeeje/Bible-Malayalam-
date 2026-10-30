part of 'main.dart';

class ReadingHub extends StatelessWidget {
  final BibleStore store;
  final VoidCallback onSaved;
  const ReadingHub({super.key, required this.store, required this.onSaved});
  @override
  Widget build(BuildContext context) {
    final s = store, p = s.plan ?? readingPlans.first;
    final day = s.nextPlanDay(p), done = (s.planCompleted[p.id] ?? {}).length;
    final chapters = day < p.days ? s.planChapters(p, day) : <String>[];
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 18,
              20,
              115,
            ),
            children: [
              Row(
                children: [
                  Expanded(child: heading('Bible', size: 34)),
                  glassIcon(
                    CupertinoIcons.gear,
                    'Settings',
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) => SettingsPage(store: s),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassPanel(
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: uiAccent(context).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: AppIcon(
                        CupertinoIcons.book,
                        size: 28,
                        color: uiAccent(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue reading',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: uiMuted(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          heading('${s.location}:${s.verse}', size: 23),
                        ],
                      ),
                    ),
                    SizedBox.square(
                      dimension: 46,
                      child: FilledButton(
                        onPressed: () => openReader(context, s),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: const AppIcon(
                          CupertinoIcons.arrow_right,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(child: heading('Your reading plan', size: 20)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) => PlanCatalog(store: s),
                      ),
                    ),
                    child: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassPanel(
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) => PlanDetail(store: s, plan: p),
                        ),
                      ),
                      child: Row(
                        children: [
                          PlanCover(plan: p, width: 86),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: uiAccent(
                                      context,
                                    ).withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${p.days}-day plan',
                                    style: TextStyle(
                                      color: uiAccent(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.title,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.6,
                                    color: uiInk(context),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  day < p.days
                                      ? 'Day ${day + 1} of ${p.days}'
                                      : 'Plan complete',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: uiMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$done of ${p.days} completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: uiMuted(context),
                            ),
                          ),
                        ),
                        Text(
                          '${(100 * done / p.days).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: uiMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: '$done of ${p.days} days complete',
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: done / p.days),
                        duration: motionDuration(context, 260),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            color: uiAccent(context),
                            backgroundColor: uiFill(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1),
                    const SizedBox(height: 16),
                    if (day < p.days)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: uiFill(context).withValues(alpha: .38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S READING",
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                                color: uiMuted(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in chapters.take(4))
                                  ActionChip(
                                    label: Text(
                                      chapterLabel(c),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => openReader(
                                      context,
                                      s,
                                      verse: s.chapters[c]!.first,
                                    ),
                                  ),
                                if (chapters.length > 4)
                                  Text(
                                    '+${chapters.length - 4}',
                                    style: TextStyle(color: uiMuted(context)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: primaryPill('Read day ${day + 1}', () {
                                    s.activePlan = p.id;
                                    s.changed();
                                    save(context, s);
                                    showPlanDay(context, s, p, day);
                                  }),
                                ),
                                const SizedBox(width: 10),
                                glassIcon(
                                  CupertinoIcons.checkmark,
                                  'Mark day complete',
                                  () {
                                    s.activePlan = p.id;
                                    s.completePlanDay(p, day, true);
                                    save(context, s);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      primaryPill(
                        'Choose another plan',
                        () => Navigator.push(
                          context,
                          CupertinoPageRoute<void>(
                            builder: (_) => PlanCatalog(store: s),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                radius: 24,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const AppIcon(
                    CupertinoIcons.bookmark,
                    color: Color(0xffd4a139),
                  ),
                  title: const Text(
                    'Saved verses',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  trailing: const AppIcon(
                    CupertinoIcons.chevron_right,
                    size: 17,
                  ),
                  onTap: onSaved,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlanCover extends StatelessWidget {
  final ReadingPlan plan;
  final double width;
  const PlanCover({super.key, required this.plan, this.width = 60});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width * 1.36,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(uiAccent(context), Colors.white, .7)!,
          Color.lerp(uiAccent(context), Colors.white, .35)!,
        ],
      ),
      border: Border.all(color: uiAccent(context).withValues(alpha: .2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              plan.title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'Editorial',
                fontSize: width > 70 ? 12 : 9,
                letterSpacing: 1,
                color: const Color(0xff252633),
              ),
            ),
          ),
        ),
        const AppIcon(CupertinoIcons.book, size: 28, color: Colors.white),
        const SizedBox(height: 8),
      ],
    ),
  );
}
