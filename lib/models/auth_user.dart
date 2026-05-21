import 'dart:convert';

class AuthUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool emailVerified;
  final String? avatarUrl;
  final String? cnib;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.emailVerified = false,
    this.avatarUrl,
    this.cnib,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        emailVerified: json['emailVerified'] == true || json['email_verified'] == true,
        avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
        cnib: json['cnib']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'emailVerified': emailVerified,
        'avatarUrl': avatarUrl,
        'cnib': cnib,
        'createdAt': createdAt?.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory AuthUser.fromJsonString(String s) =>
      AuthUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  AuthUser copyWith({
    String? id, String? name, String? phone, String? email,
    bool? emailVerified, String? avatarUrl, String? cnib, DateTime? createdAt,
  }) => AuthUser(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        emailVerified: emailVerified ?? this.emailVerified,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        cnib: cnib ?? this.cnib,
        createdAt: createdAt ?? this.createdAt,
      );
}
