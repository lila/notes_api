/// Notes API Library
///
/// A REST API for managing user notes with CRUD operations using Firestore.
library notes_api;

// Export models
export 'models/note.dart';

// Export services
export 'services/firestore_service.dart';

// Export handlers
export 'handlers/notes_handler.dart';

// Export middleware
export 'middleware/cors_middleware.dart';
export 'middleware/logging_middleware.dart';

// Export utilities
export 'utils/response_utils.dart';
