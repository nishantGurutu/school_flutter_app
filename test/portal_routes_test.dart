import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/core/routes/routes.dart';
import 'package:school_desk_app/core/routes/routes_name.dart';

void main() {
  test('Family routes preserve selected child identity', () {
    for (final name in [
      RoutesName.attendance,
      RoutesName.fees,
      RoutesName.exam,
      RoutesName.homework,
      RoutesName.timetable,
      '/portal/report',
      '/portal/diary',
      '/portal/certificates',
      '/portal/notifications',
      '/portal/onlineExams',
    ]) {
      const arguments = {'admissionNo': 'SECOND-CHILD'};
      final route = Routes.generateRoute(
        RouteSettings(name: name, arguments: arguments),
      );
      expect(route.settings.name, name);
      expect(route.settings.arguments, same(arguments));
    }
  });
}
