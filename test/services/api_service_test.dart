import 'dart:convert';

import 'package:event_log_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiService — success paths', () {
    test('getEvents parses list on 200', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode([
                {
                  'id': 1,
                  'name': 'Ran 5km',
                  'status': 'processed',
                  'category_id': null,
                  'observation': null,
                  'timestamp': null,
                  'processed_at': '2024-01-01T10:00:00.000Z',
                },
              ]),
              200,
            )),
      );

      final events = await service.getEvents();

      expect(events.length, 1);
      expect(events.first.name, 'Ran 5km');
      expect(events.first.status, 'processed');
    });

    test('createEvent parses response on 201', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'id': 2,
                'name': 'Read 30 pages',
                'status': 'pending',
                'category_id': null,
                'observation': null,
                'timestamp': null,
                'processed_at': null,
              }),
              201,
            )),
      );

      final event = await service.createEvent(name: 'Read 30 pages');

      expect(event.id, 2);
      expect(event.status, 'pending');
    });
  });

  group('ApiService — error paths', () {
    test('throws ApiException with fieldErrors on 422 validation error', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode({'name': ["can't be blank"]}),
              422,
            )),
      );

      expect(
        () => service.createEvent(name: ''),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.fieldErrors, 'fieldErrors', isNotNull)
              .having(
                (e) => e.fieldErrors!['name'],
                'name errors',
                contains("can't be blank"),
              ),
        ),
      );
    });

    test('throws ApiException with message on 404 not-found', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode({'error': 'Event not found'}),
              404,
            )),
      );

      expect(
        () => service.getEvent(99),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Event not found')
              .having((e) => e.fieldErrors, 'fieldErrors', isNull),
        ),
      );
    });

    test('throws ApiException with generic message on 500 with empty body', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response('', 500)),
      );

      expect(
        () => service.getEvents(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('500')),
        ),
      );
    });

    test('deleteCategory re-throws ApiException on 422 blocked delete', () async {
      final service = ApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode({'error': 'Category has associated events'}),
              422,
            )),
      );

      expect(
        () => service.deleteCategory(1),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Category has associated events',
          ),
        ),
      );
    });
  });
}
