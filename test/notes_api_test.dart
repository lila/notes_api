import 'package:notes_api/notes_api.dart';
import 'package:test/test.dart';

void main() {
  group('Note Model Tests', () {
    test('Note creation with valid data', () {
      final note = Note.create(
        title: 'Test Note',
        content: 'This is a test note content',
      );

      expect(note.title, equals('Test Note'));
      expect(note.content, equals('This is a test note content'));
      expect(note.id, isNotEmpty);
      expect(note.createdAt, isA<DateTime>());
      expect(note.updatedAt, isA<DateTime>());
    });

    test('Note validation - title required', () {
      final error = Note.validateTitle('');
      expect(error, equals('Title is required'));
    });

    test('Note validation - content required', () {
      final error = Note.validateContent('');
      expect(error, equals('Content is required'));
    });

    test('Note validation - title too long', () {
      final longTitle = 'a' * 201;
      final error = Note.validateTitle(longTitle);
      expect(error, equals('Title must be 200 characters or less'));
    });

    test('Note validation - content too long', () {
      final longContent = 'a' * 10001;
      final error = Note.validateContent(longContent);
      expect(error, equals('Content must be 10,000 characters or less'));
    });

    test('Note JSON serialization', () {
      final note = Note.create(title: 'Test Note', content: 'Test content');

      final json = note.toJson();
      expect(json['title'], equals('Test Note'));
      expect(json['content'], equals('Test content'));
      expect(json['id'], equals(note.id));
    });

    test('Note copyWith updates timestamp', () {
      final originalNote = Note.create(
        title: 'Original Title',
        content: 'Original content',
      );

      // Wait a bit to ensure different timestamp
      final updatedNote = originalNote.copyWith(title: 'Updated Title');

      expect(updatedNote.title, equals('Updated Title'));
      expect(updatedNote.content, equals('Original content'));
      expect(updatedNote.id, equals(originalNote.id));
      expect(updatedNote.createdAt, equals(originalNote.createdAt));
      expect(updatedNote.updatedAt.isAfter(originalNote.updatedAt), isTrue);
    });
  });
}
