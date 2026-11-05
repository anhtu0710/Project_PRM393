// lib/models/food_menu_model.dart

class FoodMenuModel {
  final int foodId;
  final String name;
  final String category;
  final double price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;

  const FoodMenuModel({
    required this.foodId,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  factory FoodMenuModel.fromJson(Map<String, dynamic> json) => FoodMenuModel(
        foodId: (json['foodId'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (foodId > 0) 'foodId': foodId,
        'name': name,
        'category': category,
        'price': price,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (description != null) 'description': description,
        'isAvailable': isAvailable,
      };
}
