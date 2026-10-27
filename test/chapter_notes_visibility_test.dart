import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/curriculum_model.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';
import 'package:school_desk_app/view/screens/modules/subject_curriculum_screen.dart';

class ChapterNotesRepository extends ApiSchoolRepository {
  List<StudyNoteModel> notes = [
    StudyNoteModel(
      id: '1',
      title: 'Teacher examples',
      contentHtml: '<p>One half plus one half equals one.</p>',
      fileName: 'fractions.pdf',
      fileUrl: '/api/files/download/fractions.pdf',
    ),
  ];
  @override
  Future<SubjectCurriculumModel?> getSubjectCurriculum(
    String subjectId,
  ) async => SubjectCurriculumModel(
    subjectId: subjectId,
    subjectName: 'Math',
    subjectCode: 'M7',
    totalChapters: 1,
    totalNotes: notes.length,
    chapters: [
      CurriculumChapterModel(
        chapterId: '10',
        chapterNumber: 'Chapter 1',
        chapterTitle: 'Fractions',
        notes: notes,
        notesCount: notes.length,
      ),
    ],
  );
}

void main() {
  testWidgets(
    'Chapter without topics displays published notes and PDF action',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: SubjectCurriculumScreen(
              repository: ChapterNotesRepository(),
              subjectId: '4',
              subjectName: 'Math',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Teacher examples'), findsOneWidget);
      expect(find.text('fractions.pdf'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('View PDF'), findsOneWidget);
    },
  );
}
