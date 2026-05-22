import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookings_provider.dart';
import '../../../models/booking_model.dart';
import '../../../shared/constants/app_data.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const TicketDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _isCancelModalOpen = false;
  String? _cancelReason;
  int _cancelStep = 0; // 0=reasons, 1=cancelling, 2=contact

  static const List<String> _cancelReasons = [
    'Changement de programme',
    'Problème de santé',
    'Urgence familiale',
    'Erreur de réservation',
    'Prix trop élevé',
    'Autre raison',
  ];

  static const String _supportPhone = '+22670000000';

  BookingItem? _getBooking(BookingsState state) {
    try {
      return state.all.firstWhere((b) => b.id == widget.bookingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final booking = _getBooking(state);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text('Détail du ticket'),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final companyColor = getCompanyColor(booking.companyId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mon ticket',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
            onPressed: () => _shareTicket(booking),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                // Status banner
                _StatusBanner(status: booking.status),
                const SizedBox(height: 16),

                // QR Code card
                _QRCard(booking: booking, companyColor: companyColor),
                const SizedBox(height: 16),

                // Route details
                _RouteCard(booking: booking, companyColor: companyColor),
                const SizedBox(height: 16),

                // Passenger info
                _PassengerCard(booking: booking),
                const SizedBox(height: 16),

                // Payment info
                _PaymentCard(booking: booking),

                // Cancel button (if cancellable)
                if (booking.isActive || booking.isReserved) ...[
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => setState(() { _isCancelModalOpen = true; _cancelStep = 0; }),
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.primaryRed, size: 18),
                    label: const Text('Annuler ce billet',
                        style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Cancel modal
          if (_isCancelModalOpen)
            _CancelModal(
              step: _cancelStep,
              reasons: _cancelReasons,
              selectedReason: _cancelReason,
              onReasonSelected: (r) => setState(() => _cancelReason = r),
              onCancel: () => setState(() { _isCancelModalOpen = false; _cancelStep = 0; _cancelReason = null; }),
              onConfirm: () async {
                setState(() => _cancelStep = 1);
                await _doCancel(booking.id);
              },
              onContactSupport: () {
                setState(() => _isCancelModalOpen = false);
                _callSupport();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _doCancel(String id) async {
    try {
      await ref.read(bookingsProvider.notifier).cancelBooking(id);
      if (mounted) setState(() { _cancelStep = 2; });
    } catch (e) {
      if (mounted) {
        setState(() { _isCancelModalOpen = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'annulation. Contactez le support.')),
        );
      }
    }
  }

  void _shareTicket(BookingItem booking) {
    Share.share(
      'Mon ticket Movia 🚌\n'
      '${booking.from} → ${booking.to}\n'
      'Date: ${booking.travelDate} à ${booking.departureTime}\n'
      'Réf: ${booking.id.substring(0, 8).toUpperCase()}',
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:$_supportPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String icon, label, desc;
    switch (status) {
      case 'active':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF166534);
        icon = '✅'; label = 'Billet actif'; desc = 'Votre billet est valide et prêt à l\'emploi';
        break;
      case 'reserved':
        bg = const Color(0xFFE0F2FE); fg = const Color(0xFF0369A1);
        icon = '🔖'; label = 'Réservé'; desc = 'Payez à la gare avant le départ';
        break;
      case 'used':
        bg = const Color(0xFFF3F4F6); fg = const Color(0xFF6B7280);
        icon = '✓'; label = 'Utilisé'; desc = 'Ce trajet a été effectué';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEF2F2); fg = AppColors.primaryRed;
        icon = '✕'; label = 'Annulé'; desc = 'Ce billet a été annulé';
        break;
      default:
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFC2410C);
        icon = '⚠'; label = 'Expiré'; desc = 'Ce billet est expiré';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: fg)),
                Text(desc, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QR Card ────────────────────────────────────────────────────────────────

class _QRCard extends StatelessWidget {
  final BookingItem booking;
  final Color companyColor;
  const _QRCard({required this.booking, required this.companyColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadowStrong, blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Company header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: companyColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text('MOVIA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                const Spacer(),
                Text(getCompanyFullName(booking.companyId),
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // QR Code
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                QrImageView(
                  // ✅ CORRIGÉ: Le QR encode la bookingReference (pas l'id)
                  // Le backend GET /bookings/scan?qrCode=MOV-2026-XXXXX attend la référence
                  data: booking.bookingReference.isNotEmpty
                      ? booking.bookingReference
                      : booking.id,
                  version: QrVersions.auto,
                  size: 180,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  booking.bookingReference.isNotEmpty
                      ? booking.bookingReference
                      : booking.id.substring(0, 8).toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: companyColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Présentez ce QR code à l\'embarquement',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Dashed separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(30, (_) => Expanded(
                child: Container(
                  height: 1,
                  color: _ % 2 == 0 ? Colors.grey[300] : Colors.transparent,
                ),
              )),
            ),
          ),
          // Route summary
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QRInfoCol(label: 'De', value: booking.from),
                Column(children: [
                  Icon(Icons.arrow_forward_rounded, color: companyColor, size: 20),
                  Text(booking.departureTime,
                      style: TextStyle(fontSize: 13, color: companyColor, fontWeight: FontWeight.w700)),
                ]),
                _QRInfoCol(label: 'À', value: booking.to, align: CrossAxisAlignment.end),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QRInfoCol extends StatelessWidget {
  final String label, value;
  final CrossAxisAlignment align;
  const _QRInfoCol({required this.label, required this.value, this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ─── Route Card ──────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final BookingItem booking;
  final Color companyColor;
  const _RouteCard({required this.booking, required this.companyColor});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Détails du trajet',
      children: [
        _InfoRow(label: 'Date', value: booking.travelDate),
        _InfoRow(label: 'Départ', value: '${booking.departureTime} — ${booking.departureStation ?? booking.from}'),
        if (booking.arrivalTime != null)
          _InfoRow(label: 'Arrivée', value: '${booking.arrivalTime} — ${booking.arrivalStation ?? booking.to}'),
        _InfoRow(label: 'Siège', value: booking.seatNumber.toString()),
        _InfoRow(label: 'Compagnie', value: getCompanyFullName(booking.companyId)),
      ],
    );
  }
}

// ─── Passenger Card ──────────────────────────────────────────────────────────

class _PassengerCard extends StatelessWidget {
  final BookingItem booking;
  const _PassengerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Passager',
      children: [
        _InfoRow(label: 'Nom', value: booking.passengerName ?? 'N/A'),
        _InfoRow(label: 'Téléphone', value: booking.passengerPhone ?? 'N/A'),
        if (booking.passengerCnib != null)
          _InfoRow(label: 'CNIB', value: booking.passengerCnib!),
      ],
    );
  }
}

// ─── Payment Card ────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final BookingItem booking;
  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Paiement',
      children: [
        _InfoRow(label: 'Montant', value: '${formatPrice(booking.totalPrice.toInt())} FCFA'),
        _InfoRow(label: 'Mode', value: booking.bookingMode == 'reserve_only' ? 'Réservation' : 'Paiement mobile'),
        if (booking.paymentProvider != null)
          _InfoRow(label: 'Opérateur', value: booking.paymentProvider!.replaceAll('_', ' ').toUpperCase()),
        _InfoRow(label: 'Statut paiement', value: booking.paymentStatus ?? 'N/A'),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Cancel Modal ─────────────────────────────────────────────────────────────

class _CancelModal extends StatelessWidget {
  final int step;
  final List<String> reasons;
  final String? selectedReason;
  final ValueChanged<String> onReasonSelected;
  final VoidCallback onCancel, onConfirm, onContactSupport;
  const _CancelModal({
    required this.step, required this.reasons, this.selectedReason,
    required this.onReasonSelected, required this.onCancel,
    required this.onConfirm, required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              if (step == 0) ...[
                const Text('Annuler le billet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Veuillez indiquer la raison de votre annulation',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ...reasons.map((r) => GestureDetector(
                  onTap: () => onReasonSelected(r),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedReason == r ? AppColors.primaryRed.withValues(alpha: 0.06) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selectedReason == r ? AppColors.primaryRed : Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(r, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selectedReason == r ? AppColors.primaryRed : AppColors.textPrimary))),
                        if (selectedReason == r)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 20),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onCancel,
                        child: const Text('Retour', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedReason != null ? onConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ] else if (step == 1) ...[
                const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                const SizedBox(height: 16),
                const Center(child: Text('Annulation en cours...', style: TextStyle(fontSize: 15, color: AppColors.textSecondary))),
                const SizedBox(height: 24),
              ] else ...[
                const Text('Annulation traitée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Votre demande d\'annulation a été traitée. Contactez le support pour le remboursement.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                    label: const Text('Contacter le support', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text('Fermer', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
