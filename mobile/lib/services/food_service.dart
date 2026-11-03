// lib/services/food_service.dart
// Thực đơn đồ ăn thức uống — đọc bảng FoodMenu trong SQLite

import '../database/database_helper.dart';
import '../models/food_menu_model.dart';

class FoodService {
  Future<List<FoodMenuModel>> getFoodMenu({String? category}) async {
    final db = await DatabaseHelper.database;
    final rows = (category != null && category.isNotEmpty)
        ? await db.query('FoodMenu',
            where: 'Category = ? AND IsAvailable = 1', whereArgs: [category])
        : await db.query('FoodMenu', where: 'IsAvailable = 1');

    return rows
        .map((r) => FoodMenuModel(
              foodId: r['FoodId'] as int,
              name: r['Name'] as String? ?? '',
              category: r['Category'] as String? ?? '',
              price: (r['Price'] as num?)?.toDouble() ?? 0,
              imageUrl: r['ImageUrl'] as String?,
              description: r['Description'] as String?,
              isAvailable: r['IsAvailable'] == 1,
            ))
        .toList();
  }
}
