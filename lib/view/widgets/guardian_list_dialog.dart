import 'package:flutter/material.dart';
import '../../data/models/guardian_model.dart';
import '../../data/repositories/guardian_repository.dart';
import 'guardian_avatar.dart';
import '../screens/modules/guardian_details_screen.dart';

class GuardianListDialog extends StatefulWidget {
  final String? admissionNo;
  final GuardianRepository? repository;
  const GuardianListDialog({super.key, this.admissionNo, this.repository});

  static Future<void> show(BuildContext context, {String? admissionNo}) async {
    final guardian = await showDialog<GuardianModel>(
      context: context,
      builder: (_) => GuardianListDialog(admissionNo: admissionNo),
    );
    if (guardian == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuardianDetailsScreen(guardian: guardian),
      ),
    );
  }

  @override
  State<GuardianListDialog> createState() => _GuardianListDialogState();
}

class _GuardianListDialogState extends State<GuardianListDialog> {
  late final GuardianRepository _repository =
      widget.repository ?? GuardianRepository();
  late Future<List<GuardianModel>> _guardians;

  @override
  void initState() {
    super.initState();
    _guardians = _repository.getGuardians(admissionNo: widget.admissionNo);
  }

  void _reload() => setState(() {
    _guardians = _repository.getGuardians(admissionNo: widget.admissionNo);
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Guardian Details'),
    content: SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .55,
        ),
        child: FutureBuilder<List<GuardianModel>>(
          future: _guardians,
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
                  const Text(
                    'Unable to load guardians. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              );
            }
            final guardians = snapshot.data ?? [];
            if (guardians.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No guardians have been added for this student.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: guardians.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final guardian = guardians[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: GuardianAvatar(guardian: guardian),
                  title: Text(
                    guardian.name.isEmpty ? 'Guardian' : guardian.name,
                  ),
                  subtitle: Text(guardian.relation),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, guardian),
                );
              },
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _reload, child: const Text('Refresh')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
