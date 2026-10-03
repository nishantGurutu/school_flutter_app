import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/routes/routes_name.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/context_extensions.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/school/school_bloc.dart';
import '../../logic/school/school_event.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            // Route to Dashboard shell
            Navigator.pushReplacementNamed(context, RoutesName.dashboard);
          } else if (state.status == AuthStatus.error &&
              state.errorMessage != null) {
            context.showAppSnackBar(state.errorMessage!, isError: true);
          }
        },
        builder: (context, state) {
          // If in any of the verification stages, overlay a beautiful animated milestone screen
          final isVerifying =
              state.status == AuthStatus.verifyingCredentials ||
              state.status == AuthStatus.loadingPermissions ||
              state.status == AuthStatus.loadingModules;

          return Stack(
            children: [
              // Background ambient glows
              Positioned(
                top: -120.h,
                right: -100.w,
                child: Container(
                  width: 350.w,
                  height: 350.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -80.h,
                left: -80.w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.06),
                  ),
                ),
              ),

              // Scrollable form layout
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: AppColors.primary,
                                size: 38.sp,
                              ),
                              12.w.width,
                              Text(
                                'SchoolDesk',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          4.h.height,
                          Center(
                            child: Text(
                              'Smart School Management',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          36.h.height,

                          // Greeting text
                          Text(
                            'Welcome Back!',
                            style: context.h1,
                            textAlign: TextAlign.center,
                          ),
                          6.h.height,
                          Text(
                            'Sign in to access your dashboard.',
                            style: context.caption,
                            textAlign: TextAlign.center,
                          ),
                          24.h.height,

                          // Form Glass Panel
                          GlassCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 24.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email field
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email / Login ID',
                                  hint: 'Enter your email or login ID',
                                  prefixIcon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter email or login ID';
                                    }
                                    return null;
                                  },
                                ),
                                16.h.height,

                                // Password field
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter password';
                                    }
                                    return null;
                                  },
                                ),
                                12.h.height,

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      context.showAppSnackBar(
                                        'Please contact your school administrator to reset credentials.',
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                20.h.height,

                                // Error feedback banner
                                if (state.status == AuthStatus.error &&
                                    state.errorMessage != null &&
                                    state.errorMessage!.isNotEmpty) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 18.sp,
                                        ),
                                        8.w.width,
                                        Expanded(
                                          child: Text(
                                            state.errorMessage!,
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  16.h.height,
                                ],

                                // Login Button
                                ElevatedButton(
                                  onPressed:
                                      state.status == AuthStatus.authenticating
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            context.read<AuthBloc>().add(
                                              LoginRequested(
                                                email: _emailController.text.trim(),
                                                password:
                                                    _passwordController.text,
                                              ),
                                            );
                                          }
                                        },
                                  child:
                                      state.status == AuthStatus.authenticating
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                        )
                                      : const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                          36.h.height,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.sp,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.showAppSnackBar(
                                  'Please contact school administration for registration credentials.',
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Full Screen Blur Verification Overlay
              if (isVerifying) _VerificationOverlay(status: state.status),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationOverlay extends StatelessWidget {
  final AuthStatus status;

  const _VerificationOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    // Determine milestone indicators
    final step1Active =
        status == AuthStatus.verifyingCredentials ||
        status == AuthStatus.loadingPermissions ||
        status == AuthStatus.loadingModules;
    final step2Active =
        status == AuthStatus.loadingPermissions ||
        status == AuthStatus.loadingModules;
    final step3Active = status == AuthStatus.loadingModules;

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: GlassCard(
        blur: 16.0,
        color: Colors.transparent,
        borderColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              28.h.height,
              Text(
                'Verification Pipeline',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              4.h.height,
              Text(
                'Securing credentials and configuring workspaces',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
              ),
              36.h.height,

              // Checkpoint 1
              _MilestoneRow(
                label: 'Verifying user credentials',
                isActive: step1Active,
                isCompleted: step2Active,
              ),
              16.h.height,

              // Checkpoint 2
              _MilestoneRow(
                label: 'Retrieving role & permissions',
                isActive: step2Active,
                isCompleted: step3Active,
              ),
              16.h.height,

              // Checkpoint 3
              _MilestoneRow(
                label: 'Loading authorized app modules',
                isActive: step3Active,
                isCompleted:
                    false, // is completed when it switches to authenticated dashboard
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _MilestoneRow({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    double opacity = 0.4;

    if (isCompleted) {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      opacity = 1.0;
    } else if (isActive) {
      icon = Icons.circle_outlined;
      iconColor = AppColors.primary;
      opacity = 1.0;
    } else {
      icon = Icons.circle_outlined;
      iconColor = AppColors.textMuted;
    }

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20.sp),
            16.w.width,
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isActive || isCompleted
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isActive || isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
