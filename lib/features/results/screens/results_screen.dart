import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/trip_model.dart';
import '../../../services/trips_service.dart';
import '../../../shared/constants/app_data.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> params;
  const ResultsScreen({super.key, required this.params});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final TripsService _tripsService = TripsService();
  List<TripResult> _trips = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'price_asc';
  String? _filterCompany;

  String get _from => widget.params['from'] as String? ?? '';
  String get _to => widget.params['to'] as String? ?? '';
  String get _date => widget.params['date'] as String? ?? '';
  int get _passengers => widget.params['passengers'] as int? ?? 1;
  bool get _isRoundTrip => widget.params['isRoundTrip'] as bool? ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dateStr = _date.isNotEmpty ? _date.substring(0, 10) : DateTime.now().toIso8601String().substring(0, 10);
      final results = await _tripsService.search(TripSearchParams(
        from: _from, to: _to, date: dateStr, passengers: _passengers,
      ));
      if (mounted) setState(() { _trips = results; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Mode hors-ligne. Résultats de démonstration affichés.';
          _isLoading = false;
          _trips = _mockTrips();
        });
      }
    }
  }

  List<TripResult> _mockTrips() {
    final dateStr = _date.isNotEmpty ? _date.substring(0, 10) : DateTime.now().toIso8601String().substring(0, 10);
    return companies.take(4).map((c) {
      final idx = companies.indexOf(c);
      return TripResult(
        id: 'mock_${c.id}',
        companyId: c.id,
        companyName: c.name,
        companyShortName: c.shortName,
        from: _from.isNotEmpty ? _from : 'Ouagadougou',
        to: _to.isNotEmpty ? _to : 'Bobo Dioulasso',
        fromStation: 'Gare centrale',
        toStation: 'Gare centrale',
        departureTime: ['06:30','08:00','10:30','14:00'][idx],
        arrivalTime: ['12:30','14:00','16:30','20:00'][idx],
        duration: '6h00',
        price: (7500 + idx * 500).toDouble(),
        seatsAvailable: 12 - idx * 2,
        totalSeats: 50,
        date: dateStr,
        supportsReservation: getCompanySupportsReservation(c.id),
      );
    }).toList();
  }

  List<TripResult> get _sortedTrips {
    var list = List<TripResult>.from(_trips);
    if (_filterCompany != null) {
      list = list.where((t) => t.companyId == _filterCompany).toList();
    }
    switch (_sortBy) {
      case 'price_asc':   list.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_desc':  list.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'time_asc':    list.sort((a, b) => a.departureTime.compareTo(b.departureTime)); break;
      case 'seats_desc':  list.sort((a, b) => b.seatsAvailable.compareTo(a.seatsAvailable)); break;
      default: break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final trips = _sortedTrips;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_from → $_to',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
            Text('$_passengers passager${_passengers > 1 ? 's' : ''}${_isRoundTrip ? ' · Aller-retour' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'price_asc', child: Text('Prix croissant')),
              PopupMenuItem(value: 'price_desc', child: Text('Prix décroissant')),
              PopupMenuItem(value: 'time_asc', child: Text('Départ le plus tôt')),
              PopupMenuItem(value: 'seats_desc', child: Text('Plus de places')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _AIDemandBanner(from: _from, to: _to),
          if (!_isLoading && _trips.isNotEmpty) _CompanyFilter(
            trips: _trips,
            selected: _filterCompany,
            onSelected: (id) => setState(() => _filterCompany = id == _filterCompany ? null : id),
          ),
          Expanded(
            child: _isLoading
                ? _SkeletonResults()
                : _error != null && _trips.isEmpty
                    ? _ErrorState(onRetry: _search)
                    : trips.isEmpty
                        ? const _EmptyResults()
                        : RefreshIndicator(
                            color: AppColors.primaryRed,
                            onRefresh: _search,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: trips.length + (_error != null ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (_error != null && i == 0) return _OfflineBanner();
                                final trip = trips[_error != null ? i - 1 : i];
                                return _TripCard(
                                  trip: trip,
                                  passengers: _passengers,
                                  isRoundTrip: _isRoundTrip,
                                  returnDate: widget.params['returnDate'] as String?,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Banner ───────────────────────────────────────────────────────────────

class _AIDemandBanner extends StatelessWidget {
  final String from, to;
  const _AIDemandBanner({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Forte demande sur $from → $to. Réservez rapidement !',
                style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Company Filter ───────────────────────────────────────────────────────────

class _CompanyFilter extends StatelessWidget {
  final List<TripResult> trips;
  final String? selected;
  final ValueChanged<String> onSelected;
  const _CompanyFilter({required this.trips, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final companyIds = trips.map((t) => t.companyId).toSet().toList();
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: companyIds.length,
        itemBuilder: (_, i) {
          final id = companyIds[i];
          final isSelected = id == selected;
          final color = getCompanyColor(id);
          return GestureDetector(
            onTap: () => onSelected(id),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                getCompanyShortName(id),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripResult trip;
  final int passengers;
  final bool isRoundTrip;
  final String? returnDate;
  const _TripCard({required this.trip, required this.passengers, required this.isRoundTrip, this.returnDate});

  @override
  Widget build(BuildContext context) {
    final color = getCompanyColor(trip.companyId);
    final totalPrice = trip.price * passengers;
    final isLowSeats = trip.seatsAvailable <= 5;

    return GestureDetector(
      onTap: () => context.push('/booking', extra: {
        'tripId': trip.id, 'companyId': trip.companyId,
        'from': trip.from, 'to': trip.to,
        'departureTime': trip.departureTime, 'arrivalTime': trip.arrivalTime,
        'price': trip.price, 'passengers': passengers,
        'travelDate': trip.date, 'isRoundTrip': isRoundTrip,
        'returnDate': returnDate, 'supportsReservation': trip.supportsReservation,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            // Header compagnie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Text(getCompanyShortName(trip.companyId),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text(getCompanyFullName(trip.companyId),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  if (isLowSeats)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20)),
                      child: Text('🔥 ${trip.seatsAvailable} places',
                          style: const TextStyle(color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.w600)),
                    )
                  else
                    Text('${trip.seatsAvailable} places',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(trip.from,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                          Text(trip.departureTime,
                              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      Column(children: [
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.textTertiary, size: 22),
                        Text(trip.duration, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      ]),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(trip.to,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                              textAlign: TextAlign.end),
                          Text(trip.arrivalTime,
                              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.end),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${formatPrice(totalPrice.toInt())} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryRed)),
                        if (passengers > 1)
                          Text('${formatPrice(trip.price.toInt())} FCFA/pers.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ]),
                      const Spacer(),
                      if (trip.supportsReservation)
                        TextButton(
                          onPressed: () => context.push('/booking', extra: {
                            'tripId': trip.id, 'companyId': trip.companyId,
                            'from': trip.from, 'to': trip.to,
                            'departureTime': trip.departureTime,
                            'price': trip.price, 'passengers': passengers,
                            'travelDate': trip.date, 'bookingMode': 'reserve_only',
                          }),
                          child: const Text('Réserver',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => context.push('/booking', extra: {
                          'tripId': trip.id, 'companyId': trip.companyId,
                          'from': trip.from, 'to': trip.to,
                          'departureTime': trip.departureTime, 'arrivalTime': trip.arrivalTime,
                          'price': trip.price, 'passengers': passengers,
                          'travelDate': trip.date, 'isRoundTrip': isRoundTrip,
                          'returnDate': returnDate, 'bookingMode': 'pay_now',
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text('Acheter',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(children: [
        Icon(Icons.wifi_off_rounded, color: Color(0xFFC2410C), size: 18),
        SizedBox(width: 10),
        Expanded(child: Text('Mode hors-ligne. Résultats de démonstration.',
            style: TextStyle(fontSize: 12, color: Color(0xFFC2410C)))),
      ]),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🔍', style: TextStyle(fontSize: 56)),
        SizedBox(height: 16),
        Text('Aucun trajet trouvé',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        SizedBox(height: 8),
        Text('Essayez une autre date ou un autre itinéraire',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        const Text('Connexion impossible',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Vérifiez votre connexion internet',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }
}

class _SkeletonResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 160,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          )),
        ),
      ),
    );
  }
}
