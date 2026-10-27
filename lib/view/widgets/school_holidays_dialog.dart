import 'package:flutter/material.dart';
import '../../data/models/school_models.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/api_school_repository.dart';

bool holidayVisibleToRole(HolidayModel holiday, UserRole role) {
  final target = (holiday.target ?? 'ALL').trim().toUpperCase();
  if (target.isEmpty || target == 'ALL') return true;
  if ([UserRole.admin, UserRole.masterAdmin].contains(role)) return true;
  return [UserRole.student, UserRole.parent].contains(role)
      ? ['STUDENT', 'STUDENTS'].contains(target)
      : ['STAFF', 'TEACHER', 'TEACHERS'].contains(target);
}

class SchoolHolidaysDialog extends StatefulWidget {
  final UserRole role;
  final ApiSchoolRepository? repository;
  const SchoolHolidaysDialog({super.key, required this.role, this.repository});

  static void show(BuildContext context, {required UserRole role}) {
    showDialog<void>(
      context: context,
      builder: (_) => SchoolHolidaysDialog(role: role),
    );
  }

  @override
  State<SchoolHolidaysDialog> createState() => _SchoolHolidaysDialogState();
}

class _SchoolHolidaysDialogState extends State<SchoolHolidaysDialog> {
  late final ApiSchoolRepository _repository =
      widget.repository ?? ApiSchoolRepository();
  late Future<List<HolidayModel>> _holidays;
  @override
  void initState() {
    super.initState();
    _holidays = _repository.getLiveHolidays();
  }

  void _refresh() => setState(() {
    _holidays = _repository.getLiveHolidays();
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('School Holidays'),
    content: SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: FutureBuilder<List<HolidayModel>>(
          future: _holidays,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load holidays. Please try again.'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              );
            }
            final holidays =
                (snapshot.data ?? [])
                    .where(
                      (holiday) => holidayVisibleToRole(holiday, widget.role),
                    )
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));
            if (holidays.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No holidays have been added for you yet.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: holidays.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final holiday = holidays[index];
                final dateRange =
                    holiday.endDate?.isNotEmpty == true &&
                        holiday.endDate != holiday.date
                    ? '${holiday.date} – ${holiday.endDate}'
                    : holiday.date;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(holiday.title),
                  subtitle: Text(
                    [
                      dateRange,
                      if (holiday.category?.isNotEmpty == true)
                        holiday.category!,
                      if (holiday.description?.isNotEmpty == true)
                        holiday.description!,
                    ].join('\n'),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _refresh, child: const Text('Refresh')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
