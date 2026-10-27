import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/guardian_model.dart';
import '../../widgets/guardian_avatar.dart';

class GuardianDetailsScreen extends StatelessWidget {
  final GuardianModel guardian;
  const GuardianDetailsScreen({super.key, required this.guardian});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guardian Details')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: GuardianAvatar(guardian: guardian, radius: 48)),
        const SizedBox(height: 16),
        Text(
          guardian.name.isEmpty ? 'Guardian' : guardian.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          guardian.relation,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        _detail(Icons.family_restroom, 'Relation', guardian.relation),
        _detail(Icons.phone_outlined, 'Phone', guardian.phone),
        _detail(Icons.email_outlined, 'Email', guardian.email),
        _detail(Icons.work_outline, 'Occupation', guardian.occupation),
        _detail(Icons.home_outlined, 'Address', guardian.address),
      ],
    ),
  );

  Widget _detail(IconData icon, String label, String value) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: SelectableText(value.isEmpty ? 'Not provided' : value),
    ),
  );
}
