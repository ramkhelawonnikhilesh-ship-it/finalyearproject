import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Lesson {
  final String id, title, topic, body, question;
  final int minutes, level, correct;
  final List<String> answers;
  const Lesson(this.id, this.title, this.topic, this.minutes, this.level, this.body, this.question, this.answers, this.correct);
}
const lessons = <Lesson>[
  Lesson('variables', 'Your first variables', 'Dart essentials', 5, 1, 'A variable stores a value you can use later. Dart can infer a type with var, or you can declare it explicitly.\n\nvar name = "Alex";\nint studyMinutes = 15;\nfinal goal = "Learn Dart";\n\nUse final when a value is assigned only once. Use const for compile-time constants. Clear variable names make programs easier to read.', 'Which declaration cannot be reassigned?', ['var score = 10;', 'final score = 10;', 'int score = 10;'], 1),
  Lesson('conditions', 'Make decisions with if', 'Dart essentials', 8, 1, 'Conditions let a program choose an action.\n\nif (minutes >= 15) {\n  print("Start a full lesson");\n} else {\n  print("Try a quick review");\n}\n\nComparison operators include ==, !=, <, and >=. Combine conditions with && (and) or || (or). A condition must evaluate to a boolean.', 'Which operator means both conditions must be true?', ['||', '&&', '!='], 1),
  Lesson('loops', 'Repeat with loops', 'Dart essentials', 10, 2, 'A for loop repeats work a known number of times.\n\nfor (var i = 0; i < 3; i++) {\n  print(i);\n}\n\nThis prints 0, 1, and 2. A for-in loop visits every element of a collection. A while loop repeats while its condition remains true. Always ensure a loop can finish.', 'How many times does the example loop run?', ['2', '3', '4'], 1),
  Lesson('widgets', 'Think in widgets', 'Flutter foundations', 7, 1, 'Flutter builds interfaces from widgets. Text displays a string. Padding adds space. Row arranges children horizontally and Column arranges them vertically.\n\nA StatelessWidget describes an interface from its inputs. A StatefulWidget holds changing state. The build method returns the widget tree. Prefer small reusable widgets with clear responsibilities.', 'Which widget arranges children vertically?', ['Row', 'Column', 'Padding'], 1),
  Lesson('state', 'Bring your screen to life', 'Flutter foundations', 15, 2, 'State is information that changes while an app runs, such as a selected answer or completed lesson. In a StatefulWidget, setState schedules a rebuild.\n\nsetState(() {\n  completed = true;\n});\n\nKeep durable data in persistent storage. A screen rebuild alone does not save data after closing the app. Separate domain logic from presentation so it can be tested.', 'What does setState do?', ['Saves data permanently', 'Schedules an interface rebuild', 'Installs a package'], 1),
  Lesson('context', 'Design for the moment', 'Context-aware design', 5, 1, 'Context-aware apps adapt to a person’s situation. Useful signals include available time, place, activity, and previous performance.\n\nFor example, a learner with five minutes can receive a short review. A learner studying at home can receive a longer practice task. Explain recommendations and let the learner correct context. Collect only necessary data with permission.', 'What is a useful context-aware recommendation?', ['The same lesson for everyone', 'A short review for a five-minute break', 'Always the longest lesson'], 1),
  Lesson('privacy', 'Build respectful context sensing', 'Context-aware design', 12, 2, 'Device signals can be inaccurate and sensitive. Ask for permission when a feature needs a signal, explain its purpose, and offer manual input.\n\nDo not assume movement means someone can safely study. Avoid reading tasks while driving or walking. Prefer approximate place categories when precise coordinates are unnecessary. Store only what your application needs.', 'What should happen when location access is unavailable?', ['Block all learning', 'Offer manual context selection', 'Guess exact coordinates'], 1),
  Lesson('adaptive', 'Create an adaptive pathway', 'Context-aware design', 20, 3, 'An adaptive pathway uses performance to choose the next useful activity. A low quiz score can trigger revision; a high score can unlock more challenging content.\n\nA transparent rule-based engine is a good baseline: filter by time, suppress tasks during movement, prioritize revision, then rank by readiness. Evaluate it against a non-adaptive baseline using completion rate, quiz scores, and user feedback.', 'What is a good response to a low quiz score?', ['Recommend revision', 'Hide the topic forever', 'Ignore the result'], 0),
];

class LearningStore extends ChangeNotifier {
  final SharedPreferences prefs;
  LearningStore(this.prefs) { load(); }
  String name = 'Learner', place = 'Home', activity = 'Stationary';
  int minutes = 15;
  bool clockMode = true;
  final Map<String, int> scores = {};
  final List<Map<String, dynamic>> history = [];
  String? storageError;
  void load() {
    try {
      final raw = prefs.getString('learning_v1');
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      name = data['name'] as String; place = data['place'] as String;
      activity = data['activity'] as String; minutes = data['minutes'] as int;
      clockMode = data['clockMode'] as bool;
      scores.addAll(Map<String, int>.from(data['scores']));
      history.addAll((data['history'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) { storageError = 'Saved data could not be loaded. You can continue or reset your profile.'; }
  }
  Future<void> save() async {
    final raw = jsonEncode({'name':name,'place':place,'activity':activity,'minutes':minutes,'clockMode':clockMode,'scores':scores,'history':history});
    try {
      if (!await prefs.setString('learning_v1', raw)) throw StateError('Save failed');
      storageError = null;
    } catch (_) { storageError = 'Changes are in memory but could not be saved on this device.'; }
    notifyListeners();
  }
  List<Lesson> recommendations({DateTime? now}) {
    if (activity != 'Stationary') return [];
    final hour = (now ?? DateTime.now()).hour;
    final limit = clockMode && hour >= 22 ? minutes.clamp(0, 10) : minutes;
    final result = lessons.where((l) => l.minutes <= limit).toList();
    int rank(Lesson l) {
      final score = scores[l.id];
      if (score != null && score < 70) return 100;
      if (score != null) return -100;
      final mastered = scores.values.where((s) => s >= 70).length;
      final readyLevel = mastered >= 5 ? 3 : mastered >= 2 ? 2 : 1;
      return (l.level <= readyLevel ? 30 : 0) + (place == 'Campus' && l.topic == 'Flutter foundations' ? 10 : 0) - l.level;
    }
    result.sort((a,b) { final byRank = rank(b).compareTo(rank(a)); return byRank != 0 ? byRank : a.minutes.compareTo(b.minutes); });
    return result;
  }
  String reason(Lesson l) {
    if ((scores[l.id] ?? 100) < 70) return 'Revision recommended after your last quiz • ${l.minutes} min';
    if (scores.containsKey(l.id)) return 'Revisit a completed lesson • ${l.minutes} min';
    return 'Fits your $minutes-minute window • ${place.toLowerCase()} • level ${l.level}';
  }
  Future<void> complete(Lesson lesson, int score) async {
    scores[lesson.id] = score;
    history.add({'id':lesson.id,'score':score,'at':DateTime.now().toIso8601String(),'minutes':lesson.minutes});
    await save();
  }
  Future<void> reset() async { name='Learner'; place='Home'; activity='Stationary'; minutes=15; clockMode=true; scores.clear(); history.clear(); await save(); }
}
