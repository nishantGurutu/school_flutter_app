class UserModel {
  final String name;
  final int age;
  final String profession;
  final String imageUrl;
  final List<String> interests;
  final String about;
  final String role;

  UserModel({
    required this.name,
    required this.age,
    required this.profession,
    required this.imageUrl,
    this.interests = const [],
    this.about = "",
    this.role = "",
  });
}
