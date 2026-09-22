import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:school_desk_app/model/category/category_model.dart';

class CategoryService {
  Future<CategoryResponse> loadCategories() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/category.json',
      );
      final data = json.decode(response);
      return CategoryResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
