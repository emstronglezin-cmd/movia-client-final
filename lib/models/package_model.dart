class PackageStep {
  final int id;
  final String label;
  final String? date;
  final String? description;
  final String? time;
  final bool completed;
  final bool active;
  final int order;

  const PackageStep({
    required this.id,
    required this.label,
    this.date,
    this.description,
    this.time,
    required this.completed,
    required this.active,
    required this.order,
  });

  /// Alias status pour compatibilité écrans
  String get status => completed ? 'completed' : (active ? 'active' : 'pending');

  factory PackageStep.fromJson(Map<String, dynamic> json) => PackageStep(
        id: (json['id'] as num?)?.toInt() ?? 0,
        label: json['label']?.toString() ?? '',
        date: json['date']?.toString(),
        description: json['description']?.toString(),
        time: json['time']?.toString() ?? json['date']?.toString(),
        completed: json['completed'] == true || json['status'] == 'completed',
        active: json['active'] == true || json['status'] == 'active',
        order: (json['order'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      );
}

class PackageCompany {
  final String id;
  final String name;
  const PackageCompany({required this.id, required this.name});
  factory PackageCompany.fromJson(Map<String, dynamic> json) =>
      PackageCompany(id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
}

class PackageItem {
  final String id;
  final String reference;
  final String companyId;
  final PackageCompany company;
  final String from;
  final String to;
  final String? fromStation;
  final String? toStation;
  final String senderName;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String? description;
  final String? weight;
  final double price;
  final String status; // en_cours, livre, annule
  final List<PackageStep> steps;
  final String date;

  const PackageItem({
    required this.id,
    required this.reference,
    required this.companyId,
    required this.company,
    required this.from,
    required this.to,
    this.fromStation,
    this.toStation,
    required this.senderName,
    required this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    this.description,
    this.weight,
    required this.price,
    required this.status,
    required this.steps,
    required this.date,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) => PackageItem(
        id: json['id']?.toString() ?? '',
        reference: json['reference']?.toString() ?? '',
        companyId: json['companyId']?.toString() ?? json['company_id']?.toString() ?? '',
        company: json['company'] != null
            ? PackageCompany.fromJson(json['company'] as Map<String, dynamic>)
            : PackageCompany(
                id: json['companyId']?.toString() ?? '',
                name: json['companyName']?.toString() ?? '',
              ),
        from: json['from']?.toString() ?? '',
        to: json['to']?.toString() ?? '',
        fromStation: json['fromStation']?.toString() ?? json['from_station']?.toString(),
        toStation: json['toStation']?.toString() ?? json['to_station']?.toString(),
        senderName: json['senderName']?.toString() ?? json['sender_name']?.toString() ?? '',
        senderPhone: json['senderPhone']?.toString() ?? json['sender_phone']?.toString() ?? '',
        recipientName: json['recipientName']?.toString() ?? json['recipient_name']?.toString() ?? '',
        recipientPhone: json['recipientPhone']?.toString() ?? json['recipient_phone']?.toString() ?? '',
        description: json['description']?.toString(),
        weight: json['weight']?.toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'en_cours',
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((s) => PackageStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        date: json['date']?.toString() ?? '',
      );
}
