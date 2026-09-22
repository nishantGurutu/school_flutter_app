import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';
import '../../../data/models/school_models.dart';

class NoticeScreen extends StatelessWidget {
  final bool isInline;

  const NoticeScreen({super.key, this.isInline = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isInline
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'Noticeboard',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = state.notices;

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined, size: 48.sp, color: AppColors.textMuted),
                  12.h.height,
                  const Text('No recent announcements published.'),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            itemCount: notices.length,
            itemBuilder: (context, i) {
              final notice = notices[i];
              Color catColor;
              String catLabel;

              switch (notice.category) {
                case NoticeCategory.urgent:
                  catColor = AppColors.error;
                  catLabel = 'Urgent';
                  break;
                case NoticeCategory.regular:
                  catColor = AppColors.primary;
                  catLabel = 'General';
                  break;
                case NoticeCategory.informational:
                  catColor = AppColors.info;
                  catLabel = 'Info';
                  break;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: catColor.withOpacity(0.25)),
                          ),
                          child: Text(
                            catLabel,
                            style: TextStyle(color: catColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _formatDate(notice.date),
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                        ),
                      ],
                    ),
                    12.h.height,
                    Text(
                      notice.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    8.h.height,
                    Text(
                      notice.content,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
