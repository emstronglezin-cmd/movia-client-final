import 'package:flutter/material.dart';

class CompanyStation {
  final String city;
  final String stationName;
  final String phone;
  const CompanyStation({required this.city, required this.stationName, required this.phone});
}

class Company {
  final String id;
  final String name;
  final String shortName;
  final String color;
  final String? phone;
  final String? email;
  final String? description;
  final List<String>? schedules;
  final List<CompanyStation>? stations;
  final bool supportsReservation;
  final bool requiresImmediatePayment;
  final String? deliveryDays;
  final bool isFeatured;
  final int featuredOrder;
  final int maxBookingDaysAhead;
  const Company({
    required this.id, required this.name, required this.shortName,
    required this.color, this.phone, this.email, this.description,
    this.schedules, this.stations,
    this.supportsReservation = true, this.requiresImmediatePayment = false,
    this.deliveryDays, this.isFeatured = false, this.featuredOrder = 99,
    this.maxBookingDaysAhead = 14,
  });
}

class AppCity {
  final String id;
  final String name;
  final List<String> stations;
  const AppCity({required this.id, required this.name, required this.stations});
}

const List<Company> companies = [
  Company(id: 'saramaya', name: 'Saramaya', shortName: 'Saramaya', color: '#D4380D',
    phone: '+226 25 30 67 89', email: 'contact@saramaya.bf',
    description: 'Compagnie pionnière du transport interurbain au Burkina Faso.',
    schedules: ['6:30','8:30','9:30','10:30','12:30','14:30','18:30','21:30','23:30'],
    deliveryDays: '1-2 jours', isFeatured: true, featuredOrder: 1, maxBookingDaysAhead: 14,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare Saramaya ZAD', phone:'+226 25 30 67 89'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare Saramaya Bobo', phone:'+226 20 97 11 22'),
      CompanyStation(city:'Kaya', stationName:'Gare Saramaya Kaya', phone:'+226 40 45 03 18'),
      CompanyStation(city:'Ouahigouya', stationName:'Gare Saramaya Ouahigouya', phone:'+226 40 55 02 41'),
      CompanyStation(city:'Dédougou', stationName:'Gare Saramaya Dédougou', phone:'+226 20 52 06 37'),
    ]),
  Company(id: 'elitis', name: 'Elitis Transport', shortName: 'Elitis', color: '#C0392B',
    phone: '+226 25 33 44 55', email: 'info@elitis-transport.bf',
    description: 'Service de transport confort avec climatisation et WiFi à bord.',
    schedules: ['6:30','10:30','14:30','16:30','23:00'],
    deliveryDays: '1-2 jours', isFeatured: true, featuredOrder: 2, maxBookingDaysAhead: 28,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare Elitis Wemtenga', phone:'+226 25 33 44 55'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare Elitis Bobo', phone:'+226 20 97 22 33'),
      CompanyStation(city:'Koudougou', stationName:'Gare Elitis Koudougou', phone:'+226 40 44 10 88'),
    ]),
  Company(id: 'tsr', name: 'TSR Voyages', shortName: 'TSR', color: '#2980B9',
    phone: '+226 25 36 12 00', email: 'tsr@transport.bf',
    description: 'Transport sans retard, fiable et accessible sur tous les grands axes.',
    schedules: ['6:00','7:00','8:00','9:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00','18:00'],
    deliveryDays: '1 jour', isFeatured: false, maxBookingDaysAhead: 30,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare TSR Centre', phone:'+226 25 36 12 00'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare TSR Bobo', phone:'+226 20 97 36 00'),
      CompanyStation(city:"Fada N'Gourma", stationName:'Gare TSR Fada', phone:'+226 40 77 05 14'),
    ]),
  Company(id: 'rahimo', name: 'Rahimo Transport', shortName: 'Rahimo', color: '#16A085',
    phone: '+226 25 41 78 90', email: 'rahimo@voyages.bf',
    description: 'Spécialiste du transport de passagers vers le nord du Burkina.',
    schedules: ['7:00','9:00','13:00','16:00','20:00'],
    deliveryDays: '2-3 jours', isFeatured: false, maxBookingDaysAhead: 21,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare Rahimo Ouaga', phone:'+226 25 41 78 90'),
      CompanyStation(city:'Ouahigouya', stationName:'Gare Rahimo Ouahigouya', phone:'+226 40 55 14 02'),
    ]),
  Company(id: 'stmb', name: 'STMB', shortName: 'STMB', color: '#27AE60',
    phone: '+226 25 30 11 22', email: 'stmb@transport.bf',
    description: 'Société de Transport Moderne du Burkina, réseau national étendu.',
    schedules: ['7:00','9:30','13:00','17:00'],
    deliveryDays: '2-4 jours', supportsReservation: false, requiresImmediatePayment: true,
    isFeatured: false, maxBookingDaysAhead: 7,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare STMB Centrale', phone:'+226 25 30 11 22'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare STMB Bobo', phone:'+226 20 97 30 11'),
      CompanyStation(city:'Banfora', stationName:'Gare STMB Banfora', phone:'+226 20 91 01 44'),
    ]),
  Company(id: 'rakieta', name: 'Rakieta Express', shortName: 'Rakieta', color: '#8E44AD',
    phone: '+226 25 45 67 89', email: 'rakieta@express.bf',
    description: 'Service express rapide et ponctuel entre les principales villes.',
    schedules: ['8:30','11:00','14:00','18:00'],
    deliveryDays: '1-2 jours', isFeatured: true, featuredOrder: 3, maxBookingDaysAhead: 21,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare Rakieta Ouaga 2000', phone:'+226 25 45 67 89'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare Rakieta Bobo', phone:'+226 20 97 45 67'),
      CompanyStation(city:'Koudougou', stationName:'Gare Rakieta Koudougou', phone:'+226 40 44 67 89'),
    ]),
  Company(id: 'tcv', name: 'TCV Transport', shortName: 'TCV', color: '#E67E22',
    phone: '+226 25 38 90 01', email: 'tcv@transport.bf',
    description: 'Transport collectif de voyageurs, tarifs compétitifs.',
    schedules: ['7:00','10:00','14:00','19:00'],
    deliveryDays: '3-5 jours', supportsReservation: false, requiresImmediatePayment: true,
    isFeatured: false, maxBookingDaysAhead: 14,
    stations: [
      CompanyStation(city:'Ouagadougou', stationName:'Gare TCV Ouaga', phone:'+226 25 38 90 01'),
      CompanyStation(city:'Bobo Dioulasso', stationName:'Gare TCV Bobo', phone:'+226 20 97 38 90'),
    ]),
];

const List<AppCity> cities = [
  AppCity(id:'ouaga', name:'Ouagadougou', stations:['Gare Saramaya (ZAD)','Gare Elitis (Wemtenga)','Gare TSR (Centre)','Gare de la ZAD','Gare Centrale','Gare de Ouaga 2000']),
  AppCity(id:'bobo', name:'Bobo Dioulasso', stations:['Gare Saramaya Bobo','Gare Elitis Bobo','Gare Secteur 25','Gare Centrale de Bobo','Gare de Kôkô']),
  AppCity(id:'kaya', name:'Kaya', stations:['Gare Saramaya Kaya','Gare Centrale de Kaya','Gare du Centre']),
  AppCity(id:'banfora', name:'Banfora', stations:['Gare de Banfora','Gare Secteur 3']),
  AppCity(id:'dedougou', name:'Dédougou', stations:['Gare Saramaya Dédougou','Gare de Dédougou']),
  AppCity(id:'koudougou', name:'Koudougou', stations:['Gare Centrale de Koudougou','Gare du Marché']),
  AppCity(id:'ouahigouya', name:'Ouahigouya', stations:['Gare Saramaya Ouahigouya','Gare de Ouahigouya','Gare Nord']),
  AppCity(id:'fada', name:"Fada N'Gourma", stations:["Gare de Fada",'Gare TSR Fada']),
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

Company? getCompanyById(String id) {
  try { return companies.firstWhere((c) => c.id == id); } catch (_) { return null; }
}

/// Convertit un hex CSS (#RRGGBB) en Color Flutter
Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  if (h.length == 8) {
    return Color(int.parse(h, radix: 16));
  }
  return const Color(0xFFE74C3C);
}

/// Retourne la couleur (Color) de la compagnie
Color getCompanyColor(String id) => hexToColor(getCompanyById(id)?.color ?? '#E74C3C');

String getCompanyColorHex(String id) => getCompanyById(id)?.color ?? '#E74C3C';
String getCompanyShortName(String id) => getCompanyById(id)?.shortName ?? id.toUpperCase();
String getCompanyFullName(String id) => getCompanyById(id)?.name ?? id;
bool getCompanySupportsReservation(String id) => getCompanyById(id)?.supportsReservation ?? true;

List<String> getCompanyStationsForCity(String companyId, String cityName) {
  final company = getCompanyById(companyId);
  if (company?.stations == null) return [];
  return company!.stations!.where((s) => s.city == cityName).map((s) => s.stationName).toList();
}

String formatPrice(num? price) {
  if (price == null) return '—';
  return price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

int getDaysUntil(String dateStr) {
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parts = dateStr.split('-').map(int.parse).toList();
    final target = DateTime(parts[0], parts[1], parts[2]);
    return target.difference(today).inDays;
  } catch (_) { return 0; }
}
