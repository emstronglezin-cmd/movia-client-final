import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/notifications_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationBell;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showNotificationBell = false,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).unreadCount;
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.tabBgInactive,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textDark),
              ),
              onPressed: () => context.pop(),
            )
          : null,
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      actions: [
        if (showNotificationBell) _NotificationBell(unread: unread),
        ...?actions,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unread;
  const _NotificationBell({required this.unread});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 24),
            onPressed: () => context.push('/notifications'),
          ),
          if (unread > 0)
            Positioned(
              top: 8, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MoviaBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const MoviaBackButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => context.pop(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.tabBgInactive,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textDark),
      ),
    );
  }
}
