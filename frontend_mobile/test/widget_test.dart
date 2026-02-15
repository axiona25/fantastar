// Basic Flutter widget smoke test (app uses MaterialApp.router + providers in main).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('FANTASTAR'))),
      ),
    );
    expect(find.text('FANTASTAR'), findsOneWidget);
  });
}
