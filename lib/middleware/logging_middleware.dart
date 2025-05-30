import 'dart:io';
import 'package:shelf/shelf.dart';

/// Logging middleware for HTTP requests and responses
class LoggingMiddleware {
  /// Creates logging middleware with configurable options
  static Middleware create({
    bool logRequests = true,
    bool logResponses = true,
    bool logHeaders = false,
    bool logBody = false,
    LogLevel level = LogLevel.info,
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        final requestId = _generateRequestId();

        if (logRequests) {
          _logRequest(
            request,
            requestId: requestId,
            logHeaders: logHeaders,
            logBody: logBody,
            level: level,
          );
        }

        Response response;
        try {
          response = await innerHandler(request);
        } catch (error, stackTrace) {
          stopwatch.stop();

          _logError(
            request,
            error,
            stackTrace,
            requestId: requestId,
            duration: stopwatch.elapsedMilliseconds,
            level: level,
          );

          rethrow;
        }

        stopwatch.stop();

        if (logResponses) {
          _logResponse(
            request,
            response,
            requestId: requestId,
            duration: stopwatch.elapsedMilliseconds,
            logHeaders: logHeaders,
            level: level,
          );
        }

        return response;
      };
    };
  }

  /// Logs incoming HTTP requests
  static void _logRequest(
    Request request, {
    required String requestId,
    required bool logHeaders,
    required bool logBody,
    required LogLevel level,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('→ ${request.method} ${request.requestedUri}');
    buffer.writeln('  Request ID: $requestId');
    buffer.writeln(
      '  User Agent: ${request.headers['user-agent'] ?? 'Unknown'}',
    );
    buffer.writeln(
      '  Content Type: ${request.headers['content-type'] ?? 'None'}',
    );

    if (logHeaders && request.headers.isNotEmpty) {
      buffer.writeln('  Headers:');
      request.headers.forEach((key, value) {
        // Don't log sensitive headers
        if (!_isSensitiveHeader(key)) {
          buffer.writeln('    $key: $value');
        }
      });
    }

    _log(buffer.toString().trim(), level);
  }

  /// Logs HTTP responses
  static void _logResponse(
    Request request,
    Response response, {
    required String requestId,
    required int duration,
    required bool logHeaders,
    required LogLevel level,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      '← ${response.statusCode} ${request.method} ${request.requestedUri}',
    );
    buffer.writeln('  Request ID: $requestId');
    buffer.writeln('  Duration: ${duration}ms');
    buffer.writeln(
      '  Content Type: ${response.headers['content-type'] ?? 'None'}',
    );

    if (logHeaders && response.headers.isNotEmpty) {
      buffer.writeln('  Headers:');
      response.headers.forEach((key, value) {
        if (!_isSensitiveHeader(key)) {
          buffer.writeln('    $key: $value');
        }
      });
    }

    // Color code based on status
    final logLevel = _getLogLevelForStatus(response.statusCode);
    _log(buffer.toString().trim(), logLevel);
  }

  /// Logs errors that occur during request processing
  static void _logError(
    Request request,
    dynamic error,
    StackTrace stackTrace, {
    required String requestId,
    required int duration,
    required LogLevel level,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('✗ ERROR ${request.method} ${request.requestedUri}');
    buffer.writeln('  Request ID: $requestId');
    buffer.writeln('  Duration: ${duration}ms');
    buffer.writeln('  Error: $error');
    buffer.writeln('  Stack Trace:');
    buffer.writeln('    ${stackTrace.toString().replaceAll('\n', '\n    ')}');

    _log(buffer.toString().trim(), LogLevel.error);
  }

  /// Generates a unique request ID
  static String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'req_$random';
  }

  /// Checks if a header contains sensitive information
  static bool _isSensitiveHeader(String headerName) {
    final sensitiveHeaders = {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
    };
    return sensitiveHeaders.contains(headerName.toLowerCase());
  }

  /// Gets appropriate log level based on HTTP status code
  static LogLevel _getLogLevelForStatus(int statusCode) {
    if (statusCode >= 500) return LogLevel.error;
    if (statusCode >= 400) return LogLevel.warning;
    if (statusCode >= 300) return LogLevel.info;
    return LogLevel.info;
  }

  /// Logs a message with the specified level
  static void _log(String message, LogLevel level) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final colorCode = _getColorCode(level);
    final resetCode = '\x1B[0m';

    if (Platform.isLinux || Platform.isMacOS) {
      // Use colors on Unix-like systems
      print('$colorCode[$timestamp] $levelStr $message$resetCode');
    } else {
      // Plain text on other systems
      print('[$timestamp] $levelStr $message');
    }
  }

  /// Gets ANSI color code for log level
  static String _getColorCode(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m'; // Green
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
    }
  }

  /// Creates a simple logging middleware for development
  static Middleware simple() {
    return create(
      logRequests: true,
      logResponses: true,
      logHeaders: false,
      logBody: false,
      level: LogLevel.info,
    );
  }

  /// Creates a detailed logging middleware for debugging
  static Middleware detailed() {
    return create(
      logRequests: true,
      logResponses: true,
      logHeaders: true,
      logBody: true,
      level: LogLevel.debug,
    );
  }

  /// Creates a minimal logging middleware for production
  static Middleware minimal() {
    return create(
      logRequests: true,
      logResponses: true,
      logHeaders: false,
      logBody: false,
      level: LogLevel.warning,
    );
  }
}

/// Log levels for different types of messages
enum LogLevel { debug, info, warning, error }
