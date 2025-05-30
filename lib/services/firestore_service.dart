import 'dart:convert';
import 'dart:io';
import '../models/note.dart';

/// Service class for Firestore operations (Mock implementation for development)
class FirestoreService {
  static const String _collectionName = 'notes';
  late final String _projectId;
  final Map<String, Note> _mockDatabase = {};

  FirestoreService._();

  static FirestoreService? _instance;

  /// Singleton instance
  static FirestoreService get instance {
    _instance ??= FirestoreService._();
    return _instance!;
  }

  /// Initialize Firestore connection
  Future<void> initialize({String? projectId}) async {
    try {
      // Get project ID from environment or parameter
      _projectId =
          projectId ??
          Platform.environment['GOOGLE_CLOUD_PROJECT_ID'] ??
          'notes-api-project';

      print(
        'Firestore service initialized for project: $_projectId (Mock Mode)',
      );
      print(
        'Note: This is a mock implementation. For production, configure real Firestore credentials.',
      );
    } catch (e) {
      print('Error initializing Firestore: $e');
      rethrow;
    }
  }

  /// Create a new note
  Future<Note> createNote(Note note) async {
    try {
      _mockDatabase[note.id] = note;

      print('Created note with ID: ${note.id}');
      return note;
    } catch (e) {
      print('Error creating note: $e');
      throw FirestoreException('Failed to create note: $e');
    }
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    try {
      final notes = _mockDatabase.values.toList();

      // Sort by creation date (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Retrieved ${notes.length} notes');
      return notes;
    } catch (e) {
      print('Error getting all notes: $e');
      throw FirestoreException('Failed to retrieve notes: $e');
    }
  }

  /// Get a note by ID
  Future<Note?> getNoteById(String id) async {
    try {
      final note = _mockDatabase[id];

      if (note == null) {
        print('Note not found with ID: $id');
        return null;
      }

      print('Retrieved note with ID: $id');
      return note;
    } catch (e) {
      print('Error getting note by ID: $e');
      throw FirestoreException('Failed to retrieve note: $e');
    }
  }

  /// Update an existing note
  Future<Note?> updateNote(String id, Note updatedNote) async {
    try {
      if (!_mockDatabase.containsKey(id)) {
        print('Note not found for update with ID: $id');
        return null;
      }

      _mockDatabase[id] = updatedNote;

      print('Updated note with ID: $id');
      return updatedNote;
    } catch (e) {
      print('Error updating note: $e');
      throw FirestoreException('Failed to update note: $e');
    }
  }

  /// Delete a note by ID
  Future<bool> deleteNote(String id) async {
    try {
      if (!_mockDatabase.containsKey(id)) {
        print('Note not found for deletion with ID: $id');
        return false;
      }

      _mockDatabase.remove(id);

      print('Deleted note with ID: $id');
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      throw FirestoreException('Failed to delete note: $e');
    }
  }

  /// Check if a note exists
  Future<bool> noteExists(String id) async {
    try {
      return _mockDatabase.containsKey(id);
    } catch (e) {
      print('Error checking note existence: $e');
      throw FirestoreException('Failed to check note existence: $e');
    }
  }

  /// Get notes count
  Future<int> getNotesCount() async {
    try {
      return _mockDatabase.length;
    } catch (e) {
      print('Error getting notes count: $e');
      throw FirestoreException('Failed to get notes count: $e');
    }
  }

  /// Search notes by title or content
  Future<List<Note>> searchNotes(String query) async {
    try {
      final allNotes = await getAllNotes();

      final searchQuery = query.toLowerCase();
      final filteredNotes =
          allNotes.where((note) {
            return note.title.toLowerCase().contains(searchQuery) ||
                note.content.toLowerCase().contains(searchQuery);
          }).toList();

      print('Found ${filteredNotes.length} notes matching query: $query');
      return filteredNotes;
    } catch (e) {
      print('Error searching notes: $e');
      throw FirestoreException('Failed to search notes: $e');
    }
  }

  /// Add some sample data for testing
  Future<void> addSampleData() async {
    try {
      final sampleNotes = [
        Note.create(
          title: 'Welcome to Notes API',
          content:
              'This is your first note! You can create, read, update, and delete notes using this API.',
        ),
        Note.create(
          title: 'API Endpoints',
          content:
              'Available endpoints:\n- GET /api/notes (list all)\n- POST /api/notes (create)\n- PUT /api/notes/{id} (update)\n- DELETE /api/notes/{id} (delete)',
        ),
        Note.create(
          title: 'Development Mode',
          content:
              'This API is currently running in development mode with a mock database. Configure Firestore credentials for production use.',
        ),
      ];

      for (final note in sampleNotes) {
        await createNote(note);
      }

      print('Added ${sampleNotes.length} sample notes');
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }

  /// Close Firestore connection (cleanup)
  Future<void> close() async {
    try {
      print('Firestore service closed');
    } catch (e) {
      print('Error closing Firestore service: $e');
    }
  }
}

/// Custom exception for Firestore operations
class FirestoreException implements Exception {
  final String message;

  const FirestoreException(this.message);

  @override
  String toString() => 'FirestoreException: $message';
}
