import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/view/widgets/study_note_pdf_preview.dart';
import 'package:school_desk_app/view/screens/modules/topic_notes_screen.dart';
import 'package:school_desk_app/data/models/curriculum_model.dart';

void main() {
  test('Recognizes PDFs by metadata, filename and URL path', () {
    expect(
      isPdfStudyNote(StudyNoteModel(id: '1', title: 'Note', fileType: 'PDF')),
      isTrue,
    );
    expect(
      isPdfStudyNote(
        StudyNoteModel(
          id: '1',
          title: 'Note',
          fileType: 'LINK',
          fileUrl: '/notes.PDF?download=true',
        ),
      ),
      isTrue,
    );
    expect(
      isPdfStudyNote(
        StudyNoteModel(
          id: '1',
          title: 'Note',
          fileType: 'IMAGE',
          fileName: 'note.png',
        ),
      ),
      isFalse,
    );
  });

  testWidgets('PDF loading failure is visible and retries in app', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<Uint8List>();
    final uri = Uri.parse('https://school.test/api/files/download/note.pdf');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyNotePdfPreview(
            uri: uri,
            fileName: 'note.pdf',
            loader: (requested) async {
              expect(requested, uri);
              calls++;
              if (calls == 1) throw StateError('Offline');
              return pending.future;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load PDF. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Retry PDF'));
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    pending.complete(Uint8List(0));
    await tester.pump();
  });
}
