import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const Map<String, IconData> _icons = {
    'ticket': Icons.confirmation_num_rounded,
    'colis': Icons.inventory_2_rounded,
    'info': Icons.info_rounded,
    'promo': Icons.local_offer_rounded,
  };

  static const Map<String, Color> _colors = {
    'ticket': AppColors.primaryRed,
    'colis': Color(0xFF2563EB),
    'info': Color(0xFF0369A1),
    'promo': Color(0xFFD97706),
  };

  static const Map<String, Color> _bgColors = {
    'ticket': Color(0xFFFEF2F2),
    'colis': Color(0xFFEFF6FF),
    'info': Color(0xFFE0F2FE),
    'promo': Color(0xFFFFFBEB),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(10)),
                child: Text('${state.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllRead(),
              child: const Text('Tout lire', style: TextStyle(color: AppColors.primaryRed, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () => context.push('/notification-settings'),
          ),
        ],
      ),
      body: state.notifications.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () => notifier.refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (_, i) {
                  final n = state.notifications[i];
                  return _NotificationTile(
                    notification: n,
                    icon: _icons[n.type] ?? Icons.notifications_rounded,
                    color: _colors[n.type] ?? AppColors.primaryRed,
                    bgColor: _bgColors[n.type] ?? const Color(0xFFFEF2F2),
                    onTap: () => _handleTap(context, ref, n),
                  );
                },
              ),
            ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, AppNotification n) {
    if (!n.read) {
      ref.read(notificationsProvider.notifier).markRead(n.id);
    }
    if (n.linkTo != null) {
      final params = n.linkParams;
      context.push(n.linkTo!, extra: params);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;
  const _NotificationTile({
    required this.notification, required this.icon,
    required this.color, required this.bgColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.read ? Colors.transparent : color.withValues(alpha: 0.03),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                              fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notification.message,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(notification.time,
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Aucune notification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('Vous serez notifié de vos réservations\net mises à jour de colis',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
