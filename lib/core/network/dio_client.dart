import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

typedef SessionExpiredCallback = void Function(String message);

/// Convertit toute exception technique en message lisible par l'utilisateur.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La connexion a pris trop de temps. Vérifiez votre connexion internet.';
      case DioExceptionType.connectionError:
        return 'Connexion impossible. Vérifiez votre connexion internet.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        // Essayer d'extraire le message du serveur
        String? serverMsg;
        if (data is Map<String, dynamic>) {
          final msg = data['message'];
          if (msg is List && msg.isNotEmpty) {
            serverMsg = msg.first.toString();
          } else if (msg is String) {
            serverMsg = msg;
          }
        }
        switch (statusCode) {
          case 400:
            return serverMsg ?? 'Données invalides. Vérifiez vos informations.';
          case 401:
            return 'Session expirée. Veuillez vous reconnecter.';
          case 403:
            return 'Accès refusé.';
          case 404:
            return serverMsg ?? 'Ressource introuvable.';
          case 409:
            return serverMsg ?? 'Conflit : cette action n\'est pas possible.';
          case 422:
            return serverMsg ?? 'Données invalides.';
          case 429:
            return 'Trop de tentatives. Attendez quelques instants.';
          case 500:
          case 502:
          case 503:
            return 'Serveur temporairement indisponible. Réessayez dans un moment.';
          default:
            return serverMsg ?? 'Une erreur est survenue (code $statusCode).';
        }
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      default:
        // Vérifier si c'est une erreur réseau sous-jacente
        if (error.error is SocketException) {
          return 'Connexion impossible. Vérifiez votre connexion internet.';
        }
        return 'Une erreur est survenue. Réessayez.';
    }
  }
  if (error is SocketException) {
    return 'Connexion impossible. Vérifiez votre connexion internet.';
  }
  // Pour toute autre exception, retourner un message générique
  final msg = error.toString();
  if (msg.contains('DioException') ||
      msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('connection error') ||
      msg.contains('Connection refused') ||
      msg.contains('errno =')) {
    return 'Connexion impossible. Vérifiez votre connexion internet.';
  }
  // Message d'exception propre (sans préfixe technique)
  return msg
      .replaceAll('Exception: ', '')
      .replaceAll('DioException: ', '')
      .replaceAll('[connection error]: ', '')
      .replaceAll('[bad response]: ', '');
}

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  SessionExpiredCallback? onSessionExpired;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConfig.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: AppConfig.tokenKey);
            await _storage.delete(key: AppConfig.userKey);
            onSessionExpired
                ?.call('Votre session a expiré. Veuillez vous reconnecter.');
          }
          return handler.next(error);
        },
      ),
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: false, // Désactivé : on ne log plus les erreurs techniques
      ),
    ]);

  Dio get dio => _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return _extractData<T>(response);
    } on DioException catch (e) {
      throw Exception(friendlyErrorMessage(e));
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<T> post<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _extractData<T>(response);
    } on DioException catch (e) {
      throw Exception(friendlyErrorMessage(e));
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<T> patch<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _extractData<T>(response);
    } on DioException catch (e) {
      throw Exception(friendlyErrorMessage(e));
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete(path);
      return _extractData<T>(response);
    } on DioException catch (e) {
      throw Exception(friendlyErrorMessage(e));
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<T> postMultipart<T>(String path, FormData formData) async {
    try {
      final response = await _dio.post(path, data: formData);
      return _extractData<T>(response);
    } on DioException catch (e) {
      throw Exception(friendlyErrorMessage(e));
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  T _extractData<T>(Response response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return body['data'] as T;
    }
    return body as T;
  }
}

final dioClient = DioClient();
