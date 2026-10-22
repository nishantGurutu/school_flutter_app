import 'package:printing/printing.dart';
import '../../data/network/network_api_services.dart';
import '../../utils/app_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/certificate_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/api_school_repository.dart';
import 'smooth_skeleton.dart';

class CertificatesDialog extends StatefulWidget {
  final UserModel? user;

  const CertificatesDialog({super.key, this.user});

  static void show(BuildContext context, {UserModel? user}) {
    showDialog(
      context: context,
      builder: (ctx) => CertificatesDialog(user: user),
    );
  }

  @override
  State<CertificatesDialog> createState() => _CertificatesDialogState();
}

class _CertificatesDialogState extends State<CertificatesDialog> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() => _isLoading = true);
    try {
      final certs = await _repository.getCertificates(
        admissionNo: widget.user?.admissionNo,
      );
      if (!mounted) return;
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openCertificatePreview(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (ctx) => _CertificateViewerDialog(certificate: cert),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      titlePadding: EdgeInsets.fromLTRB(20.w, 18.h, 16.w, 10.h),
      contentPadding: EdgeInsets.symmetric(horizontal: 18.w),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          12.w.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Certificates',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Live certificates from School Dashboard',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: 'Refresh',
            onPressed: _fetchCertificates,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SmoothShimmer(
                      child: SkeletonBox(width: double.infinity, height: 70),
                    ),
                    10.h.verticalSpace,
                    const SmoothShimmer(
                      child: SkeletonBox(width: double.infinity, height: 70),
                    ),
                  ],
                ),
              )
            : _certificates.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 48.sp,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    12.h.verticalSpace,
                    Text(
                      'No Certificates Found',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    6.h.verticalSpace,
                    Text(
                      'No certificates have been issued yet. Once school administration issues a certificate from the dashboard, it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 380.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _certificates.length,
                  separatorBuilder: (_, _) => 10.h.verticalSpace,
                  itemBuilder: (context, i) {
                    final cert = _certificates[i];
                    return _buildCertificateTile(cert);
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateTile(CertificateModel cert) {
    return InkWell(
      onTap: () => _openCertificatePreview(cert),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Gold Certificate Badge
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            12.w.horizontalSpace,

            // Certificate Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.certificateName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  3.h.verticalSpace,
                  Text(
                    'Awarded to: ${cert.name}${cert.className != null && cert.className!.isNotEmpty ? " • ${cert.className}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  2.h.verticalSpace,
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 10.sp,
                        color: AppColors.textMuted,
                      ),
                      4.w.horizontalSpace,
                      Text(
                        cert.date.isNotEmpty
                            ? 'Issued: ${cert.date}'
                            : 'Official Certificate',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View / Eye Icon button
            IconButton(
              icon: const Icon(
                Icons.remove_red_eye_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              tooltip: 'View Certificate',
              onPressed: () => _openCertificatePreview(cert),
            ),

            // Download Icon Button
            IconButton(
              icon: const Icon(
                Icons.download_rounded,
                color: Color(0xFF0EA5E9),
                size: 22,
              ),
              tooltip: 'Download Certificate',
              onPressed: () => _openCertificatePreview(cert),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uses the same authenticated PDF as the dashboard for preview, save and print.
class _CertificateViewerDialog extends StatelessWidget {
  final CertificateModel certificate;
  const _CertificateViewerDialog({required this.certificate});

  @override
  Widget build(BuildContext context) {
    final pdf = NetworkApiService().getPdfBytes(
      AppUrl.certificatePdf(certificate.id),
    );
    return Dialog(
      child: SizedBox(
        width: 900,
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            ListTile(
              title: Text(certificate.certificateName),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: pdf,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load certificate. Please close and try again.',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PdfPreview(
                    build: (_) async => snapshot.data!,
                    pdfFileName:
                        'Certificate_${certificate.name.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.pdf',
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    allowPrinting: true,
                    allowSharing: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
