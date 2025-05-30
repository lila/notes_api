import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:notes_api/services/firestore_service.dart';
import 'package:notes_api/handlers/notes_handler.dart';
import 'package:notes_api/middleware/cors_middleware.dart';
import 'package:notes_api/middleware/logging_middleware.dart';
import 'package:notes_api/utils/response_utils.dart';

/// Main server entry point
Future<void> main(List<String> arguments) async {
  // Load environment variables
  final env = DotEnv();
  try {
    env.load();
    print('Environment variables loaded');
  } catch (e) {
    print('No .env file found, using system environment variables');
  }

  // Get configuration from environment
  final port =
      int.tryParse(env['PORT'] ?? Platform.environment['PORT'] ?? '8080') ??
      8080;
  final environment =
      env['ENVIRONMENT'] ??
      Platform.environment['ENVIRONMENT'] ??
      'development';
  final projectId =
      env['GOOGLE_CLOUD_PROJECT_ID'] ??
      Platform.environment['GOOGLE_CLOUD_PROJECT_ID'];

  print('Starting Notes API server...');
  print('Environment: $environment');
  print('Port: $port');
  print('Project ID: ${projectId ?? 'Not specified'}');

  try {
    // Initialize Firestore service
    print('Initializing Firestore service...');
    await FirestoreService.instance.initialize(projectId: projectId);
    print('Firestore service initialized successfully');

    // Add sample data in development mode
    if (environment == 'development') {
      print('Adding sample data for development...');
      await FirestoreService.instance.addSampleData();
    }

    // Create handlers
    final notesHandler = NotesHandler(FirestoreService.instance);

    // Create main router
    final router = Router();

    // Health check endpoint
    router.get('/health', NotesHandler.healthCheck);

    // Mount notes routes
    router.mount('/', notesHandler.router.call);

    // Root endpoint
    router.get('/', (Request request) {
      return ResponseUtils.success(
        data: {
          'message': 'Notes API is running',
          'version': '1.0.0',
          'environment': environment,
          'endpoints': {
            'health': '/health',
            'notes': '/api/notes',
            'documentation': 'See ARCHITECTURE.md for API documentation',
          },
        },
      );
    });

    // Create middleware pipeline
    final pipeline = Pipeline()
        .addMiddleware(_createErrorHandler())
        .addMiddleware(_createCorsMiddleware(environment))
        .addMiddleware(_createLoggingMiddleware(environment))
        .addHandler(router.call);

    // Start the server
    final server = await shelf_io.serve(
      pipeline,
      InternetAddress.anyIPv4,
      port,
    );

    print('Server started successfully!');
    print('Listening on http://${server.address.host}:${server.port}');
    print('Health check: http://${server.address.host}:${server.port}/health');
    print(
      'API endpoints: http://${server.address.host}:${server.port}/api/notes',
    );

    // Handle graceful shutdown
    _setupGracefulShutdown(server);
  } catch (e, stackTrace) {
    print('Failed to start server: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Creates CORS middleware based on environment
Middleware _createCorsMiddleware(String environment) {
  if (environment == 'production') {
    // In production, you would specify allowed origins
    return CorsMiddleware.production(
      allowedOrigins: [
        'https://your-frontend-domain.com',
        // Add your production frontend URLs here
      ],
    );
  } else {
    // Development - allow all origins
    return CorsMiddleware.development();
  }
}

/// Creates logging middleware based on environment
Middleware _createLoggingMiddleware(String environment) {
  switch (environment) {
    case 'production':
      return LoggingMiddleware.minimal();
    case 'development':
      return LoggingMiddleware.detailed();
    default:
      return LoggingMiddleware.simple();
  }
}

/// Creates error handling middleware
Middleware _createErrorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        print(
          'Unhandled error in request ${request.method} ${request.requestedUri}',
        );
        print('Error: $error');
        print('Stack trace: $stackTrace');

        return ResponseUtils.handleException(error, stackTrace);
      }
    };
  };
}

/// Sets up graceful shutdown handling
void _setupGracefulShutdown(HttpServer server) {
  // Handle SIGTERM (Docker/Kubernetes shutdown)
  ProcessSignal.sigterm.watch().listen((signal) async {
    print('Received SIGTERM, shutting down gracefully...');
    await _shutdown(server);
  });

  // Handle SIGINT (Ctrl+C)
  ProcessSignal.sigint.watch().listen((signal) async {
    print('Received SIGINT, shutting down gracefully...');
    await _shutdown(server);
  });
}

/// Performs graceful shutdown
Future<void> _shutdown(HttpServer server) async {
  print('Closing server...');

  try {
    // Close the HTTP server
    await server.close(force: false);
    print('HTTP server closed');

    // Close Firestore service
    await FirestoreService.instance.close();
    print('Firestore service closed');

    print('Graceful shutdown completed');
    exit(0);
  } catch (e) {
    print('Error during shutdown: $e');
    exit(1);
  }
}
