import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/notifications_provider.dart';
import '../../../providers/bookings_provider.dart';
import '../../../providers/packages_provider.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/colis')) return 1;
    if (location.startsWith('/tickets')) return 2;
    if (location.startsWith('/compte')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/colis'); break;
      case 2: context.go('/tickets'); break;
      case 3: context.go('/compte'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final notifState = ref.watch(notificationsProvider);
    final bookingsState = ref.watch(bookingsProvider);
    final packagesState = ref.watch(packagesProvider);

    final unreadNotifs = notifState.unreadCount;
    final activeTickets = bookingsState.activeCount;
    final activePkgs = packagesState.activeCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.directions_bus_rounded,
                  label: 'Trajets',
                  isSelected: currentIndex == 0,
                  badge: 0,
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Colis',
                  isSelected: currentIndex == 1,
                  badge: activePkgs,
                  onTap: () => _onTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.confirmation_num_rounded,
                  label: 'Tickets',
                  isSelected: currentIndex == 2,
                  badge: activeTickets,
                  onTap: () => _onTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Compte',
                  isSelected: currentIndex == 3,
                  badge: unreadNotifs,
                  onTap: () => _onTap(context, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryRed : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
