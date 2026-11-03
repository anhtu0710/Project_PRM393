// lib/models/user_model.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String roleId;
  final String? hotelId;
  final String? hotelName;
  final String token;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.roleId,
    this.hotelId,
    this.hotelName,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    final hotel = json['hotel'] as Map<String, dynamic>?;
    return UserModel(
      userId:   json['userId']   ?? '',
      fullName: json['fullName'] ?? '',
      email:    json['email']    ?? '',
      role:     json['role']     ?? '',
      roleId:   json['roleId']   ?? '',
      hotelId:  hotel?['hotelId'] as String?,
      hotelName: hotel?['name'] as String?,
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId':   userId,
    'fullName': fullName,
    'email':    email,
    'role':     role,
    'roleId':   roleId,
    if (hotelId != null) 'hotelId': hotelId,
    if (hotelName != null) 'hotelName': hotelName,
    'token':    token,
  };

  UserModel copyWith({
    String? userId, String? fullName, String? email,
    String? role, String? roleId, String? hotelId, String? hotelName, String? token,
  }) {
    return UserModel(
      userId:   userId   ?? this.userId,
      fullName: fullName ?? this.fullName,
      email:    email    ?? this.email,
      role:     role     ?? this.role,
      roleId:   roleId   ?? this.roleId,
      hotelId:  hotelId  ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      token:    token    ?? this.token,
    );
  }
}
