// lib/database/database_helper.dart
// Database SQLite nằm ngay trong điện thoại (không cần server, không cần mạng).
// Các bảng giống hệt SQL Server (SQLQuery1.sql + sprint_foundation.sql), chỉ đổi kiểu:
//   NVARCHAR / VARCHAR -> TEXT,  DECIMAL -> REAL,  BIT -> INTEGER (0/1),
//   DATETIME -> TEXT (dạng "2026-11-05T19:00:00.000"),  IDENTITY -> AUTOINCREMENT

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static Database? _database;

  /// Lấy database. Lần đầu mở app sẽ tự tạo bảng + dữ liệu mẫu.
  static Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'genz_cinema_hotel.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await insertSeedData(db);
      },
    );
  }

  /// Mã hoá mật khẩu trước khi lưu (không lưu mật khẩu thật)
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE Role (
        RoleId   TEXT PRIMARY KEY,
        RoleName TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE TypeRoom (
        TypeRoomId   TEXT PRIMARY KEY,
        TypeRoom     TEXT NOT NULL,
        pricePerHour REAL
      )''');

    await db.execute('''
      CREATE TABLE TypeBooking (
        TypeBookingId TEXT PRIMARY KEY,
        TypeName      TEXT NOT NULL,
        BookingCode   TEXT NOT NULL,
        DurationHours INTEGER
      )''');

    await db.execute('''
      CREATE TABLE [User] (
        UserId    TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone     TEXT,
        email     TEXT,
        password  TEXT NOT NULL,
        RoleId    TEXT,
        IsLocked  INTEGER NOT NULL DEFAULT 0
      )''');

    await db.execute('''
      CREATE TABLE Hotel (
        HotelId   TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        address   TEXT,
        countRoom INTEGER DEFAULT 0,
        phone     TEXT,
        imageUrl  TEXT
      )''');

    await db.execute('''
      CREATE TABLE Room (
        RoomId     TEXT PRIMARY KEY,
        nameRoom   TEXT NOT NULL,
        TypeRoomId TEXT,
        Status     TEXT,
        HotelId    TEXT,
        imageUrl   TEXT
      )''');

    await db.execute('''
      CREATE TABLE PriceConfig (
        PriceConfigId INTEGER PRIMARY KEY AUTOINCREMENT,
        TypeRoomId    TEXT NOT NULL,
        TypeBookingId TEXT NOT NULL,
        Price         REAL NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE Booking (
        BookingId      INTEGER PRIMARY KEY AUTOINCREMENT,
        RoomId         TEXT NOT NULL,
        UserId         TEXT NOT NULL,
        TypeBookingId  TEXT NOT NULL,
        checkIn        TEXT NOT NULL,
        checkOut       TEXT,
        totalPrice     REAL,
        Status         TEXT,
        voucherCode    TEXT,
        discountAmount REAL DEFAULT 0,
        note           TEXT
      )''');

    await db.execute('''
      CREATE TABLE PasswordResetToken (
        token      TEXT PRIMARY KEY,
        expiryTime TEXT NOT NULL,
        isUsed     INTEGER NOT NULL DEFAULT 0,
        UserId     TEXT
      )''');

    await db.execute('''
      CREATE TABLE Voucher (
        VoucherId       INTEGER PRIMARY KEY AUTOINCREMENT,
        Code            TEXT NOT NULL UNIQUE,
        Description     TEXT,
        DiscountPercent REAL,
        DiscountAmount  REAL,
        MinOrderAmount  REAL NOT NULL DEFAULT 0,
        ExpiryDate      TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE Review (
        ReviewId  INTEGER PRIMARY KEY AUTOINCREMENT,
        BookingId INTEGER NOT NULL UNIQUE,
        RoomId    TEXT NOT NULL,
        UserId    TEXT NOT NULL,
        Rating    INTEGER NOT NULL,
        Comment   TEXT,
        CreatedAt TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE Notification (
        NotificationId INTEGER PRIMARY KEY AUTOINCREMENT,
        UserId    TEXT NOT NULL,
        BookingId INTEGER,
        Title     TEXT NOT NULL,
        Message   TEXT NOT NULL,
        IsRead    INTEGER NOT NULL DEFAULT 0,
        CreatedAt TEXT NOT NULL
      )''');
  }
}
