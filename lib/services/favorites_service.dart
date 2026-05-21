import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loyalty_model.dart';
import '../core/config/app_config.dart';

class FavoritesService {
  Future<List<FavoriteRoute>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConfig.favoritesKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => FavoriteRoute.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<FavoriteRoute> add({
    required String from,
    required String to,
    required String fromStation,
    required String toStation,
    String? label,
  }) async {
    final favorites = await getAll();
    final exists = favorites.where((f) => f.from == from && f.to == to).firstOrNull;
    if (exists != null) return exists;

    final newFav = FavoriteRoute(
      id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
      from: from,
      to: to,
      fromStation: fromStation,
      toStation: toStation,
      label: label,
      savedAt: DateTime.now(),
    );

    final updated = [...favorites, newFav];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.favoritesKey, jsonEncode(updated.map((f) => f.toJson()).toList()));
    return newFav;
  }

  Future<void> remove(String id) async {
    final favorites = await getAll();
    final updated = favorites.where((f) => f.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.favoritesKey, jsonEncode(updated.map((f) => f.toJson()).toList()));
  }

  Future<bool> isFavorite(String from, String to) async {
    final favorites = await getAll();
    return favorites.any((f) => f.from == from && f.to == to);
  }
}
