part of 'main.dart';

class PlanCatalog extends StatelessWidget {
  final BibleStore store;
  const PlanCatalog({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              pageHeader(
                context,
                'Reading plans',
                trailing: glassIcon(
                  CupertinoIcons.plus,
                  'Create plan',
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute<void>(
                      builder: (_) => CustomPlanPage(store: store),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                  children: [
                    if (store.customPlans.isNotEmpty) ...[
                      section(context, 'Your plans'),
                      for (final p in store.customPlans) tile(context, p),
                      SizedBox(height: 14),
                    ],
                    section(context, 'Included'),
                    for (final p in readingPlans) tile(context, p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget section(BuildContext context, String title) => Padding(
    padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: uiMuted(context),
      ),
    ),
  );
  Widget tile(BuildContext context, ReadingPlan p) => Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute<void>(
          builder: (_) => PlanDetail(store: store, plan: p),
        ),
      ),
      child: GlassPanel(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            PlanCover(plan: p),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: uiInk(context),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    store.activePlan == p.id
                        ? (store.nextPlanDay(p) >= p.days
                              ? 'Completed'
                              : 'Day ${store.nextPlanDay(p) + 1} of ${p.days}')
                        : '${p.days} days',
                    style: TextStyle(fontSize: 12, color: uiMuted(context)),
                  ),
                ],
              ),
            ),
            AppIcon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: uiMuted(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class CustomPlanPage extends StatefulWidget {
  final BibleStore store;
  const CustomPlanPage({super.key, required this.store});
  @override
  State<CustomPlanPage> createState() => _CustomPlanPageState();
}

class _CustomPlanPageState extends State<CustomPlanPage> {
  final title = TextEditingController();
  final days = TextEditingController(text: '30');
  Set<String> books = bookNames.keys.toSet();
  String? error;
  bool saving = false;
  @override
  void dispose() {
    title.dispose();
    days.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final plan = widget.store.createPlan(
        title.text,
        int.tryParse(days.text) ?? 0,
        books,
      );
      setState(() => saving = true);
      await save(context, widget.store);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute<void>(
            builder: (_) => PlanDetail(store: widget.store, plan: plan),
          ),
        );
      }
    } on ArgumentError catch (e) {
      setState(() => error = e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.store.chapters.keys
        .where((k) => books.contains(k.split('.').first))
        .length;
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              pageHeader(
                context,
                'New plan',
                trailing: primaryPill('Create', saving ? null : submit),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassPanel(
                        padding: EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            menuLabel(context, 'Name'),
                            SizedBox(height: 10),
                            TextField(
                              key: ValueKey('custom-title'),
                              controller: title,
                              maxLength: 80,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Plan name',
                                counterText: '',
                              ),
                            ),
                            SizedBox(height: 22),
                            menuLabel(context, 'Duration'),
                            SizedBox(height: 10),
                            TextField(
                              key: ValueKey('custom-days'),
                              controller: days,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(suffixText: 'days'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      GlassPanel(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          title: Text(
                            'Books',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: uiInk(context),
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Text(
                              '${books.length} ${books.length == 1 ? 'book' : 'books'} · $chapters ${chapters == 1 ? 'chapter' : 'chapters'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: uiMuted(context),
                              ),
                            ),
                          ),
                          trailing: AppIcon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: uiMuted(context),
                          ),
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            final selected =
                                await showModalBottomSheet<Set<String>>(
                                  context: context,
                                  useSafeArea: true,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      PlanBooksSheet(initial: books),
                                );
                            if (selected != null && mounted) {
                              setState(() => books = selected);
                            }
                          },
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(6, 16, 6, 0),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanBooksSheet extends StatefulWidget {
  final Set<String> initial;
  const PlanBooksSheet({super.key, required this.initial});
  @override
  State<PlanBooksSheet> createState() => _PlanBooksSheetState();
}

class _PlanBooksSheetState extends State<PlanBooksSheet> {
  late final Set<String> selected = {...widget.initial};
  String query = '';
  @override
  Widget build(BuildContext context) => GlassPanel(
    radius: 30,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            children: [
              sheetGrip(context),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Books',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: uiInk(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextField(
                onChanged: (v) =>
                    setState(() => query = v.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Find a book',
                  prefixIcon: AppIcon(CupertinoIcons.search, size: 17),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => selected.addAll(bookNames.keys)),
                    child: Text('All'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => selected.clear()),
                    child: Text('Clear'),
                  ),
                  Spacer(),
                  Text(
                    '${selected.length} selected',
                    style: TextStyle(fontSize: 12, color: uiMuted(context)),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final e in bookNames.entries.where(
                      (e) => e.value.toLowerCase().contains(query),
                    ))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        title: Text(
                          e.value,
                          style: TextStyle(fontSize: 14, color: uiInk(context)),
                        ),
                        trailing: AppIcon(
                          selected.contains(e.key)
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: uiAccent(context),
                          size: 23,
                        ),
                        onTap: () => setState(() {
                          if (!selected.add(e.key)) selected.remove(e.key);
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> deleteCustomPlan(
  BuildContext context,
  BibleStore store,
  ReadingPlan plan,
) async {
  final yes = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialog) => CupertinoAlertDialog(
      title: Text('Delete ${plan.title}?'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(dialog, true),
          child: Text('Delete'),
        ),
      ],
    ),
  );
  if (yes == true && context.mounted) {
    store.deletePlan(plan.id);
    await save(context, store);
    if (context.mounted) Navigator.pop(context);
  }
}
