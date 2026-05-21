import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final String? sessionExpiredMessage;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.token,
    this.sessionExpiredMessage,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    String? sessionExpiredMessage,
    String? error,
    bool clearSession = false,
    bool clearError = false,
    bool clearExpired = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearSession ? null : user ?? this.user,
        token: clearSession ? null : token ?? this.token,
        sessionExpiredMessage:
            clearExpired ? null : sessionExpiredMessage ?? this.sessionExpiredMessage,
        error: clearError ? null : error ?? this.error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final AuthService _service;

  AuthNotifier(this._storage, this._service) : super(const AuthState()) {
    _init();
    dioClient.onSessionExpired = (msg) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        sessionExpiredMessage: msg,
      );
    };
  }

  Future<void> _init() async {
    try {
      final token = await _storage.read(key: AppConfig.tokenKey);
      final userRaw = await _storage.read(key: AppConfig.userKey);
      if (token != null && userRaw != null) {
        final user = AuthUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
        state = state.copyWith(status: AuthStatus.authenticated, token: token, user: user);
        _refreshUser();
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<Map<String, dynamic>> initiateAuth({
    required String phone,
    String? cnib,
    bool isRegistration = false,
  }) async {
    return await _service.initiateAuth(phone: phone, cnib: cnib, isRegistration: isRegistration);
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    final result = await _service.verifyOtp(phone: phone, code: code);
    final token = result['token']?.toString() ?? '';
    final user = AuthUser.fromJson(result['user'] as Map<String, dynamic>);

    await _storage.write(key: AppConfig.tokenKey, value: token);
    await _storage.write(key: AppConfig.userKey, value: user.toJsonString());

    state = state.copyWith(
      status: AuthStatus.authenticated,
      token: token,
      user: user,
      clearError: true,
      clearExpired: true,
    );
  }

  Future<void> _refreshUser() async {
    try {
      final user = await _service.getMe();
      await _storage.write(key: AppConfig.userKey, value: user.toJsonString());
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> refreshUser() => _refreshUser();

  /// Met à jour le profil (nom, email, etc.)
  Future<void> updateProfile({String? name, String? email}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
    if (updates.isEmpty) return;
    final user = await _service.updateProfile(updates);
    await _storage.write(key: AppConfig.userKey, value: user.toJsonString());
    state = state.copyWith(user: user);
  }

  /// Upload avatar depuis un chemin de fichier local
  Future<void> uploadAvatar(String filePath) async {
    final user = await _service.uploadAvatar(filePath);
    await _storage.write(key: AppConfig.userKey, value: user.toJsonString());
    state = state.copyWith(user: user);
  }

  Future<void> signOut() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearSessionExpired() {
    state = state.copyWith(clearExpired: true);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final _storageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final _authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(dioClient),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(_storageProvider),
    ref.read(_authServiceProvider),
  ),
);
