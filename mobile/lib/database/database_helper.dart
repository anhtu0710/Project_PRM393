// lib/database/database_helper.dart
// Database SQLite nằm ngay trong điện thoại (không cần server, không cần mạng).
// Bảng + dữ liệu mẫu viết trong file mobile/database.sql.
// Lần đầu mở app (database chưa có) sẽ chạy file đó 1 lần.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  /// Lấy database. Lần đầu mở app sẽ tự tạo bảng + dữ liệu mẫu.
  static Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  /// Tăng số này mỗi khi sửa database.sql: máy đã cài app cũ sẽ xoá bảng cũ và tạo lại.
  static const int _dbVersion = 2;

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'genz_cinema_hotel.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _runSqlFile(db, 'database.sql');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _dropAllTables(db);
        await _runSqlFile(db, 'database.sql');
      },
    );
  }

  /// Xoá hết các bảng (dữ liệu cũ mất hết, dùng khi đổi phiên bản database)
  static Future<void> _dropAllTables(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
    for (final t in tables) {
      await db.execute('DROP TABLE IF EXISTS [${t['name']}]');
    }
  }

  /// Đọc file .sql rồi chạy lần lượt từng câu lệnh (các câu cách nhau bằng dấu ;)
  static Future<void> _runSqlFile(Database db, String assetPath) async {
    final sql = await rootBundle.loadString(assetPath);
    for (final part in sql.split(';')) {
      // Bỏ các dòng chú thích bắt đầu bằng "--"
      final lines = part.split('\n').where((line) => !line.trim().startsWith('--'));
      final statement = lines.join('\n').trim();
      if (statement.isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  /// Mã hoá mật khẩu trước khi lưu (không lưu mật khẩu thật)
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
