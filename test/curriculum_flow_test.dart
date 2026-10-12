import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/curriculum_model.dart';
import 'package:school_desk_app/view/screens/modules/topic_notes_screen.dart';
import 'package:school_desk_app/utils/app_url.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';

class FakeNotesRepository extends ApiSchoolRepository {
  String? requestedTopic;
  bool fail = false;
  @override
  Future<TopicNotesResponseModel?> getTopicNotes(String topicId) async {
    requestedTopic = topicId;
    if (fail) throw Exception('Connection failed');
    return TopicNotesResponseModel(topicId: topicId, topicTitle: 'Fractions', subjectName: 'Math', notes: [StudyNoteModel(id: '1', title: 'Teacher examples', contentHtml: '<p>One half plus one half equals one.</p>')]);
  }
}

void main() {
  testWidgets('Topic fetch leads to the actual note reader', (tester) async {
    final repository = FakeNotesRepository();
    await tester.pumpWidget(MaterialApp(home: TopicNotesScreen(repository: repository, topicId: '42', chapterId: '8', subjectName: 'Math')));
    await tester.pumpAndSettle();
    expect(repository.requestedTopic, '42');
    expect(find.text('Teacher examples'), findsOneWidget);
    await tester.tap(find.text('Read notes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('One half plus one half equals one.', findRichText: true), findsWidgets);
  });

  testWidgets('Failed notes request can be retried', (tester) async {
    final repository = FakeNotesRepository()..fail = true;
    await tester.pumpWidget(MaterialApp(home: TopicNotesScreen(repository: repository, topicId: '42', subjectName: 'Math')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load notes. Please try again.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Teacher examples'), findsOneWidget);
  });
  test('Chapter response retains title and description', () {
    final model = TopicNotesResponseModel.fromJson({
      'chapterId': 8, 'chapterTitle': 'Fractions', 'description': 'Chapter overview', 'notes': [],
    });
    expect(model.topicId, '8');
    expect(model.topicTitle, 'Fractions');
    expect(model.topicDescription, 'Chapter overview');
  });

  test('Attachment URLs use configured server and reject unsafe schemes', () {
    expect(resolveNoteUrl('/api/files/download/algebra.pdf')?.host, Uri.parse(AppUrl.baseUrl).host);
    expect(resolveNoteUrl('https://school.example/notes.pdf')?.host, 'school.example');
    expect(resolveNoteUrl('javascript:alert(1)'), isNull);
    expect(resolveNoteUrl('file:///secret'), isNull);
    expect(resolveNoteUrl(''), isNull);
  });

  testWidgets('Reader displays teacher HTML content instead of placeholder', (tester) async {
    final note = StudyNoteModel(id: '1', title: 'Addition', contentHtml: '<h2>Adding fractions</h2><p>Find a common denominator.</p>');
    await tester.pumpWidget(MaterialApp(home: InAppNoteReaderScreen(note: note, topicTitle: 'Fractions', subjectName: 'Math')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Adding fractions', findRichText: true), findsWidgets);
    expect(find.textContaining('Find a common denominator.', findRichText: true), findsWidgets);
    expect(find.text('Interactive Fullscreen View'), findsNothing);
    expect(find.textContaining('Open attachment'), findsNothing);
  });
}
