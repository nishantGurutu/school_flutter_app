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
  String _selectedRole = 'STUDENT';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pre-fill helper for convenience
  void _quickFill(String email, String role, BuildContext context) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password';
      _selectedRole = role;
    });
    context.showAppSnackBar(
      'Role set to $role • Credentials: $email / password',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            // Trigger loading school data for the authenticated user
            context.read<SchoolBloc>().add(LoadSchoolData(state.user!.id));
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
                                // User Role Selector Dropdown
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRole,
                                      dropdownColor: AppColors.background,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      items: const [
                                        DropdownMenuItem(value: 'STUDENT', child: Text('Login as STUDENT')),
                                        DropdownMenuItem(value: 'PARENT', child: Text('Login as PARENT')),
                                        DropdownMenuItem(value: 'TEACHER', child: Text('Login as TEACHER')),
                                        DropdownMenuItem(value: 'STAFF', child: Text('Login as STAFF')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedRole = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                16.h.height,

                                // Email field
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email Address / Mobile',
                                  hint: 'student@schooldesk.com or student',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter email/username';
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
                                        'Forgot password simulator: enter password as "password"',
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
                                                email: _emailController.text,
                                                password:
                                                    _passwordController.text,
                                                loginUser: _selectedRole,
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
                                      : Text('Login as $_selectedRole'),
                                ),
                              ],
                            ),
                          ),
                          24.h.height,

                          // Demo quick logins
                          Text(
                            'QUICK LOGIN ROLES',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          12.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _QuickLoginChip(
                                label: 'Student',
                                icon: Icons.person_outline_rounded,
                                color: AppColors.primary,
                                onTap: () => _quickFill(
                                  'student@schooldesk.com',
                                  'STUDENT',
                                  context,
                                ),
                              ),
                              _QuickLoginChip(
                                label: 'Parent',
                                icon: Icons.family_restroom_rounded,
                                color: AppColors.success,
                                onTap: () => _quickFill(
                                  'parent@schooldesk.com',
                                  'PARENT',
                                  context,
                                ),
                              ),
                            ],
                          ),
                          10.h.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _QuickLoginChip(
                                label: 'Teacher',
                                icon: Icons.assignment_ind_outlined,
                                color: AppColors.info,
                                onTap: () => _quickFill(
                                  'teacher@schooldesk.com',
                                  'TEACHER',
                                  context,
                                ),
                              ),
                              _QuickLoginChip(
                                label: 'Staff',
                                icon: Icons.admin_panel_settings_outlined,
                                color: AppColors.warning,
                                onTap: () => _quickFill(
                                  'staff@schooldesk.com',
                                  'STAFF',
                                  context,
                                ),
                              ),
                            ],
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
                                  'Signup simulator: use Quick Logins to explore',
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

class _QuickLoginChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLoginChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 150.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: color),
              8.w.width,
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
