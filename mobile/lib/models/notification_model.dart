// lib/models/notification_model.dart

class NotificationModel {
  final int? notificationId;
  final String userId;
  final int? bookingId;
  final String title;
  final String message;
  final bool read;
  final String? createdAt;

  NotificationModel({
    this.notificationId,
    required this.userId,
    this.bookingId,
    required this.title,
    required this.message,
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as int?,
      userId: json['userId']?.toString() ?? '',
      bookingId: json['bookingId'] as int?,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (notificationId != null) 'notificationId': notificationId,
      'userId': userId,
      if (bookingId != null) 'bookingId': bookingId,
      'title': title,
      'message': message,
      'read': read,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
