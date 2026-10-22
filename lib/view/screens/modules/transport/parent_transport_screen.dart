import 'package:flutter/material.dart';
import 'student_transport_screen.dart';

class ParentTransportScreen extends StatelessWidget {
  final int? studentId;
  const ParentTransportScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context) =>
      StudentTransportScreen(studentId: studentId, parentMode: true);
}
