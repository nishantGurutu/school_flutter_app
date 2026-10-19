import 'package:flutter/material.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/api_school_repository.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});
  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  final _repository = ApiSchoolRepository();
  List<HolidayModel> _events = [];
  bool _loading = true;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final events = await _repository.getHolidays();
    if (mounted) setState(() { _events = events; _loading = false; });
  }
  @override
  Widget build(BuildContext context) {
    final start = DateTime(_year, _month);
    final end = DateTime(_year, _month + 1);
    final events = _events.where((event) {
      final date = DateTime.tryParse(event.date);
      final last = DateTime.tryParse(event.endDate ?? '') ?? date;
      return date != null && last != null && date.isBefore(end) && !last.isBefore(start);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Calendar'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { final previous = DateTime(_year, _month - 1); _year = previous.year; _month = previous.month; })),
          Text(MaterialLocalizations.of(context).formatMonthYear(start)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { final next = DateTime(_year, _month + 1); _year = next.year; _month = next.month; })),
        ]),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: events.isEmpty ? [const Padding(padding: EdgeInsets.all(24), child: Text('No school calendar entries for this month.'))] : events.map((event) => Card(child: ListTile(
            leading: const Icon(Icons.event), title: Text(event.title),
            subtitle: Text('${event.date}${event.endDate == null ? '' : ' – ${event.endDate}'}\n${event.category ?? ''}\n${event.description ?? ''}'),
            isThreeLine: true,
          ))).toList(),
        ))),
      ]),
    );
  }
}
