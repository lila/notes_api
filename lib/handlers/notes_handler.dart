import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../models/note.dart';
import '../services/firestore_service.dart';
import '../utils/response_utils.dart';

/// Handler for notes-related HTTP requests
class NotesHandler {
  final FirestoreService _firestoreService;

  NotesHandler(this._firestoreService);

  /// Creates the router with all note endpoints
  Router get router {
    final router = Router();

    // GET /api/notes - Get all notes
    router.get('/api/notes', _getAllNotes);

    // GET /api/notes/<id> - Get note by ID
    router.get('/api/notes/<id>', _getNoteById);

    // POST /api/notes - Create new note
    router.post('/api/notes', _createNote);

    // PUT /api/notes/<id> - Update note
    router.put('/api/notes/<id>', _updateNote);

    // DELETE /api/notes/<id> - Delete note
    router.delete('/api/notes/<id>', _deleteNote);

    // GET /api/notes/search?q=<query> - Search notes
    router.get('/api/notes/search', _searchNotes);

    return router;
  }

  /// Handles GET /api/notes - retrieve all notes
  Future<Response> _getAllNotes(Request request) async {
    try {
      final notes = await _firestoreService.getAllNotes();
      final notesJson = notes.map((note) => note.toJson()).toList();

      return ResponseUtils.successList(items: notesJson, itemName: 'notes');
    } catch (e) {
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Handles GET /api/notes/<id> - retrieve note by ID
  Future<Response> _getNoteById(Request request) async {
    try {
      final id = request.params['id']!;

      if (id.isEmpty) {
        return ResponseUtils.badRequest(message: 'Note ID is required');
      }

      final note = await _firestoreService.getNoteById(id);

      if (note == null) {
        return ResponseUtils.notFound(
          message: 'Note not found',
          resourceId: id,
        );
      }

      return ResponseUtils.success(data: note.toJson());
    } catch (e) {
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Handles POST /api/notes - create new note
  Future<Response> _createNote(Request request) async {
    try {
      final jsonData = await ResponseUtils.parseJsonBody(request);

      if (jsonData == null) {
        return ResponseUtils.badRequest(message: 'Request body is required');
      }

      // Validate required fields
      final validationError = ResponseUtils.validateRequiredFields(jsonData, [
        'title',
        'content',
      ]);
      if (validationError != null) {
        return ResponseUtils.validationError(message: validationError);
      }

      // Validate title
      final titleError = Note.validateTitle(jsonData['title']);
      if (titleError != null) {
        return ResponseUtils.validationError(
          message: titleError,
          field: 'title',
          value: jsonData['title'],
        );
      }

      // Validate content
      final contentError = Note.validateContent(jsonData['content']);
      if (contentError != null) {
        return ResponseUtils.validationError(
          message: contentError,
          field: 'content',
          value: jsonData['content'],
        );
      }

      // Create note
      final note = Note.create(
        title: jsonData['title'].toString().trim(),
        content: jsonData['content'].toString().trim(),
      );

      final createdNote = await _firestoreService.createNote(note);

      return ResponseUtils.created(data: createdNote.toJson());
    } catch (e) {
      if (e is FormatException) {
        return ResponseUtils.badRequest(message: 'Invalid JSON format');
      }
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Handles PUT /api/notes/<id> - update existing note
  Future<Response> _updateNote(Request request) async {
    try {
      final id = request.params['id']!;

      if (id.isEmpty) {
        return ResponseUtils.badRequest(message: 'Note ID is required');
      }

      final jsonData = await ResponseUtils.parseJsonBody(request);

      if (jsonData == null) {
        return ResponseUtils.badRequest(message: 'Request body is required');
      }

      // Check if note exists
      final existingNote = await _firestoreService.getNoteById(id);
      if (existingNote == null) {
        return ResponseUtils.notFound(
          message: 'Note not found',
          resourceId: id,
        );
      }

      // Validate title if provided
      if (jsonData.containsKey('title')) {
        final titleError = Note.validateTitle(jsonData['title']);
        if (titleError != null) {
          return ResponseUtils.validationError(
            message: titleError,
            field: 'title',
            value: jsonData['title'],
          );
        }
      }

      // Validate content if provided
      if (jsonData.containsKey('content')) {
        final contentError = Note.validateContent(jsonData['content']);
        if (contentError != null) {
          return ResponseUtils.validationError(
            message: contentError,
            field: 'content',
            value: jsonData['content'],
          );
        }
      }

      // Update note with new values
      final updatedNote = existingNote.copyWith(
        title: jsonData['title']?.toString().trim(),
        content: jsonData['content']?.toString().trim(),
      );

      final result = await _firestoreService.updateNote(id, updatedNote);

      if (result == null) {
        return ResponseUtils.notFound(
          message: 'Note not found',
          resourceId: id,
        );
      }

      return ResponseUtils.success(data: result.toJson());
    } catch (e) {
      if (e is FormatException) {
        return ResponseUtils.badRequest(message: 'Invalid JSON format');
      }
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Handles DELETE /api/notes/<id> - delete note
  Future<Response> _deleteNote(Request request) async {
    try {
      final id = request.params['id']!;

      if (id.isEmpty) {
        return ResponseUtils.badRequest(message: 'Note ID is required');
      }

      final deleted = await _firestoreService.deleteNote(id);

      if (!deleted) {
        return ResponseUtils.notFound(
          message: 'Note not found',
          resourceId: id,
        );
      }

      return ResponseUtils.noContent();
    } catch (e) {
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Handles GET /api/notes/search?q=<query> - search notes
  Future<Response> _searchNotes(Request request) async {
    try {
      final query = request.url.queryParameters['q'];

      if (query == null || query.trim().isEmpty) {
        return ResponseUtils.badRequest(
          message: 'Search query parameter "q" is required',
        );
      }

      final notes = await _firestoreService.searchNotes(query.trim());
      final notesJson = notes.map((note) => note.toJson()).toList();

      return ResponseUtils.successList(items: notesJson, itemName: 'notes');
    } catch (e) {
      return ResponseUtils.handleException(e, StackTrace.current);
    }
  }

  /// Creates a health check handler
  static Response healthCheck(Request request) {
    return ResponseUtils.healthCheck(
      additionalInfo: {'version': '1.0.0', 'environment': 'development'},
    );
  }

  /// Creates a 404 handler for unmatched routes
  static Response notFoundHandler(Request request) {
    return ResponseUtils.notFound(
      message:
          'Endpoint not found: ${request.method} ${request.requestedUri.path}',
    );
  }

  /// Creates a method not allowed handler
  static Response methodNotAllowedHandler(Request request) {
    return ResponseUtils.methodNotAllowed(
      method: request.method,
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    );
  }
}
