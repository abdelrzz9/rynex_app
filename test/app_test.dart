import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rynex_app/app.dart';

void main() {
  testWidgets('App renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RynexApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
