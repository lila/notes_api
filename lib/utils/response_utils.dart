import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Utility class for creating consistent HTTP responses
class ResponseUtils {
  /// Creates a successful JSON response
  static Response success({
    required Map<String, dynamic> data,
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final responseHeaders = {'content-type': 'application/json', ...?headers};

    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: responseHeaders,
    );
  }

  /// Creates a successful response with a list of items
  static Response successList({
    required List<Map<String, dynamic>> items,
    required String itemName,
    int? count,
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final data = {itemName: items, 'count': count ?? items.length};

    return success(data: data, statusCode: statusCode, headers: headers);
  }

  /// Creates a created response (201)
  static Response created({
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) {
    return success(data: data, statusCode: 201, headers: headers);
  }

  /// Creates a no content response (204)
  static Response noContent({Map<String, String>? headers}) {
    final responseHeaders = {'content-type': 'application/json', ...?headers};

    return Response(204, headers: responseHeaders);
  }

  /// Creates an error response
  static Response error({
    required String message,
    required String code,
    int statusCode = 500,
    Map<String, dynamic>? details,
    Map<String, String>? headers,
  }) {
    final responseHeaders = {'content-type': 'application/json', ...?headers};

    final errorData = {
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
    };

    return Response(
      statusCode,
      body: jsonEncode(errorData),
      headers: responseHeaders,
    );
  }

  /// Creates a bad request response (400)
  static Response badRequest({
    required String message,
    Map<String, dynamic>? details,
    Map<String, String>? headers,
  }) {
    return error(
      message: message,
      code: 'BAD_REQUEST',
      statusCode: 400,
      details: details,
      headers: headers,
    );
  }

  /// Creates a validation error response (400)
  static Response validationError({
    required String message,
    String? field,
    dynamic value,
    Map<String, String>? headers,
  }) {
    final details = <String, dynamic>{};
    if (field != null) details['field'] = field;
    if (value != null) details['value'] = value;

    return error(
      message: message,
      code: 'VALIDATION_ERROR',
      statusCode: 400,
      details: details.isNotEmpty ? details : null,
      headers: headers,
    );
  }

  /// Creates a not found response (404)
  static Response notFound({
    required String message,
    String? resourceId,
    Map<String, String>? headers,
  }) {
    final details = resourceId != null ? {'id': resourceId} : null;

    return error(
      message: message,
      code: 'NOT_FOUND',
      statusCode: 404,
      details: details,
      headers: headers,
    );
  }

  /// Creates an internal server error response (500)
  static Response internalServerError({
    String message = 'Internal server error',
    Map<String, String>? headers,
  }) {
    return error(
      message: message,
      code: 'INTERNAL_SERVER_ERROR',
      statusCode: 500,
      headers: headers,
    );
  }

  /// Creates a method not allowed response (405)
  static Response methodNotAllowed({
    required String method,
    List<String>? allowedMethods,
    Map<String, String>? headers,
  }) {
    final responseHeaders = {
      if (allowedMethods != null) 'Allow': allowedMethods.join(', '),
      ...?headers,
    };

    return error(
      message: 'Method $method not allowed',
      code: 'METHOD_NOT_ALLOWED',
      statusCode: 405,
      headers: responseHeaders,
    );
  }

  /// Parses JSON from request body
  static Future<Map<String, dynamic>?> parseJsonBody(Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return null;

      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON format: $e');
    }
  }

  /// Validates required fields in JSON data
  static String? validateRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return 'Field "$field" is required';
      }
    }
    return null;
  }

  /// Creates a health check response
  static Response healthCheck({
    String status = 'healthy',
    Map<String, dynamic>? additionalInfo,
  }) {
    final data = {
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'notes-api',
      if (additionalInfo != null) ...additionalInfo,
    };

    return success(data: data);
  }

  /// Handles exceptions and converts them to appropriate responses
  static Response handleException(dynamic exception, StackTrace stackTrace) {
    print('Exception occurred: $exception');
    print('Stack trace: $stackTrace');

    if (exception is FormatException) {
      return badRequest(message: exception.message);
    }

    if (exception.toString().contains('FirestoreException')) {
      return internalServerError(message: 'Database operation failed');
    }

    return internalServerError();
  }
}
