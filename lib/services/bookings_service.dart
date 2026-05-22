import '../core/network/dio_client.dart';
import '../models/booking_model.dart';

/// Résultat de la création d'une réservation
/// Contient booking + payment (si applicable)
class BookingCreateResult {
  final BookingItem booking;
  final PaymentInfo? payment;

  const BookingCreateResult({required this.booking, this.payment});
}

class PaymentInfo {
  final String id;
  final String reference;
  final String status; // completed, pending, failed
  final double amount;
  final String? provider; // orange_money, moov_money

  const PaymentInfo({
    required this.id,
    required this.reference,
    required this.status,
    required this.amount,
    this.provider,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
    id: json['id']?.toString() ?? '',
    reference: json['reference']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    provider: json['provider']?.toString(),
  );

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}

class CreateBookingRequest {
  final String tripId;
  final String passengerName;
  final String passengerPhone;
  final String? passengerCnib;
  final int? seatNumber;       // ✅ int? (backend attend IsNumber, Min(1))
  final double? baggageWeight;
  final String? paymentProvider; // orange_money | moov_money
  final bool isRoundTrip;
  final String? returnTripId;
  final int? returnSeatNumber;   // ✅ int?

  const CreateBookingRequest({
    required this.tripId,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerCnib,
    this.seatNumber,
    this.baggageWeight,
    this.paymentProvider,
    this.isRoundTrip = false,
    this.returnTripId,
    this.returnSeatNumber,
  });

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'passengerName': passengerName,
        'passengerPhone': passengerPhone,
        if (passengerCnib != null && passengerCnib!.isNotEmpty) 'passengerCnib': passengerCnib,
        if (seatNumber != null) 'seatNumber': seatNumber,   // ✅ int
        if (baggageWeight != null) 'baggageWeight': baggageWeight,
        // ✅ paymentProvider: orange_money | moov_money (pas de bookingMode)
        if (paymentProvider != null) 'paymentProvider': paymentProvider,
        'isRoundTrip': isRoundTrip,
        if (returnTripId != null) 'returnTripId': returnTripId,
        if (returnSeatNumber != null) 'returnSeatNumber': returnSeatNumber,
      };
}

class BookingsService {
  final DioClient _client;
  BookingsService([DioClient? client]) : _client = client ?? dioClient;

  /// ✅ Crée une réservation et retourne booking + payment info
  Future<BookingCreateResult> create(CreateBookingRequest request) async {
    final data = await _client.post<Map<String, dynamic>>('/bookings', data: request.toJson());
    // La réponse POST /bookings (après unwrap data) = { booking: {...}, payment: {...} }
    final bookingData = data['booking'] as Map<String, dynamic>? ?? data;
    final paymentData = data['payment'] as Map<String, dynamic>?;

    return BookingCreateResult(
      booking: BookingItem.fromJson(bookingData),
      payment: paymentData != null ? PaymentInfo.fromJson(paymentData) : null,
    );
  }

  /// Crée seulement le BookingItem (pour compatibilité provider existant)
  Future<BookingItem> createSimple(CreateBookingRequest request) async {
    final result = await create(request);
    return result.booking;
  }

  Future<List<BookingItem>> createBatch(List<CreateBookingRequest> requests) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/bookings/batch',
      data: {'bookings': requests.map((r) => r.toJson()).toList()},
    );
    if (data.containsKey('bookings')) {
      final list = data['bookings'] as List<dynamic>;
      return list.map((d) => BookingItem.fromJson(d as Map<String, dynamic>)).toList();
    }
    if (data.containsKey('booking')) {
      return [BookingItem.fromJson(data['booking'] as Map<String, dynamic>)];
    }
    return [BookingItem.fromJson(data)];
  }

  Future<List<BookingItem>> getMyBookings() async {
    final data = await _client.get<List<dynamic>>('/bookings/user');
    return data.map((d) => BookingItem.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<BookingItem> getById(String id) async {
    final data = await _client.get<Map<String, dynamic>>('/bookings/$id');
    return BookingItem.fromJson(data);
  }

  Future<BookingItem> cancel(String id, {String? reason}) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/bookings/$id/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return BookingItem.fromJson(data);
  }

  /// Valider un ticket (endpoint controller)
  Future<Map<String, dynamic>> validateTicket(String bookingId) async {
    return await _client.post<Map<String, dynamic>>('/bookings/$bookingId/validate');
  }

  /// Récupérer les sièges occupés d'un trajet
  Future<Map<String, dynamic>> getTripSeats(String tripId) async {
    return await _client.get<Map<String, dynamic>>('/trips/$tripId/seats');
  }
}
