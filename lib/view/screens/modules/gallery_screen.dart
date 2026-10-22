import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/smooth_skeleton.dart';

class GalleryScreen extends StatefulWidget {
  final List<DashboardGalleryAlbum>? initialAlbums;
  final bool isInline;

  const GalleryScreen({super.key, this.initialAlbums, this.isInline = false});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  List<DashboardGalleryAlbum> _albums = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialAlbums != null && widget.initialAlbums!.isNotEmpty) {
      _albums = List.from(widget.initialAlbums!);
      _isLoading = false;
    }
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    try {
      final data = await _repository.getGalleryAlbums();
      if (!mounted) return;
      setState(() {
        if (data.isNotEmpty) {
          _albums = data;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DashboardGalleryAlbum> get _filteredAlbums {
    if (_selectedCategory == 'All') return _albums;
    final q = _selectedCategory.toLowerCase();
    return _albums.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q);
    }).toList();
  }

  void _showAlbumDetails(DashboardGalleryAlbum album) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AlbumViewerSheet(album: album),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: widget.isInline
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Photo Gallery',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Live updates from school web dashboard',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Gallery',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchGallery();
            },
          ),
          10.w.horizontalSpace,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchGallery,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Category Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: SizedBox(
                  height: 38.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Sports'),
                      _buildFilterChip('Science'),
                      _buildFilterChip('Cultural'),
                      _buildFilterChip('Campus'),
                    ],
                  ),
                ),
              ),
            ),

            // Content Grid
            if (_isLoading && _albums.isEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSkeletonCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_filteredAlbums.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 56.sp,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        14.h.verticalSpace,
                        Text(
                          'No Albums Found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        6.h.verticalSpace,
                        Text(
                          'No photos found for the selected category. Try selecting another filter or pull down to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        16.h.verticalSpace,
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text('Show All Albums'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 40.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final album = _filteredAlbums[index];
                    return _buildAlbumCard(album);
                  }, childCount: _filteredAlbums.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedCategory = label;
          });
        },
      ),
    );
  }

  Widget _buildAlbumCard(DashboardGalleryAlbum album) {
    return GestureDetector(
      onTap: () => _showAlbumDetails(album),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Thumbnail
              Image.network(
                album.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 38.sp,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Photo count badge at top right
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 11.sp,
                        color: Colors.white,
                      ),
                      4.w.horizontalSpace,
                      Text(
                        '${album.photoCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Title & Description preview
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 10.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (album.description.isNotEmpty) ...[
                      3.h.verticalSpace,
                      Text(
                        album.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return SmoothShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
    );
  }
}

class _AlbumViewerSheet extends StatelessWidget {
  final DashboardGalleryAlbum album;

  const _AlbumViewerSheet({required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          12.h.verticalSpace,
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          14.h.verticalSpace,

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      4.h.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${album.photoCount} Photos in Album',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          14.h.verticalSpace,

          // Image preview with InteractiveViewer (pinch-to-zoom)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                height: 230.h,
                width: double.infinity,
                child: InteractiveViewer(
                  maxScale: 3.5,
                  child: Image.network(
                    album.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          16.h.verticalSpace,

          // Description
          if (album.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  album.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
