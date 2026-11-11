# ContextLearn — Context-Aware Mobile Learning Application

Final-year project MST_KJ_01. Flutter application for Android, iOS, and web.

## Run in VS Code

1. Install the stable Flutter SDK: https://docs.flutter.dev/get-started/install and add Flutter's `bin` directory to PATH.
2. Install the **Flutter** extension in VS Code (includes Dart).
3. Install Android Studio for the Android SDK and create an emulator, or connect an Android phone with USB debugging enabled. iOS requires macOS, Xcode, and signing configuration.
4. Extract this project and open the `context_learn` folder in VS Code.
5. In the integrated terminal run:

```sh
flutter doctor
flutter pub get
flutter devices
flutter run
```

Select a device in VS Code's status bar and press F5. For a quick browser demonstration, use `flutter run -d chrome`.

```sh
flutter analyze
flutter test
flutter build apk --release
```

The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. Configure your own application identifier and release signing before distributing through an app store. No API keys, account, or backend are needed.

## Included functionality

- Four screens: personalized home, searchable library, context controls, and progress/profile.
- Eight lessons covering Dart, Flutter, and context-aware design; each has a formative question, feedback, and retakes.
- Recommendations adapt to manually entered place, activity, available minutes, local device time, and latest quiz performance.
- Walking/driving pauses recommendations. The library remains accessible; this is not a driving safety enforcement mechanism.
- Incorrect answers prioritize revision. Passing two distinct lessons makes level 2 lessons ready; passing five makes level 3 ready. Campus context boosts Flutter lessons. Completed lessons rank lower.
- After 22:00 local device time, automatic time mode limits suggestions to ten minutes. Toggle this off for a deterministic presentation. Recommendations refresh when returning to the app or pressing refresh.
- Local profile, context, latest scores, and attempt history persist using SharedPreferences. Reset requires confirmation.
- Layout supports narrow mobile screens and wider browser windows.

## Scope and limitations

This is a functional offline project baseline, not a production learning management system. Place and activity are explicitly manual; GPS, motion detection, login, remote content management, cloud sync, push notifications, and teacher dashboards are not implemented. Do not present manual values as sensor readings. SharedPreferences is unencrypted local convenience storage, not a secure database. Web progress belongs to the current browser/origin; uninstalling or clearing app data removes progress.

Quiz scores are 0 or 100 because each sample lesson contains one question. A score of at least 70 counts as mastered. Reported lesson minutes are estimated content length, not tracked time. Repeated attempts count as separate attempts. The latest attempt determines current mastery and recommendation ranking. Expand the question bank and evaluate learning outcomes before making research claims.

## Architecture

`lib/learning.dart`: lesson model, sample curriculum, persistence, and transparent recommendation rules.

`lib/main.dart`: Material 3 interface, navigation, context editing, lesson reader, quiz flow, and progress.

`test/learning_test.dart`: time/activity filters, nighttime behavior, revision priority, persistence/reset, and end-to-end widget quiz flow.

No external runtime service is used. Source content is bundled with the app.

## Presentation walkthrough

1. Set available time to 5 minutes and show that only short lessons appear.
2. Increase time to 30 minutes; show additional eligible lessons.
3. Choose Campus and observe the Flutter topic preference among eligible lessons.
4. Complete a quiz incorrectly; return home to see revision prioritized.
5. Retake it correctly; show mastery and attempt history.
6. Set activity to Walking; show the pause message. Return to Stationary.
7. Close and reopen the app to demonstrate persistence.

## Suggested evaluation

Compare this rule-based engine with a static lesson list. Measure task completion, pre/post quiz performance, recommendation acceptance, and usability using consented participants. Use a larger question bank to avoid memorization effects. The sample app contains no evaluated claims of improved engagement.

## Validation in the build environment

All four automated tests passed, including the lesson/quiz widget flow. Release web compilation passed. Standard static analysis could not start because the SDK tries to write to a read-only home directory in the build environment; run `flutter analyze` locally. Android/iOS builds require the corresponding SDKs and were not run here.

For a web build with bundled renderer assets, use `flutter build web --release --no-web-resources-cdn`. Serve `build/web` through an HTTP server, rather than opening index.html directly.
