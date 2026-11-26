part of 'main.dart';

void openHistory(BuildContext context, BibleStore store) => Navigator.of(
  context,
).push(CupertinoPageRoute<void>(builder: (_) => ReadingHistory(store: store)));

class ReadingHistory extends StatelessWidget {
  final BibleStore store;
  const ReadingHistory({super.key, required this.store});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final visits = store.recentHistory;
      final now = store.clock().toLocal();
      final localizations = MaterialLocalizations.of(context);
      String dayLabel(DateTime date) {
        final local = date.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        if (day == DateTime(now.year, now.month, now.day)) return 'Today';
        if (day == DateTime(now.year, now.month, now.day - 1)) {
          return 'Yesterday';
        }
        return localizations.formatMediumDate(local);
      }

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pageHeader(context, 'History'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Selected verses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: uiInk(context),
                          ),
                        ),
                        Text(
                          'Last 5 days',
                          style: TextStyle(
                            fontSize: 13,
                            color: uiMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visits.isEmpty
                        ? const _EmptyHistory()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: visits.length,
                            itemBuilder: (context, index) {
                              final visit = visits[index];
                              final verse = store.byId[visit.verseId]!;
                              final label = dayLabel(visit.visitedAt);
                              final startsDay =
                                  index == 0 ||
                                  label !=
                                      dayLabel(visits[index - 1].visitedAt);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (startsDay)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: index == 0 ? 8 : 16,
                                        bottom: 8,
                                      ),
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: uiMuted(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _HistoryVerseCard(
                                      reference: store.verseLabel(verse),
                                      time: localizations.formatTimeOfDay(
                                        TimeOfDay.fromDateTime(
                                          visit.visitedAt.toLocal(),
                                        ),
                                        alwaysUse24HourFormat:
                                            MediaQuery.alwaysUse24HourFormatOf(
                                              context,
                                            ),
                                      ),
                                      onTap: () => openReader(
                                        context,
                                        store,
                                        verse: verse,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _HistoryVerseCard extends StatelessWidget {
  final String reference, time;
  final VoidCallback onTap;
  const _HistoryVerseCard({
    required this.reference,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Color.alphaBlend(toneOf(context).panelA, toneOf(context).background),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: uiAccent(context).withValues(alpha: .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AppIcon(
                LucideIcons.bookOpen,
                size: 17,
                color: uiAccent(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reference,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: uiMuted(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppIcon(
              LucideIcons.chevronRightDir,
              size: 18,
              color: uiMuted(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: uiAccent(context).withValues(alpha: .10),
                  child: AppIcon(
                    LucideIcons.clock,
                    size: 25,
                    color: uiAccent(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No selected verses yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: uiInk(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Tap a verse while reading to add it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: uiMuted(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
