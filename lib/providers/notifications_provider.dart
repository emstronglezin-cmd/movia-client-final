import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../models/notification_model.dart';
import '../services/notifications_service.dart';
import 'auth_provider.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationsState copyWith({List<AppNotification>? notifications, bool? isLoading}) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsService _service;
  final Ref _ref;
  Timer? _pollingTimer;
  AppLifecycleListener? _lifecycleListener;

  NotificationsNotifier(this._service, this._ref)
      : super(const NotificationsState()) {
    _loadFromCache();
    _startPolling();
    _setupLifecycleListener();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConfig.notificationsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        final notifs = list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(notifications: notifs);
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(List<AppNotification> notifs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConfig.notificationsKey,
        jsonEncode(notifs.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    refresh();
  }

  void _setupLifecycleListener() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () => refresh(),
    );
  }

  Future<void> refresh() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    try {
      final notifs = await _service.getAll();
      state = state.copyWith(notifications: notifs);
      await _saveToCache(notifs);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markRead(id);
      final updated = state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
      state = state.copyWith(notifications: updated);
      await _saveToCache(updated);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      final updated = state.notifications.map((n) => n.copyWith(read: true)).toList();
      state = state.copyWith(notifications: updated);
      await _saveToCache(updated);
    } catch (_) {}
  }

  void addNotification(AppNotification notif) {
    final updated = [notif, ...state.notifications];
    state = state.copyWith(notifications: updated);
    _saveToCache(updated);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}

final _notificationsServiceProvider = Provider<NotificationsService>(
  (_) => NotificationsService(dioClient),
);

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(
    ref.read(_notificationsServiceProvider),
    ref,
  ),
);
