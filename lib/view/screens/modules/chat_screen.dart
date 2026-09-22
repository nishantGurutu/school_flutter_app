import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';

class ChatScreen extends StatelessWidget {
  final bool isInline;

  const ChatScreen({super.key, this.isInline = false});

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
          'Messages',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final channels = state.chatChannels;

          if (channels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48.sp, color: AppColors.textMuted),
                  12.h.height,
                  const Text('No messages or active threads found.'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search input field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20.sp),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),

              // Channels listing
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: channels.length,
                  itemBuilder: (context, i) {
                    final ch = channels[i];

                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                            image: DecorationImage(
                              image: NetworkImage(ch.avatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          ch.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            ch.lastMessage,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Text(
                          ch.time,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RoutesName.chatDetail,
                            arguments: ch,
                          );
                        },
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      ),
                    );
                  },
                ),
              ),
              
              100.h.height, // Spacer for floating nav bar
            ],
          );
        },
      ),
    );
  }
}
