import '../core/network/dio_client.dart';
import '../models/trip_model.dart';

class TripSearchParams {
  final String from;
  final String to;
  final String date;
  final int passengers;
  final String? departureAfter;
  final String? companyId;
  final bool isRoundTrip;
  final String? returnDate;

  const TripSearchParams({
    required this.from, required this.to, required this.date,
    this.passengers = 1, this.departureAfter, this.companyId,
    this.isRoundTrip = false, this.returnDate,
  });

  Map<String, dynamic> toQueryParams() => {
        'from': from, 'to': to, 'date': date, 'passengers': passengers,
        if (departureAfter != null) 'departureAfter': departureAfter,
        if (companyId != null) 'companyId': companyId,
      };
}

class TripsService {
  final DioClient _client;
  TripsService([DioClient? client]) : _client = client ?? dioClient;

  Future<List<TripResult>> search(TripSearchParams params) async {
    final data = await _client.get<List<dynamic>>(
      '/trips/search',
      params: params.toQueryParams(),
    );
    return data.map((d) => TripResult.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<TripResult> getById(String id) async {
    final data = await _client.get<Map<String, dynamic>>('/trips/$id');
    return TripResult.fromJson(data);
  }

  Future<Map<String, dynamic>> getSeats(String tripId) async {
    return await _client.get<Map<String, dynamic>>('/trips/$tripId/seats');
  }
}
