import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/event.dart';

// Android emulator loopback to host machine — swap for deployed URL as needed.
const _baseUrl = 'http://10.0.2.2:5000/api';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? fieldErrors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.fieldErrors,
  });

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  Future<List<Event>> getEvents() async {
    final response = await _client.get(Uri.parse('$_baseUrl/events'));
    _assertOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Event> getEvent(int id) async {
    final response = await _client.get(Uri.parse('$_baseUrl/events/$id'));
    _assertOk(response);
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> createEvent({
    required String name,
    int? categoryId,
    String? observation,
    DateTime? timestamp,
  }) async {
    final body = <String, Object?>{
      'name': name,
      'category_id': ?categoryId,
      'observation': ?observation,
      'timestamp': ?timestamp?.toIso8601String(),
    };
    final response = await _client.post(
      Uri.parse('$_baseUrl/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'event': body}),
    );
    _assertOk(response, expected: 201);
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> updateEvent(
    int id, {
    String? name,
    int? categoryId,
    String? observation,
    DateTime? timestamp,
  }) async {
    final body = <String, Object?>{
      'name': ?name,
      'category_id': ?categoryId,
      'observation': ?observation,
      'timestamp': ?timestamp?.toIso8601String(),
    };
    final response = await _client.patch(
      Uri.parse('$_baseUrl/events/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'event': body}),
    );
    _assertOk(response);
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteEvent(int id) async {
    final response =
        await _client.delete(Uri.parse('$_baseUrl/events/$id'));
    _assertOk(response, expected: 204);
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Future<List<Category>> getCategories() async {
    final response = await _client.get(Uri.parse('$_baseUrl/categories'));
    _assertOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> getCategory(int id) async {
    final response =
        await _client.get(Uri.parse('$_baseUrl/categories/$id'));
    _assertOk(response);
    return Category.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Category> createCategory({required String name}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'category': {'name': name}}),
    );
    _assertOk(response, expected: 201);
    return Category.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Category> updateCategory(int id, {required String name}) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'category': {'name': name}}),
    );
    _assertOk(response);
    return Category.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    final response =
        await _client.delete(Uri.parse('$_baseUrl/categories/$id'));
    _assertOk(response, expected: 204);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _assertOk(http.Response response, {int expected = 200}) {
    if (response.statusCode == expected) return;

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    // Validation errors: field-keyed hash
    final fieldErrors = body.values.every((v) => v is List)
        ? body.map((k, v) => MapEntry(k, (v as List).cast<String>()))
        : null;

    // Not-found / generic error
    final message = body['error'] as String? ??
        fieldErrors?.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n') ??
        'Unexpected error (${response.statusCode})';

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }
}
