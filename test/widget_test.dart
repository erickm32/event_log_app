import 'package:event_log_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:event_log_app/services/api_service.dart';

void main() {
  testWidgets('shell renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider(
        create: (_) => ApiService(),
        child: const App(),
      ),
    );

    // NavigationBar renders each label twice internally in Material 3
    expect(find.text('Events'), findsAtLeastNWidgets(1));
    expect(find.text('Categories'), findsAtLeastNWidgets(1));
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
