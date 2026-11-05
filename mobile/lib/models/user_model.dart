// lib/models/user_model.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String roleId;
  final String? hotelId;
  final String? hotelName;
  final String token;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.roleId,
    this.hotelId,
    this.hotelName,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    String? hId;
    String? hName;
    final hotelObj = json['hotel'];
    if (hotelObj is Map<String, dynamic>) {
      hId = hotelObj['hotelId'] as String? ?? hotelObj['id'] as String?;
      hName = hotelObj['name'] as String?;
    } else if (hotelObj is String) {
      hId = hotelObj;
    }
    if (hId == null) {
      hId = json['hotelId'] as String?;
    }
    if (hName == null) {
      hName = json['hotelName'] as String?;
    }

    return UserModel(
      userId:   json['userId']   ?? '',
      fullName: json['fullName'] ?? '',
      email:    json['email']    ?? '',
      phone:    json['phone'] as String?,
      role:     json['role']     ?? '',
      roleId:   json['roleId']   ?? '',
      hotelId:  hId,
      hotelName: hName,
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId':   userId,
    'fullName': fullName,
    'email':    email,
    if (phone != null) 'phone': phone,
    'role':     role,
    'roleId':   roleId,
    if (hotelId != null) 'hotelId': hotelId,
    if (hotelName != null) 'hotelName': hotelName,
    'token':    token,
  };

  UserModel copyWith({
    String? userId, String? fullName, String? email, String? phone,
    String? role, String? roleId, String? hotelId, String? hotelName, String? token,
  }) {
    return UserModel(
      userId:   userId   ?? this.userId,
      fullName: fullName ?? this.fullName,
      email:    email    ?? this.email,
      phone:    phone    ?? this.phone,
      role:     role     ?? this.role,
      roleId:   roleId   ?? this.roleId,
      hotelId:  hotelId  ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      token:    token    ?? this.token,
    );
  }
}
