// lib/models/voucher_model.dart

class VoucherModel {
  final int? voucherId;
  final String code;
  final String? description;
  final double? discountPercent;
  final double? discountAmount;
  final double minOrderAmount;
  final String expiryDate; // YYYY-MM-DD or ISO String

  const VoucherModel({
    this.voucherId,
    required this.code,
    this.description,
    this.discountPercent,
    this.discountAmount,
    this.minOrderAmount = 0.0,
    required this.expiryDate,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) => VoucherModel(
        voucherId: json['voucherId'] as int?,
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        discountPercent: (json['discountPercent'] as num?)?.toDouble(),
        discountAmount: (json['discountAmount'] as num?)?.toDouble(),
        minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
        expiryDate: json['expiryDate'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (voucherId != null) 'voucherId': voucherId,
        'code': code,
        'description': description,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'minOrderAmount': minOrderAmount,
        'expiryDate': expiryDate,
      };
}
