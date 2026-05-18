import 'package:event_log_app/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StatusChip', () {
    for (final (status, label) in [
      ('pending', 'Pending'),
      ('processing', 'Processing'),
      ('processed', 'Processed'),
      ('failed', 'Failed'),
    ]) {
      testWidgets('shows "$label" for status "$status"', (tester) async {
        await tester.pumpWidget(_wrap(StatusChip(status: status)));
        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('shows raw value for unknown status', (tester) async {
      await tester.pumpWidget(_wrap(const StatusChip(status: 'archived')));
      expect(find.text('archived'), findsOneWidget);
    });
  });
}
