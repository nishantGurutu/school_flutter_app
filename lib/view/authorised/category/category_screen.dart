import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_desk_app/config/color/app_color.dart';
import 'package:school_desk_app/model/category/category_model.dart';
import 'package:school_desk_app/services/category/category_service.dart';
import 'package:school_desk_app/utils/extensions/general_ectensions.dart';
import 'package:school_desk_app/utils/extensions/text_extension.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCategories();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _initItemAnimations(int count) {
    _itemControllers = List.generate(
      count,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 50)),
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
    }).toList();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _categoryService.loadCategories();

      setState(() {
        _categories = response.categories;
        _isLoading = false;
      });

      _initItemAnimations(_categories.length);
      _fadeController.forward();
      _scaleController.forward();

      for (int i = 0; i < _itemControllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        _itemControllers[i].forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onCategoryTap(Category category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${category.name}'),
        backgroundColor: AppColors.accentPurple,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'S',
              style: context.h2.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          10.w.width,
          Text(
            'Serving Delhi',
            style: context.h1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.menu,
              color: AppColors.textSecondary,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            16.h.height,
            _buildPromoBanner(),
            20.h.height,
            _buildCategoriesTitle(),
            16.h.height,
            _buildCategoriesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50.w,
            height: 50.w,
            child: CircularProgressIndicator(
              color: AppColors.accentPurple,
              strokeWidth: 3.w,
            ),
          ),
          16.h.height,
          Text(
            'Loading categories...',
            style: context.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 64.sp,
            ),
            16.h.height,
            Text(
              'Oops! Something went wrong',
              style: context.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            8.h.height,
            Text(
              _errorMessage ?? 'Failed to load categories',
              style: context.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            24.h.height,
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return InkWell(
      onTap: _loadCategories,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: AppColors.purpleGlowGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 20.sp),
            8.w.width,
            Text(
              'Retry',
              style: context.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          14.w.width,
          Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22.sp),
          10.w.width,
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: context.body.copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Search for '),
                  TextSpan(
                    text: 'Salons',
                    style: context.body.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.mic_none_rounded,
            color: AppColors.accentPurple,
            size: 22.sp,
          ),
          12.w.width,
          Container(width: 1, height: 24.h, color: AppColors.border),
          12.w.width,
          Icon(Icons.apps_rounded, color: AppColors.textSecondary, size: 22.sp),
          14.w.width,
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withOpacity(0.9),
            AppColors.accentPurple2.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '50%',
                  style: context.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                4.h.height,
                Text(
                  'Off on local services\nexplore & save daily',
                  style: context.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.local_offer_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 64.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTitle() {
    return Text(
      'Categories',
      style: context.h2.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _itemAnimations[index].value,
              child: Opacity(
                opacity: _itemAnimations[index].value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _CategoryCard(
            category: category,
            onTap: () => _onCategoryTap(category),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Column(
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  widget.category.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surface2,
                      child: Icon(
                        _getIconData(widget.category.icon),
                        color: AppColors.accentPurple,
                        size: 36.sp,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surface2,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentPurple,
                          strokeWidth: 2.w,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            8.h.height,
            Text(
              widget.category.name,
              textAlign: TextAlign.center,
              style: context.text(
                size: 11,
                weight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'location_on_outlined':
        return Icons.location_on_outlined;
      case 'directions_car_rounded':
        return Icons.directions_car_rounded;
      case 'local_hospital_outlined':
        return Icons.local_hospital_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'apartment_rounded':
        return Icons.apartment_rounded;
      case 'content_cut_rounded':
        return Icons.content_cut_rounded;
      case 'fitness_center_rounded':
        return Icons.fitness_center_rounded;
      case 'house_rounded':
        return Icons.house_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'event_rounded':
        return Icons.event_rounded;
      case 'flight_rounded':
        return Icons.flight_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
