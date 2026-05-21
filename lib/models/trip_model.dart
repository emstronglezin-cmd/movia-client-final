class TripResult {
  final String id;
  final String companyId;
  final String companyName;
  final String companyShortName;
  final String from;
  final String to;
  final String fromStation;
  final String toStation;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;
  final int seatsAvailable;
  final int totalSeats;
  final String date;
  final bool supportsReservation;
  final bool requiresImmediatePayment;
  final String? priceLabel; // bon_prix, normal, eleve
  final String? demandLevel; // faible, modérée, forte
  final List<String>? groupStations;

  const TripResult({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyShortName,
    required this.from,
    required this.to,
    required this.fromStation,
    required this.toStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.seatsAvailable,
    required this.totalSeats,
    required this.date,
    this.supportsReservation = true,
    this.requiresImmediatePayment = false,
    this.priceLabel,
    this.demandLevel,
    this.groupStations,
  });

  factory TripResult.fromJson(Map<String, dynamic> json) => TripResult(
        id: json['id']?.toString() ?? '',
        companyId: json['companyId']?.toString() ?? json['company_id']?.toString() ?? '',
        companyName: json['companyName']?.toString() ?? json['company_name']?.toString() ?? '',
        companyShortName: json['companyShortName']?.toString() ?? json['company_short_name']?.toString() ?? '',
        from: json['from']?.toString() ?? '',
        to: json['to']?.toString() ?? '',
        fromStation: json['fromStation']?.toString() ?? json['from_station']?.toString() ?? '',
        toStation: json['toStation']?.toString() ?? json['to_station']?.toString() ?? '',
        departureTime: json['departureTime']?.toString() ?? json['departure_time']?.toString() ?? '',
        arrivalTime: json['arrivalTime']?.toString() ?? json['arrival_time']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        seatsAvailable: (json['seatsAvailable'] ?? json['seats_available'] ?? 0) as int,
        totalSeats: (json['totalSeats'] ?? json['total_seats'] ?? 0) as int,
        date: json['date']?.toString() ?? '',
        supportsReservation: json['supportsReservation'] != false && json['supports_reservation'] != false,
        requiresImmediatePayment: json['requiresImmediatePayment'] == true || json['requires_immediate_payment'] == true,
        priceLabel: json['priceLabel']?.toString() ?? json['price_label']?.toString(),
        demandLevel: json['demandLevel']?.toString() ?? json['demand_level']?.toString(),
        groupStations: (json['groupStations'] as List<dynamic>?)?.map((s) => s.toString()).toList(),
      );
}

class SeatInfo {
  final int number;
  final bool isAvailable;
  final bool isSelected;

  const SeatInfo({required this.number, required this.isAvailable, this.isSelected = false});
  SeatInfo copyWith({bool? isSelected}) => SeatInfo(
        number: number, isAvailable: isAvailable, isSelected: isSelected ?? this.isSelected);
}
