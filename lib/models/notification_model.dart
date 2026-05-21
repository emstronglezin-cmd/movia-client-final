class AppNotification {
  final String id;
  final String type; // ticket, colis, info, promo
  final String title;
  final String message;
  final bool read;
  final String? linkTo;
  final Map<String, String>? linkParams;
  final String time;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.linkTo,
    this.linkParams,
    required this.time,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, String>? params;
    if (json['linkParams'] != null) {
      params = Map<String, String>.from(
        (json['linkParams'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      linkTo: json['linkTo']?.toString(),
      linkParams: params,
      time: json['time']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type, 'title': title, 'message': message,
        'read': read, 'linkTo': linkTo, 'linkParams': linkParams,
        'time': time, 'createdAt': createdAt.toIso8601String(),
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id, type: type, title: title, message: message,
        read: read ?? this.read, linkTo: linkTo, linkParams: linkParams,
        time: time, createdAt: createdAt,
      );
}
