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

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

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
          'Expenses',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Expense', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null && state.actionSuccessMessage!.contains('Expense')) {
            context.showAppSnackBar(state.actionSuccessMessage!);
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final pending = state.expenses.where((e) => e.status == ExpenseStatus.pending).toList();
            final approved = state.expenses.where((e) => e.status == ExpenseStatus.approved).toList();
            final totalPendingAmount = pending.fold<double>(0, (sum, e) => sum + e.amount);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    padding: EdgeInsets.all(20.w),
                    borderColor: totalPendingAmount > 0
                        ? AppColors.warning.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                    child: Column(
                      children: [
                        Text(
                          'Pending Approval Total',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                        ),
                        10.h.height,
                        Text(
                          '₹${totalPendingAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: totalPendingAmount > 0 ? AppColors.warning : AppColors.success,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (totalPendingAmount > 0) ...[
                          16.h.height,
                          Text(
                            '${pending.length} expense${pending.length > 1 ? 's' : ''} awaiting approval',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                          ),
                        ] else ...[
                          14.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                              8.w.width,
                              Text(
                                'All expenses approved!',
                                style: TextStyle(color: AppColors.success, fontSize: 13.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  24.h.height,

                  Text(
                    'All Expense Requests',
                    style: context.h3.copyWith(fontWeight: FontWeight.w800),
                  ),
                  14.h.height,

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.expenses.length,
                    itemBuilder: (context, i) {
                      final expense = state.expenses[i];
                      final isPending = expense.status == ExpenseStatus.pending;
                      final categoryColor = _categoryColor(expense.category);
                      final statusLabel = expense.status == ExpenseStatus.approved ? 'Approved' : 'Pending';

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(_categoryIcon(expense.category), color: categoryColor, size: 20.sp),
                                ),
                                12.w.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      4.h.height,
                                      Text(
                                        expense.description,
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            12.h.height,
                            Row(
                              children: [
                                _infoChip(Icons.person_outline, expense.submittedBy),
                                8.w.width,
                                _infoChip(Icons.calendar_today_outlined, _formatDate(expense.date)),
                              ],
                            ),
                            12.h.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${expense.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? AppColors.warning.withOpacity(0.08)
                                            : AppColors.success.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: isPending ? AppColors.warning : AppColors.success,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isPending) ...[
                                      8.w.width,
                                      SizedBox(
                                        height: 30.h,
                                        child: ElevatedButton(
                                          onPressed: () => _confirmApprove(context, expense),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                          ),
                                          child: Text(
                                            'Approve',
                                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      8.w.width,
                                      Text(
                                        'by ${expense.approvedBy ?? "-"}',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 9.sp),
                                      ),
                                    ],
                                  ],
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
      ),
    );
  }

  void _confirmApprove(BuildContext context, ExpenseItem expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Approve Expense'),
        content: Text('Approve expense "${expense.title}" for ₹${expense.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              final userId = context.read<AuthBloc>().state.user?.id ?? 'staff_1';
              context.read<SchoolBloc>().add(
                ApproveExpenseRequested(userId: userId, expenseId: expense.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final submitterCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    ExpenseCategory selectedCategory = ExpenseCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      16.h.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('New Expense', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      16.h.height,
                      Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Expense Title',
                          prefixIcon: Icon(Icons.receipt_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter title' : null,
                      ),
                      12.h.height,
                      TextFormField(
                        controller: descCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                      ),
                      12.h.height,
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter amount';
                          if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                      12.h.height,
                      DropdownButtonFormField<ExpenseCategory>(
                        value: selectedCategory,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: ExpenseCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.name[0].toUpperCase() + cat.name.substring(1),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedCategory = v);
                          }
                        },
                      ),
                      12.h.height,
                      TextFormField(
                        controller: submitterCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Submitted By',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      20.h.height,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              context.read<SchoolBloc>().add(
                                AddExpenseRequested(
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  amount: double.parse(amountCtrl.text.trim()),
                                  category: selectedCategory,
                                  submittedBy: submitterCtrl.text.trim(),
                                ),
                              );
                              Navigator.pop(sheetCtx);
                            }
                          },
                          child: Text('Add Expense', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.sp, color: AppColors.textMuted),
        4.w.width,
        Text(
          text,
          style: TextStyle(color: AppColors.textMuted, fontSize: 9.sp),
        ),
      ],
    );
  }

  Color _categoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.maintenance: return AppColors.primary;
      case ExpenseCategory.supplies: return AppColors.info;
      case ExpenseCategory.transport: return AppColors.warning;
      case ExpenseCategory.utilities: return AppColors.error;
      case ExpenseCategory.other: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.maintenance: return Icons.build_outlined;
      case ExpenseCategory.supplies: return Icons.shopping_bag_outlined;
      case ExpenseCategory.transport: return Icons.local_shipping_outlined;
      case ExpenseCategory.utilities: return Icons.bolt_outlined;
      case ExpenseCategory.other: return Icons.more_horiz_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
