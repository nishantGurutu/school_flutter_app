import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/guardian_model.dart';
import '../../utils/app_url.dart';

class GuardianAvatar extends StatelessWidget {
  final GuardianModel guardian;
  final double radius;
  const GuardianAvatar({super.key, required this.guardian, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final photo = guardian.photo;
    final uri = Uri.tryParse(photo);
    final url = uri?.hasScheme == true
        ? photo
        : Uri.parse(
            '${Uri.parse(AppUrl.baseUrl).origin}/',
          ).resolve(photo).toString();
    final fallback = Container(
      color: AppColors.primary.withValues(alpha: .1),
      child: Icon(Icons.person_outline, color: AppColors.primary, size: radius),
    );
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: photo.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
