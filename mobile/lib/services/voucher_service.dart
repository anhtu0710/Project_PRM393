// lib/services/voucher_service.dart
// Voucher (màn Staff) — đọc ghi bảng Voucher trong SQLite

import '../database/database_helper.dart';
import '../models/voucher_model.dart';

class VoucherService {
  Future<List<VoucherModel>> getAllVouchers() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('Voucher');
    return rows
        .map((r) => VoucherModel(
              voucherId: r['VoucherId'] as int,
              code: r['Code'] as String,
              description: r['Description'] as String?,
              discountPercent: (r['DiscountPercent'] as num?)?.toDouble(),
              discountAmount: (r['DiscountAmount'] as num?)?.toDouble(),
              minOrderAmount: (r['MinOrderAmount'] as num?)?.toDouble() ?? 0,
              expiryDate: r['ExpiryDate'] as String? ?? '',
            ))
        .toList();
  }

  Future<void> createVoucher(VoucherModel voucher) async {
    final code = voucher.code.trim().toUpperCase();
    if (code.isEmpty) throw 'Mã voucher không được để trống';

    final db = await DatabaseHelper.database;
    final existed = await db.query('Voucher', where: 'Code = ?', whereArgs: [code]);
    if (existed.isNotEmpty) throw "Mã voucher '$code' đã tồn tại";

    await db.insert('Voucher', {
      'Code': code,
      'Description': voucher.description,
      'DiscountPercent': voucher.discountPercent,
      'DiscountAmount': voucher.discountAmount,
      'MinOrderAmount': voucher.minOrderAmount,
      'ExpiryDate': voucher.expiryDate,
    });
  }

  Future<void> updateVoucher(int id, VoucherModel voucher) async {
    final code = voucher.code.trim().toUpperCase();
    final db = await DatabaseHelper.database;

    // Đổi sang mã khác mà mã đó đã có rồi thì báo lỗi
    final sameCode = await db.query('Voucher',
        where: 'Code = ? AND VoucherId <> ?', whereArgs: [code, id]);
    if (sameCode.isNotEmpty) throw "Mã voucher '$code' đã tồn tại";

    await db.update(
      'Voucher',
      {
        'Code': code,
        'Description': voucher.description,
        'DiscountPercent': voucher.discountPercent,
        'DiscountAmount': voucher.discountAmount,
        'MinOrderAmount': voucher.minOrderAmount,
        'ExpiryDate': voucher.expiryDate,
      },
      where: 'VoucherId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVoucher(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('Voucher', where: 'VoucherId = ?', whereArgs: [id]);
  }
}
