import 'package:school_desk_app/config/color/app_color.dart';
import 'package:school_desk_app/config/routes/routes_name.dart';
import 'package:school_desk_app/model/chat_item_model.dart';
import 'package:school_desk_app/utils/extensions/text_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatTile extends StatelessWidget {
  final ChatItem chat;
  final Color badgeColor;

  const ChatTile({super.key, required this.chat, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundImage: chat.imageUrl != null
                  ? NetworkImage(chat.imageUrl!)
                  : null,
              child: chat.imageUrl == null ? Text(chat.name[0]) : null,
            ),
          ],
        ),
        title: Row(
          children: [
            if (chat.isVerified) ...[
              Icon(
                Icons.check_circle,
                color: const Color(0xFFC46AFF),
                size: 18.sp,
              ),
              SizedBox(width: 5.w),
            ],
            Expanded(
              child: Text(
                chat.name,
                style: context.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Text(
              chat.timeLabel,
              style: context.bodySmall.copyWith(
                color: Colors.grey,
                fontSize: 10.sp,
              ),
            ),
            SizedBox(width: 5.w),
            Icon(Icons.done_all, color: Colors.grey, size: 16.sp),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Row(
            children: [
              Icon(Icons.reply, size: 16.sp, color: Colors.grey),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  chat.message,
                  style: context.bodySmall.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            RoutesName.message,
            arguments: {'contactName': chat.name},
          );
        },
      ),
    );
  }
}
