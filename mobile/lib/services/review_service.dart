import 'package:dio/dio.dart';

import '../models/review_eligible_booking_model.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ReviewEligibleBookingModel>> getEligibleBookings() async {
    final response = await _dio.get('/reviews/eligible');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) =>
            ReviewEligibleBookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/reviews', data: {
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment?.trim().isEmpty ?? true ? null : comment!.trim(),
    });
    return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
