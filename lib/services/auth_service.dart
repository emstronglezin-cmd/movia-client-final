import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/auth_user.dart';

class AuthService {
  final DioClient _client;
  AuthService([DioClient? client]) : _client = client ?? dioClient;

  // POST /auth/send-otp  { phone? | email?, cnib? }
  Future<Map<String, dynamic>> initiateAuth({
    required String phone,
    String? cnib,
    bool isRegistration = false,
  }) async {
    return await _client.post<Map<String, dynamic>>(
      '/auth/send-otp',
      data: {
        'phone': phone,
        if (cnib != null && cnib.isNotEmpty) 'cnib': cnib,
      },
    );
  }

  // POST /auth/verify-otp  { phone?, code }  (le backend attend "code" pas "otp")
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    return await _client.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {
        'phone': phone,
        'code': code,
      },
    );
  }

  // GET /auth/profile  (JWT requis)
  Future<AuthUser> getMe() async {
    final data = await _client.get<Map<String, dynamic>>('/auth/profile');
    return AuthUser.fromJson(data);
  }

  // PATCH /auth/profile  (JWT requis)
  Future<AuthUser> updateProfile(Map<String, dynamic> updates) async {
    final data = await _client.patch<Map<String, dynamic>>('/auth/profile', data: updates);
    return AuthUser.fromJson(data);
  }

  // POST /auth/avatar  (multipart, JWT requis)
  Future<AuthUser> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    final data = await _client.postMultipart<Map<String, dynamic>>('/auth/avatar', formData);
    return AuthUser.fromJson(data);
  }
}
