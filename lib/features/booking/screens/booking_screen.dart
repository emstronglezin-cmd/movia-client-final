import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/bookings_service.dart';
import '../../../shared/constants/app_data.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> params;
  const BookingScreen({super.key, required this.params});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0; // 0=passagers, 1=siège(s), 2=paiement, 3=confirmation
  String _bookingMode = 'pay_now';
  String _paymentProvider = 'orange_money';
  bool _isSubmitting = false;
  String? _error;

  // Passenger forms
  List<Map<String, TextEditingController>> _passengerControllers = [];

  // Seats
  List<String?> _selectedSeats = [];

  // Return trip
  bool get _isRoundTrip => widget.params['isRoundTrip'] as bool? ?? false;
  int get _step2Max => _isRoundTrip ? 4 : 3;

  String get _tripId => widget.params['tripId'] as String? ?? '';
  String get _companyId => widget.params['companyId'] as String? ?? '';
  String get _from => widget.params['from'] as String? ?? '';
  String get _to => widget.params['to'] as String? ?? '';
  String get _departureTime => widget.params['departureTime'] as String? ?? '';
  String get _arrivalTime => widget.params['arrivalTime'] as String? ?? '';
  double get _price => (widget.params['price'] as num?)?.toDouble() ?? 0.0;
  int get _passengers => widget.params['passengers'] as int? ?? 1;
  String get _travelDate => widget.params['travelDate'] as String? ?? '';

  double get _totalPrice => _price * _passengers;

  @override
  void initState() {
    super.initState();
    _bookingMode = widget.params['bookingMode'] as String? ?? 'pay_now';
    _passengerControllers = List.generate(
      _passengers,
      (_) => {
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'cnib': TextEditingController(),
      },
    );
    _selectedSeats = List.filled(_passengers, null);
  }

  @override
  void dispose() {
    for (final pc in _passengerControllers) {
      pc.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 0) {
      return _passengerControllers.every((pc) =>
          pc['name']!.text.trim().isNotEmpty &&
          pc['phone']!.text.trim().length >= 8);
    }
    if (_step == 1) return _selectedSeats.every((s) => s != null);
    return true;
  }

  void _next() {
    if (_step < _step2Max - 1) setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _confirm() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id ?? '';
      final requests = List.generate(_passengers, (i) => CreateBookingRequest(
        tripId: _tripId,
        seatNumber: _selectedSeats[i] ?? '${i + 1}',
        passengerName: _passengerControllers[i]['name']!.text.trim(),
        passengerPhone: _passengerControllers[i]['phone']!.text.trim(),
        passengerCnib: _passengerControllers[i]['cnib']!.text.trim(),
        bookingMode: _bookingMode,
        paymentProvider: _bookingMode == 'pay_now' ? _paymentProvider : null,
      ));
      if (requests.length == 1) {
        await ref.read(bookingsProvider.notifier).createBooking(requests.first);
      } else {
        await ref.read(bookingsProvider.notifier).createBatchBooking(requests);
      }
      if (mounted) setState(() { _step = _isRoundTrip ? 4 : 3; _isSubmitting = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Paiement échoué. Veuillez réessayer.'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _step == (_isRoundTrip ? 4 : 3);
    if (isSuccess) return _SuccessScreen(from: _from, to: _to, mode: _bookingMode);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _step == 0 ? () => context.pop() : _prev,
        ),
        title: Text(
          _stepTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(current: _step, total: _isRoundTrip ? 4 : 3),
        ),
      ),
      body: Column(
        children: [
          // Trip summary
          _TripSummary(
            from: _from,
            to: _to,
            companyId: _companyId,
            departureTime: _departureTime,
            travelDate: _travelDate,
            totalPrice: _totalPrice,
          ),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: [
                _PassengersForm(controllers: _passengerControllers),
                _SeatPicker(
                  passengers: _passengers,
                  selectedSeats: _selectedSeats,
                  onSeatSelected: (i, seat) => setState(() => _selectedSeats[i] = seat),
                ),
                _PaymentStep(
                  mode: _bookingMode,
                  provider: _paymentProvider,
                  totalPrice: _totalPrice,
                  error: _error,
                  onModeChanged: (m) => setState(() => _bookingMode = m),
                  onProviderChanged: (p) => setState(() => _paymentProvider = p),
                ),
              ][_step > 2 ? 2 : _step],
            ),
          ),
          // Bottom bar
          _BottomBar(
            step: _step,
            canProceed: _canProceed,
            isSubmitting: _isSubmitting,
            isLastStep: _step == 2,
            onNext: _next,
            onConfirm: _confirm,
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Informations passagers';
      case 1: return 'Choix des sièges';
      case 2: return 'Paiement';
      default: return 'Réservation';
    }
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          height: 3,
          color: i <= current ? AppColors.primaryRed : Colors.grey[200],
        ),
      )),
    );
  }
}

// ─── Trip Summary ────────────────────────────────────────────────────────────

class _TripSummary extends StatelessWidget {
  final String from, to, companyId, departureTime, travelDate;
  final double totalPrice;
  const _TripSummary({
    required this.from, required this.to, required this.companyId,
    required this.departureTime, required this.travelDate, required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final color = getCompanyColor(companyId);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(getCompanyShortName(companyId),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$from → $to • $departureTime',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${formatPrice(totalPrice.toInt())} FCFA',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryRed)),
        ],
      ),
    );
  }
}

// ─── Passengers Form ─────────────────────────────────────────────────────────

class _PassengersForm extends StatelessWidget {
  final List<Map<String, TextEditingController>> controllers;
  const _PassengersForm({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(controllers.length, (i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                ),
                const SizedBox(width: 10),
                Text('Passager ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 14),
            _FormField(controller: controllers[i]['name']!, label: 'Nom complet', hint: 'Ex: Koné Ibrahim', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _FormField(controller: controllers[i]['phone']!, label: 'Téléphone', hint: '70 00 00 00', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _FormField(controller: controllers[i]['cnib']!, label: 'CNIB (optionnel)', hint: 'B1234567', icon: Icons.badge_outlined),
          ],
        ),
      )),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  const _FormField({
    required this.controller, required this.label, required this.hint, required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 18),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Seat Picker ─────────────────────────────────────────────────────────────

class _SeatPicker extends StatelessWidget {
  final int passengers;
  final List<String?> selectedSeats;
  final Function(int, String) onSeatSelected;
  const _SeatPicker({required this.passengers, required this.selectedSeats, required this.onSeatSelected});

  static const List<String> _occupiedSeats = ['3', '7', '12', '15', '21', '28', '35'];

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(12, (r) => r + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _SeatLegend(),
        const SizedBox(height: 16),
        // Bus front
        Center(
          child: Container(
            width: 60, height: 30,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
            child: const Center(child: Icon(Icons.airline_seat_recline_normal_rounded, size: 16, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
        // Seat grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: rows.map((r) {
              final seats = ['${(r - 1) * 4 + 1}', '${(r - 1) * 4 + 2}', null, '${(r - 1) * 4 + 3}', '${(r - 1) * 4 + 4}'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, child: Text('$r', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary))),
                    const SizedBox(width: 8),
                    ...seats.map((s) {
                      if (s == null) return const SizedBox(width: 16);
                      final isOccupied = _occupiedSeats.contains(s);
                      final selectedIdx = selectedSeats.indexOf(s);
                      final isSelected = selectedIdx != -1;
                      return GestureDetector(
                        onTap: isOccupied ? null : () {
                          // Find which passenger to assign
                          final firstEmpty = selectedSeats.indexWhere((seat) => seat == null);
                          if (firstEmpty != -1) {
                            onSeatSelected(firstEmpty, s);
                          } else if (passengers > 1 && isSelected) {
                            onSeatSelected(selectedIdx, '');
                          }
                        },
                        child: Container(
                          width: 36, height: 36,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? Colors.grey[200]
                                : isSelected
                                    ? AppColors.primaryRed
                                    : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOccupied ? Colors.grey[300]! : isSelected ? AppColors.primaryRed : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(s,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOccupied ? Colors.grey[400] : isSelected ? Colors.white : AppColors.textPrimary,
                                )),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Selected seats summary
        if (selectedSeats.any((s) => s != null))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_seat_rounded, color: AppColors.primaryRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sièges sélectionnés: ${selectedSeats.where((s) => s != null).join(', ')}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryRed),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeatLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.background, border: Colors.grey[300]!, label: 'Disponible'),
        const SizedBox(width: 16),
        _LegendItem(color: AppColors.primaryRed, border: AppColors.primaryRed, label: 'Sélectionné'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.grey[200]!, border: Colors.grey[300]!, label: 'Occupé'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color, border;
  final String label;
  const _LegendItem({required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: border)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Payment Step ─────────────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  final String mode, provider;
  final double totalPrice;
  final String? error;
  final ValueChanged<String> onModeChanged, onProviderChanged;
  const _PaymentStep({
    required this.mode, required this.provider, required this.totalPrice,
    this.error, required this.onModeChanged, required this.onProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à payer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('${formatPrice(totalPrice.toInt())} FCFA',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryRed)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Mode selection (if supports reservation)
        const Text('Mode de réservation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        _ModeCard(
          title: 'Payer maintenant',
          subtitle: 'Ticket confirmé immédiatement',
          icon: Icons.payment_rounded,
          isSelected: mode == 'pay_now',
          onTap: () => onModeChanged('pay_now'),
        ),
        const SizedBox(height: 8),
        _ModeCard(
          title: 'Réserver seulement',
          subtitle: 'Payez plus tard à la gare (si disponible)',
          icon: Icons.bookmark_outline_rounded,
          isSelected: mode == 'reserve_only',
          onTap: () => onModeChanged('reserve_only'),
        ),
        const SizedBox(height: 20),

        // Payment provider (only for pay_now)
        if (mode == 'pay_now') ...[
          const Text('Méthode de paiement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          _ProviderCard(
            name: 'Orange Money',
            icon: '🟠',
            isSelected: provider == 'orange_money',
            onTap: () => onProviderChanged('orange_money'),
          ),
          const SizedBox(height: 8),
          _ProviderCard(
            name: 'Moov Money',
            icon: '🔵',
            isSelected: provider == 'moov_money',
            onTap: () => onProviderChanged('moov_money'),
          ),
        ],

        if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 13))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ModeCard({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primaryRed : Colors.grey[200]!, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? AppColors.primaryRed : AppColors.textTertiary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? AppColors.primaryRed : AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String name, icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ProviderCard({required this.name, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primaryRed : Colors.grey[200]!, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isSelected ? AppColors.primaryRed : AppColors.textPrimary))),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int step;
  final bool canProceed, isSubmitting, isLastStep;
  final VoidCallback onNext, onConfirm;
  const _BottomBar({required this.step, required this.canProceed, required this.isSubmitting, required this.isLastStep, required this.onNext, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (canProceed && !isSubmitting) ? (isLastStep ? onConfirm : onNext) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isLastStep ? 'Confirmer et payer' : 'Continuer',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// ─── Success Screen ───────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final String from, to, mode;
  const _SuccessScreen({required this.from, required this.to, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isReservation = mode == 'reserve_only';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎉', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 24),
              Text(
                isReservation ? 'Réservation confirmée !' : 'Paiement réussi !',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isReservation
                    ? 'Votre siège de $from → $to a été réservé. Payez à la gare avant le départ.'
                    : 'Votre ticket de $from → $to a été émis. Bon voyage ! 🚌',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/tickets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Voir mes tickets', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l\'accueil', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
