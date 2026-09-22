import 'package:school_desk_app/config/color/app_color.dart';
import 'package:school_desk_app/utils/extensions/text_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VisitorTile extends StatelessWidget {
  final String name;
  final int age;
  final String timeLabel;
  final String imageUrl;
  final bool isVerified;

  const VisitorTile({
    super.key,
    required this.name,
    required this.age,
    required this.timeLabel,
    required this.imageUrl,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28.r, backgroundImage: NetworkImage(imageUrl)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isVerified) ...[
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFFC46AFF),
                        size: 18.sp,
                      ),
                      SizedBox(width: 5.w),
                    ],
                    Text(
                      name,
                      style: context.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "• $age, Has Visited you",
                      style: context.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  timeLabel,
                  style: context.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
