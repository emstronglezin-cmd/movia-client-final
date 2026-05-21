import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bookings_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/booking_model.dart';
import '../../../shared/constants/app_data.dart';

class TrajetsScreen extends ConsumerStatefulWidget {
  const TrajetsScreen({super.key});

  @override
  ConsumerState<TrajetsScreen> createState() => _TrajetsScreenState();
}

class _TrajetsScreenState extends ConsumerState<TrajetsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await ref.read(bookingsProvider.notifier).load();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bookingsState = ref.watch(bookingsProvider);
    final notifState = ref.watch(notificationsProvider);
    final firstName = auth.user?.name.split(' ').first ?? 'Voyageur';
    final upcoming = bookingsState.active.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour, $firstName 👋',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const Text('Où voulez-vous aller ?',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_rounded,
                            color: AppColors.textPrimary),
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
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Search CTA
                  _SearchCard(onTap: () => context.push('/search')),
                  const SizedBox(height: 20),

                  // Promo Banner
                  _PromoBanner(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _SectionTitle('Actions rapides'),
                  const SizedBox(height: 12),
                  _QuickActions(),
                  const SizedBox(height: 24),

                  // Upcoming trips
                  _SectionTitle(
                    'Prochains voyages',
                    action: bookingsState.active.isNotEmpty
                        ? TextButton(
                            onPressed: () => context.go('/tickets'),
                            child: const Text('Voir tout',
                                style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontSize: 13)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? _SkeletonList()
                      : upcoming.isEmpty
                          ? _EmptyUpcoming(
                              onSearch: () => context.push('/search'))
                          : Column(
                              children: upcoming
                                  .map((b) => _UpcomingTripCard(booking: b))
                                  .toList(),
                            ),
                  const SizedBox(height: 24),

                  // AI Insight banner
                  _AIInsightBanner(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Card ─────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded,
                  color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rechercher un trajet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  Text('Ouagadougou → Bobo-Dioulasso...',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, Color(0xFF8B2E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🎉 Offre spéciale',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                const Text('10% de réduction\npour votre premier trajet',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  child: const Text('Réserver maintenant'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🚌', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.search_rounded,
          label: 'Rechercher',
          color: AppColors.primaryRed,
          onTap: () => context.push('/search')),
      _QuickAction(
          icon: Icons.inventory_2_rounded,
          label: 'Envoyer colis',
          color: const Color(0xFF2563EB),
          onTap: () => context.push('/send-package')),
      _QuickAction(
          icon: Icons.star_rounded,
          label: 'Favoris',
          color: const Color(0xFFD97706),
          onTap: () => context.push('/favorites')),
      _QuickAction(
          icon: Icons.business_rounded,
          label: 'Compagnies',
          color: const Color(0xFF059669),
          onTap: () => context.push('/companies')),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => a).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionTitle(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Upcoming Trip Card ────────────────────────────────────────────────────────

class _UpcomingTripCard extends StatelessWidget {
  final BookingItem booking;
  const _UpcomingTripCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final company = getCompanyById(booking.companyId);
    final companyColor = getCompanyColor(booking.companyId);
    return GestureDetector(
      onTap: () =>
          context.push('/ticket-detail', extra: {'bookingId': booking.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Company header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: companyColor.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: companyColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      getCompanyShortName(booking.companyId),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(getCompanyFullName(booking.companyId),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  _StatusBadge(status: booking.status),
                ],
              ),
            ),
            // Route info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.from,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary)),
                            Text(booking.departureStation ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.textTertiary, size: 18),
                          Text(booking.departureTime,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(booking.to,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary),
                                textAlign: TextAlign.end),
                            Text(booking.arrivalStation ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.end),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(booking.travelDate,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(
                        '${formatPrice(booking.totalPrice.toInt())} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'active':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Actif';
        break;
      case 'reserved':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Réservé';
        break;
      case 'used':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Utilisé';
        break;
      default:
        bg = const Color(0xFFFEF2F2);
        fg = AppColors.primaryRed;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyUpcoming extends StatelessWidget {
  final VoidCallback onSearch;
  const _EmptyUpcoming({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          const Text('🚌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Aucun voyage à venir',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Réservez votre prochain trajet dès maintenant',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rechercher un trajet',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── AI Insight Banner ─────────────────────────────────────────────────────────

class _AIInsightBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1B4B).withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('✨', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conseil IA Movia',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E1B4B))),
                SizedBox(height: 2),
                Text('Le trajet Ouaga → Bobo est très demandé le vendredi. Réservez tôt pour avoir les meilleurs prix.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Loading ──────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
