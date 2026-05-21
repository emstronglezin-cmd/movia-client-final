import '../core/network/dio_client.dart';
import '../models/package_model.dart';

class CreatePackageRequest {
  final String companyId;
  final String from;
  final String to;
  final String fromStation;
  final String toStation;
  final String senderName;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String? recipientCnib;
  final String description;
  final String? weight;
  final double? price;

  const CreatePackageRequest({
    required this.companyId, required this.from, required this.to,
    required this.fromStation, required this.toStation,
    required this.senderName, required this.senderPhone,
    required this.recipientName, required this.recipientPhone,
    this.recipientCnib, required this.description,
    this.weight, this.price,
  });

  Map<String, dynamic> toJson() => {
        'companyId': companyId, 'from': from, 'to': to,
        'fromStation': fromStation, 'toStation': toStation,
        'senderName': senderName, 'senderPhone': senderPhone,
        'recipientName': recipientName, 'recipientPhone': recipientPhone,
        if (recipientCnib != null) 'recipientCnib': recipientCnib,
        'description': description,
        if (weight != null) 'weight': weight,
        if (price != null) 'price': price,
      };
}

class PackagesService {
  final DioClient _client;
  PackagesService([DioClient? client]) : _client = client ?? dioClient;

  Future<PackageItem> create(CreatePackageRequest request) async {
    final data = await _client.post<Map<String, dynamic>>('/packages', data: request.toJson());
    return PackageItem.fromJson(data);
  }

  Future<List<PackageItem>> getMyPackages() async {
    final data = await _client.get<List<dynamic>>('/packages/my');
    return data.map((d) => PackageItem.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<PackageItem> getById(String id) async {
    final data = await _client.get<Map<String, dynamic>>('/packages/$id');
    return PackageItem.fromJson(data);
  }
}
