import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:context_learn/learning.dart';
import 'package:context_learn/main.dart';

void main() {
  late LearningStore store;
  setUp(() async { SharedPreferences.setMockInitialValues({}); store = LearningStore(await SharedPreferences.getInstance()); store.clockMode = false; });
  test('recommendations fit time and stop during movement', () {
    store.minutes = 5;
    expect(store.recommendations().every((l) => l.minutes <= 5), isTrue);
    store.activity = 'Driving';
    expect(store.recommendations(), isEmpty);
    store.activity = 'Walking';
    expect(store.recommendations(), isEmpty);
  });
  test('low scores trigger revision and persist across restart', () async {
    await store.complete(lessons[0], 0);
    expect(store.recommendations().first.id, lessons[0].id);
    final restored = LearningStore(store.prefs);
    expect(restored.scores[lessons[0].id], 0);
    expect(restored.history.length, 1);
    await restored.reset();
    expect(LearningStore(store.prefs).history, isEmpty);
  });
  test('night mode caps duration', () {
    store.minutes = 60; store.clockMode = true;
    expect(store.recommendations(now: DateTime(2026, 1, 1, 23)).every((l) => l.minutes <= 10), isTrue);
    expect(store.recommendations(now: DateTime(2026, 1, 1, 12)).any((l) => l.minutes > 10), isTrue);
  });
  testWidgets('complete a lesson and update progress', (tester) async {
    await tester.pumpWidget(LearnApp(store: store));
    expect(find.text('ContextLearn'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Your first variables'), 250);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your first variables'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('B. final score = 10;'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B. final score = 10;'));
    await tester.scrollUntilVisible(find.text('Submit answer'), 150, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit answer'));
    await tester.pumpAndSettle();
    expect(store.scores['variables'], 100);
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 50)); });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Back to learning'), 150, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Back to learning'), findsOneWidget);
  });
}
