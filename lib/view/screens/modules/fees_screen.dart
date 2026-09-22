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

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  void _showPaymentDialog(BuildContext context, FeeRecord fee) {
    final cardController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Details'),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        fee.title,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      4.h.height,
                      Text(
                        'Total Payable: ₹${fee.amount.toStringAsFixed(0)}',
                        style: context.h2.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                      18.h.height,

                      // Card Number field
                      TextFormField(
                        controller: cardController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Debit/Credit Card Number',
                          hintText: '4321 0987 6543 2109',
                          prefixIcon: Icon(Icons.credit_card_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter card number';
                          if (v.trim().replaceAll(" ", "").length < 16) return 'Enter valid 16-digit card';
                          return null;
                        },
                      ),
                      12.h.height,

                      // Expiry & CVV
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                hintText: 'MM/YY',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter expiry';
                                return null;
                              },
                            ),
                          ),
                          12.w.width,
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                hintText: '•••',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter CVV';
                                if (v.trim().length < 3) return 'Enter 3-digit CVV';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      20.h.height,

                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final userId = context.read<AuthBloc>().state.user?.id ?? 'parent_1';
                            context.read<SchoolBloc>().add(
                                  PayFeeRequested(userId: userId, feeId: fee.id),
                                );
                            Navigator.pop(dialogCtx);
                            context.showAppSnackBar('Contacting payment gateway. Processing transaction...');
                          }
                        },
                        child: Text('Pay Dues (₹${fee.amount.toStringAsFixed(0)})'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fees & Transactions',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null && state.actionSuccessMessage!.contains('payment')) {
            context.showAppSnackBar(state.actionSuccessMessage!);
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final outstanding = state.totalUnpaidFees;
            final unpaidRecords = state.fees.where((f) => f.status == FeeStatus.unpaid).toList();
            final paidRecords = state.fees.where((f) => f.status == FeeStatus.paid).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  GlassCard(
                    padding: EdgeInsets.all(20.w),
                    borderColor: outstanding > 0 ? AppColors.error.withOpacity(0.3) : AppColors.success.withOpacity(0.3),
                    child: Column(
                      children: [
                        Text(
                          'Outstanding Dues Balance',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                        ),
                        10.h.height,
                        Text(
                          '₹${outstanding.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: outstanding > 0 ? AppColors.error : AppColors.success,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (outstanding > 0) ...[
                          16.h.height,
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(context, unpaidRecords.first),
                            icon: const Icon(Icons.payment_rounded, color: Colors.white),
                            label: const Text('Pay Dues Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ] else ...[
                          14.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                              8.w.width,
                              Text(
                                'All clear! No pending payments.',
                                style: TextStyle(color: AppColors.success, fontSize: 13.sp, fontWeight: FontWeight.bold),
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
                      final statusColor = isPaid ? AppColors.success : AppColors.error;
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
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
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
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
