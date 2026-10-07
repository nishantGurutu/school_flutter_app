class HomeDashboardResponse {
  final String role;
  final bool isParentViewing;
  final DashboardUserProfile profile;
  final SectionsConfig sectionsConfig;
  final List<DashboardBanner> banners;
  final List<DashboardSubject> subjects;
  final List<DashboardEvent> upcomingEvents;
  final List<DashboardNotice> latestNotices;
  final List<DashboardGalleryAlbum> gallery;
  final List<DashboardChild> children;

  HomeDashboardResponse({
    required this.role,
    this.isParentViewing = false,
    required this.profile,
    required this.sectionsConfig,
    this.banners = const [],
    this.subjects = const [],
    this.upcomingEvents = const [],
    this.latestNotices = const [],
    this.gallery = const [],
    this.children = const [],
  });

  factory HomeDashboardResponse.fromJson(Map<String, dynamic> json) {
    return HomeDashboardResponse(
      role: json['role']?.toString() ?? 'student',
      isParentViewing: json['isParentViewing'] == true,
      profile: DashboardUserProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] ?? {}),
      ),
      sectionsConfig: SectionsConfig.fromJson(
        Map<String, dynamic>.from(json['sectionsConfig'] ?? {}),
      ),
      banners: (json['banners'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => DashboardBanner.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subjects: (json['subjects'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => DashboardSubject.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      upcomingEvents: (json['upcomingEvents'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => DashboardEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      latestNotices: (json['latestNotices'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => DashboardNotice.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      gallery: (json['gallery'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map(
            (e) => DashboardGalleryAlbum.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      children: (json['children'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => DashboardChild.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DashboardUserProfile {
  final String name;
  final String className;
  final String rollNo;
  final String admissionNo;
  final String avatarUrl;
  final String email;
  final String headerSubtitle;

  DashboardUserProfile({
    this.name = '',
    this.className = '',
    this.rollNo = '',
    this.admissionNo = '',
    this.avatarUrl = '',
    this.email = '',
    this.headerSubtitle = '',
  });

  factory DashboardUserProfile.fromJson(Map<String, dynamic> json) {
    return DashboardUserProfile(
      name: json['name']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      rollNo: json['rollNo']?.toString() ?? '',
      admissionNo: json['admissionNo']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      headerSubtitle: json['headerSubtitle']?.toString() ?? '',
    );
  }
}

class SectionsConfig {
  final bool showBanners;
  final bool showSubjects;
  final bool showUpcomingEvents;
  final bool showLatestNotices;
  final bool showGallery;
  final bool showChildren;

  SectionsConfig({
    this.showBanners = true,
    this.showSubjects = true,
    this.showUpcomingEvents = true,
    this.showLatestNotices = true,
    this.showGallery = true,
    this.showChildren = false,
  });

  factory SectionsConfig.fromJson(Map<String, dynamic> json) {
    return SectionsConfig(
      showBanners: json['showBanners'] ?? true,
      showSubjects: json['showSubjects'] ?? true,
      showUpcomingEvents: json['showUpcomingEvents'] ?? true,
      showLatestNotices: json['showLatestNotices'] ?? true,
      showGallery: json['showGallery'] ?? true,
      showChildren: json['showChildren'] ?? false,
    );
  }
}

class DashboardBanner {
  final dynamic id;
  final String title;
  final String subtitle;
  final String badge;
  final String buttonText;
  final String websiteUrl;
  final String imageUrl;
  final String bgColorHex;

  DashboardBanner({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.badge = '',
    this.buttonText = 'Learn More',
    this.websiteUrl = '',
    this.imageUrl = '',
    this.bgColorHex = '#EAB308',
  });

  factory DashboardBanner.fromJson(Map<String, dynamic> json) {
    return DashboardBanner(
      id: json['id'],
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? 'Learn More',
      websiteUrl: json['websiteUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      bgColorHex: json['bgColorHex']?.toString() ?? '#EAB308',
    );
  }
}

class DashboardSubject {
  final dynamic id;
  final String name;
  final String code;
  final String type;
  final String colorHex;
  final String secondaryColorHex;
  final String icon;

  DashboardSubject({
    required this.id,
    required this.name,
    this.code = '',
    this.type = 'Theory',
    this.colorHex = '#4F46E5',
    this.secondaryColorHex = '#818CF8',
    this.icon = 'book',
  });

  factory DashboardSubject.fromJson(Map<String, dynamic> json) {
    return DashboardSubject(
      id: json['id'],
      name: json['name']?.toString() ?? 'Subject',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Theory',
      colorHex: json['colorHex']?.toString() ?? '#4F46E5',
      secondaryColorHex: json['secondaryColorHex']?.toString() ?? '#818CF8',
      icon: json['icon']?.toString() ?? 'book',
    );
  }
}

class DashboardEvent {
  final String id;
  final String title;
  final String date;
  final String icon;
  final String color;

  DashboardEvent({
    required this.id,
    required this.title,
    required this.date,
    this.icon = 'people',
    this.color = '#4F46E5',
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'people',
      color: json['color']?.toString() ?? '#4F46E5',
    );
  }
}

class DashboardNotice {
  final String id;
  final String title;
  final String description;
  final String? attachmentName;
  final String? downloadUrl;
  final String date;

  DashboardNotice({
    required this.id,
    required this.title,
    required this.description,
    this.attachmentName,
    this.downloadUrl,
    required this.date,
  });

  factory DashboardNotice.fromJson(Map<String, dynamic> json) {
    return DashboardNotice(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      attachmentName: json['attachmentName']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
      date: json['date']?.toString() ?? '',
    );
  }
}

class DashboardGalleryAlbum {
  final dynamic id;
  final String title;
  final int photoCount;
  final String coverImage;

  DashboardGalleryAlbum({
    required this.id,
    required this.title,
    this.photoCount = 0,
    required this.coverImage,
  });

  factory DashboardGalleryAlbum.fromJson(Map<String, dynamic> json) {
    return DashboardGalleryAlbum(
      id: json['id'],
      title: json['title']?.toString() ?? '',
      photoCount: int.tryParse(json['photoCount']?.toString() ?? '0') ?? 0,
      coverImage: json['coverImage']?.toString() ?? '',
    );
  }
}

class DashboardChild {
  final String id;
  final String name;
  final String className;
  final String rollNo;
  final String admissionNo;
  final String avatarUrl;

  DashboardChild({
    required this.id,
    required this.name,
    required this.className,
    this.rollNo = '',
    required this.admissionNo,
    this.avatarUrl = '',
  });

  factory DashboardChild.fromJson(Map<String, dynamic> json) {
    return DashboardChild(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      rollNo: json['rollNo']?.toString() ?? '',
      admissionNo: json['admissionNo']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}
