import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LearningStore(await SharedPreferences.getInstance());
  runApp(LearnApp(store: store));
}

class LearnApp extends StatelessWidget {
  final LearningStore store;
  const LearnApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ContextLearn', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff246b61)), scaffoldBackgroundColor: const Color(0xfff6f8f7), cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.symmetric(vertical: 6))),
    home: Home(store: store),
  );
}
class Home extends StatefulWidget {
  final LearningStore store;
  const Home({super.key, required this.store});
  @override
  State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> with WidgetsBindingObserver {
  int tab = 0;
  String query = '';
  LearningStore get s => widget.store;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) setState(() {}); }
  void open(Lesson l) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonPage(store: s, lesson: l)));
  Widget heading(String eyebrow, String title, String subtitle) => Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow.toUpperCase(), style: const TextStyle(letterSpacing: 2, color: Color(0xff246b61), fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(subtitle, style: TextStyle(color: Colors.grey.shade700, height: 1.5))]));
  Widget lessonCard(Lesson l, {bool recommended = false}) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(backgroundColor: const Color(0xffe1efea), child: Icon(s.scores[l.id] == 100 ? Icons.check : Icons.auto_stories_outlined, color: const Color(0xff246b61))), title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(recommended ? s.reason(l) : '${l.topic} • ${l.minutes} min • Level ${l.level}${s.scores.containsKey(l.id) ? ' • ${s.scores[l.id]}%' : ''}')), trailing: const Icon(Icons.chevron_right), onTap: () => open(l)));
  Widget dashboard() {
    final recommendations = s.recommendations();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Your learning companion', 'Hello, ${s.name}.', 'A little progress, at the right moment.'),
      Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xff174d46), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.spa_outlined, color: Color(0xffb9e5cd), size: 34), const SizedBox(height: 16), const Text('Learning that fits\nyour life.', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text('${s.minutes} minutes • ${s.place} • ${s.activity}', style: const TextStyle(color: Colors.white)), const SizedBox(height: 16), FilledButton.tonal(onPressed: () => setState(() => tab = 2), child: const Text('Update my context'))])),
      const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('For this moment', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), IconButton(tooltip: 'Refresh recommendations', onPressed: () => setState(() {}), icon: const Icon(Icons.refresh))]),
      const Text('Selected using your context and latest quiz results.'),
      if (s.clockMode && DateTime.now().hour >= 22) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Late evening: shorter lessons are prioritized (10 minutes maximum).')),
      if (recommendations.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(s.activity != 'Stationary' ? 'Take a pause while moving. Resume learning when you are safely stationary.' : 'No lesson fits this time window. Increase your available study time.'))),
      ...recommendations.take(3).map((l) => lessonCard(l, recommended: true)),
      const SizedBox(height: 16), Text('${s.scores.values.where((v) => v >= 70).length} of ${lessons.length} lessons mastered', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), LinearProgressIndicator(value: s.scores.values.where((v) => v >= 70).length / lessons.length, minHeight: 8, borderRadius: BorderRadius.circular(10)),
    ]);
  }
  Widget library() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading('Explore & practice', 'Your lesson library', 'Build your skills, one idea at a time.'), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search lessons or topics', border: OutlineInputBorder()), onChanged: (v) => setState(() => query = v)), const SizedBox(height: 12), ...lessons.where((l) => '${l.title} ${l.topic}'.toLowerCase().contains(query.toLowerCase())).map(lessonCard), if (!lessons.any((l) => '${l.title} ${l.topic}'.toLowerCase().contains(query.toLowerCase()))) const Padding(padding: EdgeInsets.all(24), child: Text('No matching lessons. Try another search.'))]);
  Widget contextPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading('Make it personal', 'Your current context', 'You control what the app knows. Update these inputs whenever your situation changes.'),
    const Text('Available study time', style: TextStyle(fontWeight: FontWeight.bold)), Text('${s.minutes} minutes', style: const TextStyle(fontSize: 26)), Slider(value: s.minutes.toDouble(), min: 5, max: 60, divisions: 11, label: '${s.minutes} min', onChanged: (v) { s.minutes = v.round(); s.save(); }),
    dropdown('Place (manual)', s.place, ['Home', 'Campus', 'Library', 'Commute'], (v) { s.place = v; s.save(); }),
    dropdown('Activity (manual)', s.activity, ['Stationary', 'Walking', 'Driving'], (v) { s.activity = v; s.save(); }),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Use local device time'), subtitle: const Text('Suggest lessons of up to 10 minutes after 10 pm.'), value: s.clockMode, onChanged: (v) { s.clockMode = v; s.save(); }),
    const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Privacy by design\n\nPlace and activity are entered by you. This version does not access GPS, motion sensors, or a server. Your profile, context, and learning history are stored on this device.'))),
    const SizedBox(height: 16), FilledButton.icon(onPressed: () => setState(() => tab = 0), icon: const Icon(Icons.auto_awesome), label: const Text('See my recommendations')),
  ]);
  Widget dropdown(String label, String value, List<String> options, ValueChanged<String> change) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: DropdownButtonFormField<String>(initialValue: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) change(v); }));
  Widget progress() {
    final mastered = s.scores.values.where((v) => v >= 70).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading('Every step counts', 'Your learning journey', 'Mastery is based on your latest quiz result. Retake a lesson whenever you want.'),
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [stat('$mastered/${lessons.length}', 'Mastered'), stat('${s.history.length}', 'Attempts'), stat('${s.history.fold<int>(0, (n, h) => n + (h['minutes'] as int))}', 'Lesson minutes*')]))),
      const Text('* Estimated content duration, not measured study time.', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 20), TextFormField(initialValue: s.name, maxLength: 30, decoration: const InputDecoration(labelText: 'Your display name', border: OutlineInputBorder()), onChanged: (v) { s.name = v.trim().isEmpty ? 'Learner' : v.trim(); s.save(); }),
      const SizedBox(height: 12), const Text('Recent activity', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      if (s.history.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Your first lesson is the start of your story. Complete a quiz to see it here.')),
      ...s.history.reversed.take(20).map((h) { final l = lessons.firstWhere((l) => l.id == h['id']); final date = DateTime.parse(h['at']).toLocal(); return Card(child: ListTile(title: Text(l.title), subtitle: Text('${date.day}/${date.month}/${date.year} • ${h['score']}%'), trailing: Icon(h['score'] >= 70 ? Icons.check_circle_outline : Icons.refresh), onTap: () => open(l))); }),
      TextButton.icon(onPressed: () async { final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Reset your learning data?'), content: const Text('This removes your local profile, context, scores, and history.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset'))])); if (confirmed == true) { await s.reset(); if (mounted) setState(() {}); } }, icon: const Icon(Icons.delete_outline), label: const Text('Reset local data')),
    ]);
  }
  Widget stat(String value, String label) => Flexible(child: Column(children: [Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xff246b61))), Text(label, textAlign: TextAlign.center)]));
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: s, builder: (context, _) => Scaffold(appBar: AppBar(title: const Row(children: [Icon(Icons.spa, color: Color(0xff246b61)), SizedBox(width: 8), Text('ContextLearn', style: TextStyle(fontWeight: FontWeight.w800))]), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Chip(label: const Text('OFFLINE'), side: BorderSide.none, backgroundColor: const Color(0xffe1efea))) ]), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [if (s.storageError != null) MaterialBanner(content: Text(s.storageError!), actions: [TextButton(onPressed: s.save, child: const Text('Retry'))]), [dashboard, library, contextPage, progress][tab]()])))), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) { FocusScope.of(context).unfocus(); setState(() => tab = v); }, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'For you'), NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'), NavigationDestination(icon: Icon(Icons.tune), label: 'Context'), NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Progress')])));
}

class LessonPage extends StatefulWidget {
  final LearningStore store;
  final Lesson lesson;
  const LessonPage({super.key, required this.store, required this.lesson});
  @override
  State<LessonPage> createState() => _LessonPageState();
}
class _LessonPageState extends State<LessonPage> {
  int? selected;
  bool submitted = false, saving = false;
  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    return Scaffold(appBar: AppBar(title: Text(l.topic)), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.all(24), children: [Text('${l.minutes} MIN READ • LEVEL ${l.level}', style: const TextStyle(color: Color(0xff246b61), letterSpacing: 1.4)), const SizedBox(height: 12), Text(l.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 24), SelectableText(l.body, style: const TextStyle(fontSize: 17, height: 1.8)), const Divider(height: 48), const Text('Check your understanding', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(l.question, style: const TextStyle(fontSize: 17)), const SizedBox(height: 12), ...List.generate(l.answers.length, (i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: OutlinedButton(style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(18), backgroundColor: selected == i ? const Color(0xffdcece5) : null), onPressed: submitted ? null : () => setState(() => selected = i), child: Text('${String.fromCharCode(65+i)}. ${l.answers[i]}')))), const SizedBox(height: 16), if (!submitted) FilledButton(onPressed: selected == null || saving ? null : () async { setState(() => saving = true); await widget.store.complete(l, selected == l.correct ? 100 : 0); if (mounted) setState(() { submitted = true; saving = false; }); }, child: Text(saving ? 'Saving…' : 'Submit answer')), if (submitted) ...[Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(selected == l.correct ? 'Correct! You have mastered this lesson. Your learning pathway has been updated.' : 'Keep going. The correct answer is: ${l.answers[l.correct]}. Review the lesson and try again. This topic is now prioritized for revision.'))), if (widget.store.storageError != null) Text(widget.store.storageError!), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to learning')), TextButton(onPressed: () => setState(() { submitted = false; selected = null; }), child: const Text('Try again'))]])))));
  }
}
