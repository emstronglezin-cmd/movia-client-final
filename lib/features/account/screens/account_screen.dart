import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notifications_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifState = ref.watch(notificationsProvider);
    final user = auth.user;
    final memberId = (user?.id ?? '').length >= 8
        ? (user?.id ?? '').substring(0, 8).toUpperCase()
        : (user?.id ?? '').toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primaryRed,
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded,
                        color: Colors.white),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (notifState.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryRed, Color(0xFF8B2E2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () => context.push('/personal-info'),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: user?.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person_rounded,
                                              color: Colors.white, size: 36),
                                    ),
                                  )
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user?.name ?? 'Utilisateur',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${user?.phone ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'ID: $memberId',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (user?.emailVerified == true) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded,
                                        color: Colors.white, size: 16),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.white70, size: 20),
                          onPressed: () => context.push('/personal-info'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Email verification banner
                if (user?.email != null && user?.emailVerified != true)
                  _EmailVerifyBanner(),

                // Loyalty card
                _LoyaltyCard(onTap: () => context.push('/loyalty')),
                const SizedBox(height: 20),

                // Menu sections
                _MenuSection(
                  title: 'Mon compte',
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Informations personnelles',
                      onTap: () => context.push('/personal-info'),
                    ),
                    _MenuItem(
                      icon: Icons.payment_rounded,
                      label: 'Méthodes de paiement',
                      onTap: () => context.push('/payment-methods'),
                    ),
                    _MenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'Programme fidélité',
                      onTap: () => context.push('/loyalty'),
                      badge: '🥉',
                    ),
                    _MenuItem(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Trajets favoris',
                      onTap: () => context.push('/favorites'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MenuSection(
                  title: 'Paramètres',
                  items: [
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => context.push('/notification-settings'),
                      trailing: notifState.unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                    ),
                    _MenuItem(
                      icon: Icons.language_rounded,
                      label: 'Langue',
                      subtitle: 'Français',
                      onTap: () => context.push('/language'),
                    ),
                    _MenuItem(
                      icon: Icons.tune_rounded,
                      label: 'Préférences',
                      onTap: () => context.push('/preferences'),
                    ),
                    _MenuItem(
                      icon: Icons.business_rounded,
                      label: 'Compagnies de transport',
                      onTap: () => context.push('/companies'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MenuSection(
                  title: 'Aide & Support',
                  items: [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Aide & Support',
                      onTap: () => context.push('/help-support'),
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      label: 'Conditions d\'utilisation',
                      onTap: () => context.push('/terms'),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Politique de confidentialité',
                      onTap: () => context.push('/privacy'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Logout
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.primaryRed, size: 20),
                    ),
                    title: const Text('Se déconnecter',
                        style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Movia v1.0.0 — Burkina Faso',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EmailVerifyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded,
              color: Color(0xFFC2410C), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Vérifiez votre adresse email pour sécuriser votre compte.',
              style: TextStyle(fontSize: 12, color: Color(0xFFC2410C)),
            ),
          ),
          TextButton(
            onPressed: () {},
            style:
                TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Vérifier',
                style: TextStyle(
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LoyaltyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF78350F), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFB45309).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            const Text('🥉', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Niveau Bronze',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Text('0 points accumulés',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.1,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('1000 pts pour Silver',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 54),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryRed, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          (badge != null
              ? Text(badge!, style: const TextStyle(fontSize: 16))
              : const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textTertiary)),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
