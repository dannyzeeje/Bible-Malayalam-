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
      final now = store.clock();
      String dayLabel(DateTime date) {
        final local = date.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        final today = DateTime(now.year, now.month, now.day);
        if (day == today) return 'Today';
        if (day == DateTime(today.year, today.month, today.day - 1)) {
          return 'Yesterday';
        }
        return '${local.day}/${local.month}/${local.year}';
      }

      return Scaffold(
        body: Material(
          color: toneOf(context).background,
          child: SafeArea(
            child: Column(
              children: [
                pageHeader(
                  context,
                  'History',
                  trailing: Text(
                    '5 days',
                    style: TextStyle(fontSize: 12, color: uiMuted(context)),
                  ),
                ),
                Expanded(
                  child: visits.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Your recently read verses will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: uiMuted(context)),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                          itemCount: visits.length,
                          itemBuilder: (context, index) {
                            final visit = visits[index],
                                verse = store.byId[visit.verseId]!;
                            final label = dayLabel(visit.visitedAt);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0 ||
                                    label !=
                                        dayLabel(visits[index - 1].visitedAt))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 10,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: uiMuted(context),
                                      ),
                                    ),
                                  ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    await openReader(
                                      context,
                                      store,
                                      verse: verse,
                                    );
                                    if (context.mounted) store.changed();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            store.verseLabel(verse),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          MaterialLocalizations.of(
                                            context,
                                          ).formatTimeOfDay(
                                            TimeOfDay.fromDateTime(
                                              visit.visitedAt.toLocal(),
                                            ),
                                            alwaysUse24HourFormat:
                                                MediaQuery.alwaysUse24HourFormatOf(
                                                  context,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: uiMuted(context),
                                          ),
                                        ),
                                      ],
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
      );
    },
  );
}
