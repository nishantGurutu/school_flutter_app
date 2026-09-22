import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';
import '../../../data/models/school_models.dart';
import '../../widgets/glass_card.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

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
          'Payroll',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPayroll = state.payroll;
          final grossTotal = allPayroll.fold<double>(0, (s, p) => s + p.grossSalary);
          final deductionsTotal = allPayroll.fold<double>(0, (s, p) => s + p.deductions);
          final netTotal = allPayroll.fold<double>(0, (s, p) => s + p.netPay);
          final pendingCount = allPayroll.where((p) => p.status == PayrollStatus.pending).length;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: EdgeInsets.all(20.w),
                  borderColor: AppColors.warning.withOpacity(0.3),
                  child: Column(
                    children: [
                      Text(
                        'Payroll Summary - June 2026',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                      14.h.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(label: 'Gross', amount: grossTotal, color: AppColors.textPrimary),
                          _SummaryItem(label: 'Deductions', amount: deductionsTotal, color: AppColors.error),
                          _SummaryItem(label: 'Net Pay', amount: netTotal, color: AppColors.success),
                        ],
                      ),
                      if (pendingCount > 0) ...[
                        14.h.height,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '$pendingCount pending payment${pendingCount > 1 ? 's' : ''} for next cycle',
                            style: TextStyle(color: AppColors.warning, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                24.h.height,

                Text(
                  'Employee Salaries',
                  style: context.h3.copyWith(fontWeight: FontWeight.w800),
                ),
                14.h.height,

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allPayroll.length,
                  itemBuilder: (context, i) {
                    final pay = allPayroll[i];
                    final isPending = pay.status == PayrollStatus.pending;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isPending ? AppColors.warning.withOpacity(0.2) : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42.w,
                                height: 42.w,
                                decoration: BoxDecoration(
                                  color: isPending ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Center(
                                  child: Icon(
                                    isPending ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded,
                                    color: isPending ? AppColors.warning : AppColors.success,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                              12.w.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pay.employeeName,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    2.h.height,
                                    Text(
                                      pay.designation,
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${pay.netPay.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          12.h.height,
                          Divider(color: AppColors.border, height: 1.h),
                          12.h.height,
                          Row(
                            children: [
                              _PayDetail(label: 'Gross', amount: pay.grossSalary, color: AppColors.textPrimary),
                              12.w.width,
                              _PayDetail(label: 'Deductions', amount: pay.deductions, color: AppColors.error),
                            ],
                          ),
                          12.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pay.month,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? AppColors.warning.withOpacity(0.08)
                                      : AppColors.success.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  isPending ? 'Pending' : 'Paid',
                                  style: TextStyle(
                                    color: isPending ? AppColors.warning : AppColors.success,
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

                100.h.height,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp, fontWeight: FontWeight.w500),
        ),
        6.h.height,
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PayDetail extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _PayDetail({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
