import 'package:event_log_app/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event.fromJson', () {
    test('parses all fields when present', () {
      final event = Event.fromJson({
        'id': 1,
        'name': 'Ran 5km',
        'category_id': 2,
        'observation': 'Felt great',
        'timestamp': '2024-01-01T08:00:00.000Z',
        'status': 'processed',
        'processed_at': '2024-01-01T08:01:00.000Z',
      });

      expect(event.id, 1);
      expect(event.name, 'Ran 5km');
      expect(event.categoryId, 2);
      expect(event.observation, 'Felt great');
      expect(event.timestamp, DateTime.parse('2024-01-01T08:00:00.000Z'));
      expect(event.status, 'processed');
      expect(event.processedAt, DateTime.parse('2024-01-01T08:01:00.000Z'));
    });

    test('nullable fields default to null', () {
      final event = Event.fromJson({
        'id': 1,
        'name': 'Read',
        'category_id': null,
        'observation': null,
        'timestamp': null,
        'status': 'pending',
        'processed_at': null,
      });

      expect(event.categoryId, isNull);
      expect(event.observation, isNull);
      expect(event.timestamp, isNull);
      expect(event.processedAt, isNull);
    });
  });

  group('Event.toJson', () {
    test('excludes null optional fields', () {
      const event = Event(id: 1, name: 'Read', status: 'pending');
      final json = event.toJson();

      expect(json['name'], 'Read');
      expect(json.containsKey('category_id'), isFalse);
      expect(json.containsKey('observation'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
    });

    test('includes non-null optional fields', () {
      final event = Event(
        id: 1,
        name: 'Read',
        status: 'pending',
        categoryId: 3,
        observation: 'Good book',
        timestamp: DateTime.parse('2024-06-01T09:00:00.000Z'),
      );
      final json = event.toJson();

      expect(json['category_id'], 3);
      expect(json['observation'], 'Good book');
      expect(json['timestamp'], '2024-06-01T09:00:00.000Z');
    });
  });
}
