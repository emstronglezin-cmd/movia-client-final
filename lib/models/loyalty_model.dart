class LoyaltyTransaction {
  final String id;
  final String type; // earn, redeem, bonus
  final int points;
  final String description;
  final String? bookingId;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id, required this.type, required this.points,
    required this.description, this.bookingId, required this.createdAt,
  });

  /// Alias pour compatibilité écrans
  DateTime get date => createdAt;

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'earn',
        points: (json['points'] as num?)?.toInt() ?? 0,
        description: json['description']?.toString() ?? '',
        bookingId: json['bookingId']?.toString() ?? json['booking_id']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class LoyaltyAccount {
  final int points;
  final int totalEarned;
  final String level; // bronze, silver, gold, platinum
  final String levelLabel;
  final int? nextLevelAt;
  final double progressToNext;
  final double fcfaPerPoint;
  final int minRedeemPoints;
  final List<LoyaltyTransaction> transactions;

  const LoyaltyAccount({
    required this.points,
    required this.totalEarned,
    required this.level,
    required this.levelLabel,
    this.nextLevelAt,
    required this.progressToNext,
    required this.fcfaPerPoint,
    required this.minRedeemPoints,
    required this.transactions,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
        points: (json['points'] as num?)?.toInt() ?? 0,
        totalEarned: (json['totalEarned'] ?? json['total_earned'] as num?)?.toInt() ?? 0,
        level: json['level']?.toString() ?? 'bronze',
        levelLabel: json['levelLabel']?.toString() ?? json['level_label']?.toString() ?? 'Bronze',
        nextLevelAt: (json['nextLevelAt'] ?? json['next_level_at'] as num?)?.toInt(),
        progressToNext: (json['progressToNext'] ?? json['progress_to_next'] as num?)?.toDouble() ?? 0.0,
        fcfaPerPoint: (json['fcfaPerPoint'] ?? json['fcfa_per_point'] as num?)?.toDouble() ?? 10.0,
        minRedeemPoints: (json['minRedeemPoints'] ?? json['min_redeem_points'] as num?)?.toInt() ?? 100,
        transactions: (json['transactions'] as List<dynamic>? ?? [])
            .map((t) => LoyaltyTransaction.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class FavoriteRoute {
  final String id;
  final String from;
  final String to;
  final String fromStation;
  final String toStation;
  final String? label;
  final DateTime savedAt;

  const FavoriteRoute({
    required this.id,
    required this.from,
    required this.to,
    this.fromStation = '',
    this.toStation = '',
    this.label,
    required this.savedAt,
  });

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) => FavoriteRoute(
        id: json['id']?.toString() ?? '',
        from: json['from']?.toString() ?? '',
        to: json['to']?.toString() ?? '',
        fromStation: json['fromStation']?.toString() ?? '',
        toStation: json['toStation']?.toString() ?? '',
        label: json['label']?.toString(),
        savedAt: json['savedAt'] != null
            ? DateTime.tryParse(json['savedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'from': from, 'to': to, 'fromStation': fromStation,
        'toStation': toStation, 'label': label,
        'savedAt': savedAt.toIso8601String(),
      };
}
