import 'package:url_launcher/url_launcher.dart';

import '../../../data/network/network_api_services.dart';
import '../../../utils/app_url.dart';
import '../../widgets/module_error.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../../logic/school/school_state.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../data/models/school_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/smooth_skeleton.dart';

class FeesScreen extends StatefulWidget {
  final bool isInline;
  final String? admissionNo;
  const FeesScreen({super.key, this.isInline = false, this.admissionNo});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFees();
    });
  }

  void _loadFees() {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user;
    final args = ModalRoute.of(context)?.settings.arguments;
    final admissionNo =
        widget.admissionNo ??
        (args is Map ? args['admissionNo']?.toString() : null);
    context.read<SchoolBloc>().add(
      FetchFeesRequested(currentUser?.id ?? '', admissionNo: admissionNo),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, FeeRecord fee) async {
    final api = NetworkApiService();
    Map<String, dynamic>? payment;
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Fee payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fee.title),
              if (payment == null)
                const Text(
                  'Continue to the school payment provider. Return here after payment and verify your receipt.',
                ),
              if (payment != null)
                Text(
                  'Amount: ${payment!['amount']}\nStatus: ${payment!['status']}',
                ),
              if (payment?['receipt'] != null)
                SelectableText('Receipt: ${payment!['receipt']}'),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (payment?['status'] != 'PAID')
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        update(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          if (payment == null) {
                            final id = fee.id.replaceFirst('fee_', '');
                            payment = Map<String, dynamic>.from(
                              await api.postApi(
                                '${AppUrl.baseUrl}/mobile/payments/fees/$id/checkout',
                                {},
                              ),
                            );
                            if (payment!['status'] == 'PENDING') {
                              final uri = Uri.parse(payment!['checkoutUrl']);
                              if (!await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              ))
                                throw Exception(
                                  'Unable to open checkout. Please retry.',
                                );
                            }
                          } else {
                            payment = Map<String, dynamic>.from(
                              await api.postApi(
                                '${AppUrl.baseUrl}/mobile/payments/${payment!['id']}/verify',
                                {},
                              ),
                            );
                          }
                          if (payment!['status'] == 'PAID' && mounted)
                            _loadFees();
                        } catch (e) {
                          error = e.toString();
                        } finally {
                          if (ctx.mounted) update(() => busy = false);
                        }
                      },
                child: Text(
                  busy
                      ? 'Please wait…'
                      : payment == null
                      ? 'Continue to payment'
                      : 'Verify payment',
                ),
              ),
            if (payment?['status'] == 'PENDING')
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        await launchUrl(
                          Uri.parse(payment!['checkoutUrl']),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                child: const Text('Open checkout'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isInline
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'Fees & Transactions',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Sync Fees',
            onPressed: _loadFees,
          ),
        ],
      ),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null &&
              state.actionSuccessMessage!.contains('payment')) {
            context.showAppSnackBar(state.actionSuccessMessage!);
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.errorMessage != null)
              return ModuleError(
                message: state.errorMessage!,
                retry: _loadFees,
              );
            if (state.isLoading && state.fees.isEmpty) {
              return const SmoothSkeletonCardList(count: 3);
            }

            final outstanding = state.totalUnpaidFees;
            final unpaidRecords = state.fees
                .where((f) => f.status == FeeStatus.unpaid)
                .toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  GlassCard(
                    padding: EdgeInsets.all(20.w),
                    borderColor: outstanding > 0
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                    child: Column(
                      children: [
                        Text(
                          'Outstanding Dues Balance',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        10.h.height,
                        Text(
                          '₹${outstanding.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: outstanding > 0
                                ? AppColors.error
                                : AppColors.success,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (outstanding > 0) ...[
                          16.h.height,
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(
                              context,
                              unpaidRecords.first,
                            ),
                            icon: const Icon(
                              Icons.payment_rounded,
                              color: Colors.white,
                            ),
                            label: const Text('Pay Dues Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ] else ...[
                          14.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              8.w.width,
                              Text(
                                'All clear! No pending payments.',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  24.h.height,

                  // Bills Section Title
                  Text(
                    'Recent Transactions & Bills',
                    style: context.h3.copyWith(fontWeight: FontWeight.w800),
                  ),
                  14.h.height,

                  // List of payments
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.fees.length,
                    itemBuilder: (context, i) {
                      final fee = state.fees[i];
                      final isPaid = fee.status == FeeStatus.paid;
                      final statusColor = isPaid
                          ? AppColors.success
                          : AppColors.error;
                      final statusLabel = isPaid ? 'Paid' : 'Unpaid';

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fee.title,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  6.h.height,
                                  Text(
                                    isPaid
                                        ? 'Receipt No: ${fee.transactionId ?? "TXN"}'
                                        : 'Due Date: ${_formatDate(fee.dueDate)}',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${fee.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                4.h.height,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  100.h.height, // Spacer for floating nav bar
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
