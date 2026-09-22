class CategoryResponse {
  final List<Category> categories;

  CategoryResponse({
    required this.categories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    var categoriesJson = json['categories'] as List;
    List<Category> categoriesList = categoriesJson.map((i) => Category.fromJson(i)).toList();
    return CategoryResponse(
      categories: categoriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}

class Category {
  final String id;
  final String name;
  final String icon;
  final String image;
  final String description;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.description,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      image: json['image'] as String,
      description: json['description'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'image': image,
      'description': description,
      'is_active': isActive,
    };
  }
}
