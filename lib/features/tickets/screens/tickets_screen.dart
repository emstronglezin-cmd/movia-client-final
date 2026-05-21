import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookings_provider.dart';
import '../../../models/booking_model.dart';
import '../../../shared/constants/app_data.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await ref.read(bookingsProvider.notifier).load();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final active = _sortBookings(state.active);
    final history = _sortBookings(state.history);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Tickets',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'date_desc', child: Text('Plus récent d\'abord')),
              const PopupMenuItem(
                  value: 'date_asc', child: Text('Plus ancien d\'abord')),
              const PopupMenuItem(
                  value: 'price_desc', child: Text('Prix décroissant')),
              const PopupMenuItem(
                  value: 'price_asc', child: Text('Prix croissant')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryRed,
          indicatorWeight: 3,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Actifs (${active.length})'),
            Tab(text: 'Historique (${history.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Card
          _StatsCard(state: state),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryRed))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _TicketList(
                          bookings: active,
                          emptyMessage: 'Aucun ticket actif',
                          onSearch: () => context.push('/search')),
                      _TicketList(
                          bookings: history,
                          emptyMessage: 'Aucun historique'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<BookingItem> _sortBookings(List<BookingItem> list) {
    final sorted = List<BookingItem>.from(list);
    switch (_sortBy) {
      case 'date_asc':
        sorted.sort((a, b) => a.travelDate.compareTo(b.travelDate));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      default:
        sorted.sort((a, b) => b.travelDate.compareTo(a.travelDate));
    }
    return sorted;
  }
}

class _StatsCard extends StatelessWidget {
  final BookingsState state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _Stat(
              label: 'Actifs',
              value: '${state.activeCount}',
              color: const Color(0xFF059669)),
          _Divider(),
          _Stat(
              label: 'Réservés',
              value: '${state.history.where((b) => b.status == 'reserved').length}',
              color: const Color(0xFF2563EB)),
          _Divider(),
          _Stat(
              label: 'Total voyages',
              value: '${state.all.length}',
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.grey[200]);
  }
}

class _TicketList extends StatelessWidget {
  final List<BookingItem> bookings;
  final String emptyMessage;
  final VoidCallback? onSearch;
  const _TicketList(
      {required this.bookings, required this.emptyMessage, this.onSearch});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎫', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            if (onSearch != null) ...[
              const SizedBox(height: 8),
              const Text('Réservez votre prochain trajet',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rechercher un trajet',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async =>
          context.findAncestorStateOfType<_TicketsScreenState>()!._load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _TicketCard(booking: bookings[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final BookingItem booking;
  const _TicketCard({required this.booking});

  @override
  Widget build(BuildContext context) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Text(
                    getCompanyFullName(booking.companyId),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _StatusChip(status: booking.status),
                ],
              ),
            ),
            // Route
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.textPrimary)),
                            Text(booking.departureTime,
                                style: TextStyle(
                                    fontSize: 12, color: companyColor,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              color: companyColor, size: 20),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(booking.to,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.textPrimary),
                                textAlign: TextAlign.end),
                            Text(booking.arrivalTime ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: companyColor,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.end),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(booking.travelDate,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.event_seat_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('Siège ${booking.seatNumber ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(
                        '${formatPrice(booking.totalPrice.toInt())} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'active':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF166534); label = '● Actif';
        break;
      case 'reserved':
        bg = const Color(0xFFE0F2FE); fg = const Color(0xFF0369A1); label = '● Réservé';
        break;
      case 'used':
        bg = const Color(0xFFF3F4F6); fg = const Color(0xFF6B7280); label = '✓ Utilisé';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEF2F2); fg = AppColors.primaryRed; label = '✕ Annulé';
        break;
      case 'expired':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFC2410C); label = '⚠ Expiré';
        break;
      default:
        bg = Colors.grey[100]!; fg = Colors.grey; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
