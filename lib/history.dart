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
                pageHeader(context, 'Reading history'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today and the previous four days · stored on this device',
                      style: TextStyle(fontSize: 12, color: uiMuted(context)),
                    ),
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
                                    child: eyebrow(label.toUpperCase()),
                                  ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    store.verseLabel(verse),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      verse.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: store.fontFamily,
                                        fontSize: 15,
                                        height: 1.7,
                                        color: uiMuted(context),
                                      ),
                                    ),
                                  ),
                                  trailing: const AppIcon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                  ),
                                  onTap: () async {
                                    await openReader(
                                      context,
                                      store,
                                      verse: verse,
                                    );
                                    if (context.mounted) store.changed();
                                  },
                                ),
                                const Divider(),
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
