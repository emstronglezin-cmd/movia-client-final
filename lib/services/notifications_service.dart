import '../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationsService {
  final DioClient _client;
  NotificationsService(this._client);

  Future<List<AppNotification>> getAll() async {
    final data = await _client.get<List<dynamic>>('/notifications');
    return data.map((d) => AppNotification.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<AppNotification> markRead(String id) async {
    final data = await _client.patch<Map<String, dynamic>>('/notifications/$id/read', data: {});
    return AppNotification.fromJson(data);
  }

  Future<void> markAllRead() async {
    await _client.patch('/notifications/read-all', data: {});
  }
}
