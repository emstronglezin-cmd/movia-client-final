import '../core/network/dio_client.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  final DioClient _client;
  LoyaltyService([DioClient? client]) : _client = client ?? dioClient;

  Future<LoyaltyAccount> getMyLoyalty() async {
    final data = await _client.get<Map<String, dynamic>>('/loyalty/me');
    return LoyaltyAccount.fromJson(data);
  }

  Future<Map<String, dynamic>> redeemPoints(int points, {String? description}) async {
    return await _client.post<Map<String, dynamic>>(
      '/loyalty/redeem',
      data: {'points': points, if (description != null) 'description': description},
    );
  }

  Future<Map<String, dynamic>> getInfo() async {
    return await _client.get<Map<String, dynamic>>('/loyalty/info');
  }
}
