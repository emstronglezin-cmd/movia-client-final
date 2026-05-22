import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/booking_model.dart';
import '../services/bookings_service.dart';

class BookingsState {
  final List<BookingItem> bookings;
  final bool isLoading;
  final String? error;
  final BookingCreateResult? lastCreateResult; // ✅ Inclut payment info

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
    this.lastCreateResult,
  });

  List<BookingItem> get active => bookings.where((b) => b.status == 'active' || b.status == 'reserved').toList();
  List<BookingItem> get history => bookings.where((b) => b.status == 'used' || b.status == 'cancelled' || b.isExpired).toList();
  List<BookingItem> get all => bookings;
  int get activeCount => active.length;

  BookingsState copyWith({
    List<BookingItem>? bookings,
    bool? isLoading,
    String? error,
    bool clearError = false,
    BookingCreateResult? lastCreateResult,
  }) =>
      BookingsState(
        bookings: bookings ?? this.bookings,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        lastCreateResult: lastCreateResult ?? this.lastCreateResult,
      );
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final BookingsService _service;
  BookingsNotifier(this._service) : super(const BookingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _service.getMyBookings();
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// ✅ Crée une réservation et retourne booking + payment info
  Future<BookingCreateResult> createBooking(CreateBookingRequest request) async {
    final result = await _service.create(request);
    state = state.copyWith(
      bookings: [...state.bookings, result.booking],
      lastCreateResult: result,
    );
    return result;
  }

  Future<List<BookingItem>> createBatchBooking(List<CreateBookingRequest> requests) async {
    final bookings = await _service.createBatch(requests);
    state = state.copyWith(bookings: [...state.bookings, ...bookings]);
    return bookings;
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    await _service.cancel(id, reason: reason);
    final updated = state.bookings
        .map((b) => b.id == id ? b.copyWith(status: 'cancelled') : b)
        .toList();
    state = state.copyWith(bookings: updated);
  }
}

final _bookingsServiceProvider = Provider<BookingsService>((_) => BookingsService(dioClient));

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>(
  (ref) => BookingsNotifier(ref.read(_bookingsServiceProvider)),
);
