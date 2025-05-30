import 'package:shelf/shelf.dart';

/// CORS middleware for handling cross-origin requests
class CorsMiddleware {
  /// Creates CORS middleware with configurable options
  static Middleware create({
    List<String>? allowedOrigins,
    List<String>? allowedMethods,
    List<String>? allowedHeaders,
    List<String>? exposedHeaders,
    bool allowCredentials = false,
    int maxAge = 86400, // 24 hours
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        // Default allowed origins (allow all for development)
        final origins = allowedOrigins ?? ['*'];

        // Default allowed methods
        final methods =
            allowedMethods ??
            ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD'];

        // Default allowed headers
        final headers =
            allowedHeaders ??
            [
              'Origin',
              'Content-Type',
              'Accept',
              'Authorization',
              'X-Requested-With',
            ];

        // Get the origin from the request
        final requestOrigin = request.headers['origin'];

        // Determine if origin is allowed
        final isOriginAllowed =
            origins.contains('*') ||
            (requestOrigin != null && origins.contains(requestOrigin));

        // Handle preflight OPTIONS request
        if (request.method == 'OPTIONS') {
          return _createPreflightResponse(
            allowedOrigin: isOriginAllowed ? (requestOrigin ?? '*') : null,
            allowedMethods: methods,
            allowedHeaders: headers,
            exposedHeaders: exposedHeaders,
            allowCredentials: allowCredentials,
            maxAge: maxAge,
          );
        }

        // Process the actual request
        final response = await innerHandler(request);

        // Add CORS headers to the response
        return _addCorsHeaders(
          response,
          allowedOrigin: isOriginAllowed ? (requestOrigin ?? '*') : null,
          exposedHeaders: exposedHeaders,
          allowCredentials: allowCredentials,
        );
      };
    };
  }

  /// Creates a preflight response for OPTIONS requests
  static Response _createPreflightResponse({
    String? allowedOrigin,
    required List<String> allowedMethods,
    required List<String> allowedHeaders,
    List<String>? exposedHeaders,
    required bool allowCredentials,
    required int maxAge,
  }) {
    final headers = <String, String>{
      'Content-Type': 'text/plain',
      'Content-Length': '0',
    };

    // Add CORS headers if origin is allowed
    if (allowedOrigin != null) {
      headers['Access-Control-Allow-Origin'] = allowedOrigin;
      headers['Access-Control-Allow-Methods'] = allowedMethods.join(', ');
      headers['Access-Control-Allow-Headers'] = allowedHeaders.join(', ');
      headers['Access-Control-Max-Age'] = maxAge.toString();

      if (exposedHeaders != null && exposedHeaders.isNotEmpty) {
        headers['Access-Control-Expose-Headers'] = exposedHeaders.join(', ');
      }

      if (allowCredentials) {
        headers['Access-Control-Allow-Credentials'] = 'true';
      }
    }

    return Response.ok('', headers: headers);
  }

  /// Adds CORS headers to an existing response
  static Response _addCorsHeaders(
    Response response, {
    String? allowedOrigin,
    List<String>? exposedHeaders,
    required bool allowCredentials,
  }) {
    if (allowedOrigin == null) {
      return response;
    }

    final headers = Map<String, String>.from(response.headers);

    headers['Access-Control-Allow-Origin'] = allowedOrigin;

    if (exposedHeaders != null && exposedHeaders.isNotEmpty) {
      headers['Access-Control-Expose-Headers'] = exposedHeaders.join(', ');
    }

    if (allowCredentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }

    return response.change(headers: headers);
  }

  /// Creates a permissive CORS middleware for development
  static Middleware development() {
    return create(
      allowedOrigins: ['*'],
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD'],
      allowedHeaders: [
        'Origin',
        'Content-Type',
        'Accept',
        'Authorization',
        'X-Requested-With',
        'Access-Control-Allow-Origin',
      ],
      allowCredentials: false,
    );
  }

  /// Creates a restrictive CORS middleware for production
  static Middleware production({
    required List<String> allowedOrigins,
    bool allowCredentials = false,
  }) {
    return create(
      allowedOrigins: allowedOrigins,
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: [
        'Origin',
        'Content-Type',
        'Accept',
        'Authorization',
        'X-Requested-With',
      ],
      allowCredentials: allowCredentials,
    );
  }
}
