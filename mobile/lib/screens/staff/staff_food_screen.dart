// lib/screens/staff/staff_food_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/food_menu_model.dart';
import '../../providers/food_provider.dart';
import '../../widgets/app_image.dart';

class StaffFoodScreen extends ConsumerStatefulWidget {
  const StaffFoodScreen({super.key});

  @override
  ConsumerState<StaffFoodScreen> createState() => _StaffFoodScreenState();
}

class _StaffFoodScreenState extends ConsumerState<StaffFoodScreen> {
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodMenuListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thực đơn F&B'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(foodMenuListProvider.notifier).loadFoodMenu(),
          ),
        ],
      ),
      body: foodState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : foodState.items.isEmpty
              ? const Center(child: Text('Chưa có món ăn hoặc đồ uống nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: foodState.items.length,
                  itemBuilder: (context, index) {
                    final item = foodState.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: item.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Danh mục: ${item.category}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.price.toInt()} VNĐ',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showFoodDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(item.foodId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFoodDialog(null),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showFoodDialog(FoodMenuModel? item) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item != null ? item.price.toInt().toString() : '');
    final imageController = TextEditingController(text: item?.imageUrl ?? '');
    final descController = TextEditingController(text: item?.description ?? '');

    final List<String> presetCategories = ['Nước uống', 'Đồ ăn Âu', 'Set Combo', 'Mini Bar'];
    String currentCat = item?.category ?? '';
    bool isCustom = currentCat.isNotEmpty && !presetCategories.contains(currentCat);
    String selectedCategory = isCustom ? 'Khác...' : (presetCategories.contains(currentCat) ? currentCat : presetCategories.first);
    final customCategoryController = TextEditingController(text: isCustom ? currentCat : '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Sửa món ăn / đồ uống' : 'Thêm món mới'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Tên món'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'VD: Nước ép cam tươi, Mỳ Ý...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Danh mục'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      ...presetCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                      const DropdownMenuItem(value: 'Khác...', child: Text('Khác (Tự nhập)...')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                  if (selectedCategory == 'Khác...') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên danh mục khác...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildFieldLabel('Giá tiền (VNĐ)'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'VD: 49000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('URL Hình ảnh'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      hintText: 'VD: https://...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Mô tả'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập mô tả món ăn...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                final finalCategory = selectedCategory == 'Khác...'
                    ? customCategoryController.text.trim()
                    : selectedCategory;
                final price = double.tryParse(priceController.text.trim()) ?? 0;

                if (name.isEmpty || finalCategory.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ tên món, danh mục và giá tiền hợp lệ')),
                  );
                  return;
                }

                final newItem = FoodMenuModel(
                  foodId: isEdit ? item.foodId : 0,
                  name: name,
                  category: finalCategory,
                  price: price,
                  imageUrl: imageController.text.trim().isNotEmpty ? imageController.text.trim() : null,
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                  isAvailable: true,
                );

                final notifier = ref.read(foodMenuListProvider.notifier);
                final success = isEdit
                    ? await notifier.updateItem(item.foodId, newItem)
                    : await notifier.createItem(newItem);

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Thành công' : 'Thất bại')),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo mới', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa món này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref.read(foodMenuListProvider.notifier).deleteItem(id);
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Đã xóa món' : 'Xóa thất bại')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
