// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ЭТО САМЫЙ НАДЁЖНЫЙ СПОСОБ — прямой импорт через package: и правильное имя
import 'package:sketchshare/main.dart';

void main() {
  testWidgets('Приложение запускается без краша', (WidgetTester tester) async {
    // Этот тест просто проверяет, что приложение не падает при запуске
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Если приложение запустилось — значит MyApp существует
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Можно открыть экран рисования (если есть FAB)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final fab = find.byIcon(Icons.add);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(find.text('Новый скетч'), findsOneWidget);
    } else {
      // Если нет FAB — значит, мы на экране входа (тоже нормально)
      expect(find.byType(TextField), findsWidgets);
    }
  });
}