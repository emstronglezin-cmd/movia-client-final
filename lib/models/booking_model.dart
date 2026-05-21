class BookingItem {
  final String id;
  final String tripId;
  final String companyId;
  final String companyName;
  final String companyShortName;
  final String passengerName;
  final String passengerPhone;
  final String? passengerCnib;
  final String from;
  final String to;
  final String fromStation;
  final String toStation;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final int seatNumber;
  final double price;
  final String status; // active, reserved, used, cancelled
  final String bookingReference;
  final bool isRoundTrip;
  final String? returnDate;
  final String? returnDepartureTime;
  final String? returnArrivalTime;
  final int? returnSeatNumber;
  final double? baggageWeight;
  final String? paymentMethod;   // orange_money, moov_money
  final String? paymentProvider; // alias de paymentMethod
  final String? paymentStatus;   // paid, pending, failed
  final String? bookingMode;     // pay_now, reserve_only
  final DateTime? createdAt;

  const BookingItem({
    required this.id,
    required this.tripId,
    required this.companyId,
    required this.companyName,
    required this.companyShortName,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerCnib,
    required this.from,
    required this.to,
    required this.fromStation,
    required this.toStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    required this.seatNumber,
    required this.price,
    required this.status,
    required this.bookingReference,
    this.isRoundTrip = false,
    this.returnDate,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.returnSeatNumber,
    this.baggageWeight,
    this.paymentMethod,
    this.paymentProvider,
    this.paymentStatus,
    this.bookingMode,
    this.createdAt,
  });

  // ─── Computed getters ─────────────────────────────────────────────────────

  bool get isActive   => status == 'active';
  bool get isReserved => status == 'reserved';
  bool get isCancelled => status == 'cancelled';
  bool get isUsed     => status == 'used';

  /// Alias utilisé par les écrans: date du voyage
  String get travelDate => date;

  /// Alias gare départ
  String get departureStation => fromStation;

  /// Alias gare arrivée
  String get arrivalStation => toStation;

  /// Prix total (pour compatibilité screens: peut inclure aller-retour)
  double get totalPrice => price;

  bool get isExpired {
    if (status != 'active' && status != 'reserved') return false;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return date.compareTo(todayStr) < 0;
  }

  factory BookingItem.fromJson(Map<String, dynamic> json) => BookingItem(
        id: json['id']?.toString() ?? '',
        tripId: json['tripId']?.toString() ?? json['trip_id']?.toString() ?? '',
        companyId: json['companyId']?.toString() ?? json['company_id']?.toString() ?? '',
        companyName: json['companyName']?.toString() ?? json['company_name']?.toString() ?? '',
        companyShortName: json['companyShortName']?.toString() ?? json['company_short_name']?.toString() ?? '',
        passengerName: json['passengerName']?.toString() ?? json['passenger_name']?.toString() ?? '',
        passengerPhone: json['passengerPhone']?.toString() ?? json['passenger_phone']?.toString() ?? '',
        passengerCnib: json['passengerCnib']?.toString() ?? json['passenger_cnib']?.toString(),
        from: json['from']?.toString() ?? '',
        to: json['to']?.toString() ?? '',
        fromStation: json['fromStation']?.toString() ?? json['from_station']?.toString() ?? '',
        toStation: json['toStation']?.toString() ?? json['to_station']?.toString() ?? '',
        departureTime: json['departureTime']?.toString() ?? json['departure_time']?.toString() ?? '',
        arrivalTime: json['arrivalTime']?.toString() ?? json['arrival_time']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        seatNumber: (json['seatNumber'] ?? json['seat_number'] ?? 0) as int,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'active',
        bookingReference: json['bookingReference']?.toString() ?? json['booking_reference']?.toString() ?? '',
        isRoundTrip: json['isRoundTrip'] == true || json['is_round_trip'] == true,
        returnDate: json['returnDate']?.toString() ?? json['return_date']?.toString(),
        returnDepartureTime: json['returnDepartureTime']?.toString() ?? json['return_departure_time']?.toString(),
        returnArrivalTime: json['returnArrivalTime']?.toString() ?? json['return_arrival_time']?.toString(),
        returnSeatNumber: json['returnSeatNumber'] as int? ?? json['return_seat_number'] as int?,
        baggageWeight: (json['baggageWeight'] as num?)?.toDouble() ?? (json['baggage_weight'] as num?)?.toDouble(),
        paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
        paymentProvider: json['paymentProvider']?.toString() ?? json['payment_provider']?.toString()
            ?? json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
        paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString(),
        bookingMode: json['bookingMode']?.toString() ?? json['booking_mode']?.toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'tripId': tripId, 'companyId': companyId,
        'companyName': companyName, 'companyShortName': companyShortName,
        'passengerName': passengerName, 'passengerPhone': passengerPhone,
        'passengerCnib': passengerCnib, 'from': from, 'to': to,
        'fromStation': fromStation, 'toStation': toStation,
        'departureTime': departureTime, 'arrivalTime': arrivalTime,
        'date': date, 'seatNumber': seatNumber, 'price': price,
        'status': status, 'bookingReference': bookingReference,
        'isRoundTrip': isRoundTrip, 'returnDate': returnDate,
        'returnDepartureTime': returnDepartureTime, 'returnArrivalTime': returnArrivalTime,
        'returnSeatNumber': returnSeatNumber, 'baggageWeight': baggageWeight,
        'paymentMethod': paymentMethod, 'paymentProvider': paymentProvider,
        'paymentStatus': paymentStatus, 'bookingMode': bookingMode,
      };

  BookingItem copyWith({String? status, String? paymentStatus}) => BookingItem(
        id: id, tripId: tripId, companyId: companyId,
        companyName: companyName, companyShortName: companyShortName,
        passengerName: passengerName, passengerPhone: passengerPhone,
        passengerCnib: passengerCnib, from: from, to: to,
        fromStation: fromStation, toStation: toStation,
        departureTime: departureTime, arrivalTime: arrivalTime,
        date: date, seatNumber: seatNumber, price: price,
        status: status ?? this.status, bookingReference: bookingReference,
        isRoundTrip: isRoundTrip, returnDate: returnDate,
        returnDepartureTime: returnDepartureTime, returnArrivalTime: returnArrivalTime,
        returnSeatNumber: returnSeatNumber, baggageWeight: baggageWeight,
        paymentMethod: paymentMethod, paymentProvider: paymentProvider,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        bookingMode: bookingMode, createdAt: createdAt,
      );
}
