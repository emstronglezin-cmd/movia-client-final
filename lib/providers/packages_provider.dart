import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/package_model.dart';
import '../services/packages_service.dart';

class PackagesState {
  final List<PackageItem> packages;
  final bool isLoading;
  final String? error;

  const PackagesState({this.packages = const [], this.isLoading = false, this.error});

  List<PackageItem> get enCours => packages.where((p) => p.status == 'en_cours').toList();
  List<PackageItem> get livres => packages.where((p) => p.status == 'livre').toList();
  List<PackageItem> get annules => packages.where((p) => p.status == 'annule').toList();
  List<PackageItem> get all => packages;
  int get activeCount => enCours.length;

  PackagesState copyWith({List<PackageItem>? packages, bool? isLoading, String? error, bool clearError = false}) =>
      PackagesState(packages: packages ?? this.packages, isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error);
}

class PackagesNotifier extends StateNotifier<PackagesState> {
  final PackagesService _service;
  PackagesNotifier(this._service) : super(const PackagesState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final packages = await _service.getMyPackages();
      state = state.copyWith(packages: packages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<PackageItem> create(CreatePackageRequest request) async {
    final pkg = await _service.create(request);
    state = state.copyWith(packages: [...state.packages, pkg]);
    return pkg;
  }
}

final _packagesServiceProvider = Provider<PackagesService>((_) => PackagesService(dioClient));

final packagesProvider = StateNotifierProvider<PackagesNotifier, PackagesState>(
  (ref) => PackagesNotifier(ref.read(_packagesServiceProvider)),
);
