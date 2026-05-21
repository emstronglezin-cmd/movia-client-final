import '../core/network/dio_client.dart';
import '../models/booking_model.dart';

class CreateBookingRequest {
  final String tripId;
  final String passengerName;
  final String passengerPhone;
  final String? passengerCnib;
  final String? seatNumber;
  final double? baggageWeight;
  final String bookingMode;
  final String? paymentProvider;
  final bool isRoundTrip;
  final String? returnTripId;
  final String? returnSeatNumber;

  const CreateBookingRequest({
    required this.tripId,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerCnib,
    this.seatNumber,
    this.baggageWeight,
    this.bookingMode = 'pay_now',
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
        if (seatNumber != null) 'seatNumber': seatNumber,
        if (baggageWeight != null) 'baggageWeight': baggageWeight,
        'bookingMode': bookingMode,
        if (paymentProvider != null) 'paymentProvider': paymentProvider,
        'isRoundTrip': isRoundTrip,
        if (returnTripId != null) 'returnTripId': returnTripId,
        if (returnSeatNumber != null) 'returnSeatNumber': returnSeatNumber,
      };
}

class BookingsService {
  final DioClient _client;
  BookingsService([DioClient? client]) : _client = client ?? dioClient;

  Future<BookingItem> create(CreateBookingRequest request) async {
    final data = await _client.post<Map<String, dynamic>>('/bookings', data: request.toJson());
    return BookingItem.fromJson(data);
  }

  Future<List<BookingItem>> createBatch(List<CreateBookingRequest> requests) async {
    final data = await _client.post<List<dynamic>>(
      '/bookings/batch',
      data: {'bookings': requests.map((r) => r.toJson()).toList()},
    );
    return data.map((d) => BookingItem.fromJson(d as Map<String, dynamic>)).toList();
  }

  // Le backend retourne les bookings de l'utilisateur sur GET /bookings/user
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
}
