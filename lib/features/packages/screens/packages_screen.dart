import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/packages_provider.dart';
import '../../../models/package_model.dart';
import '../../../shared/constants/app_data.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await ref.read(packagesProvider.notifier).load();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Colis',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.primaryRed),
            onPressed: () => context.push('/send-package'),
            tooltip: 'Envoyer un colis',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryRed,
          indicatorWeight: 3,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'En cours (${state.enCours.length})'),
            Tab(text: 'Livrés (${state.livres.length})'),
            Tab(text: 'Annulés (${state.annules.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed))
          : TabBarView(
              controller: _tabController,
              children: [
                _PackageList(
                    packages: state.enCours,
                    emptyMessage: 'Aucun colis en cours',
                    emptyIcon: '📦',
                    onSend: () => context.push('/send-package')),
                _PackageList(
                    packages: state.livres,
                    emptyMessage: 'Aucun colis livré',
                    emptyIcon: '✅'),
                _PackageList(
                    packages: state.annules,
                    emptyMessage: 'Aucun colis annulé',
                    emptyIcon: '❌'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/send-package'),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Envoyer un colis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PackageList extends StatelessWidget {
  final List<PackageItem> packages;
  final String emptyMessage;
  final String emptyIcon;
  final VoidCallback? onSend;

  const _PackageList({
    required this.packages,
    required this.emptyMessage,
    required this.emptyIcon,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return _EmptyState(
          message: emptyMessage, icon: emptyIcon, onSend: onSend);
    }
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async =>
          context.findAncestorStateOfType<_PackagesScreenState>()!._load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (_, i) => _PackageCard(package: packages[i]),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PackageItem package;
  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(package.status);
    final statusLabel = _statusLabel(package.status);
    final progress = _statusProgress(package.status);

    return GestureDetector(
      onTap: () =>
          context.push('/package-detail', extra: {'packageId': package.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text('📦',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Réf: ${package.reference}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RouteInfo(
                          label: 'De',
                          city: package.from,
                          station: package.fromStation,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textTertiary, size: 18),
                      Expanded(
                        child: _RouteInfo(
                          label: 'À',
                          city: package.to,
                          station: package.toStation,
                          align: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${package.senderName} → ${package.recipientName}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '${formatPrice(package.price.toInt())} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return const Color(0xFF2563EB);
      case 'livre':
        return const Color(0xFF059669);
      case 'annule':
        return AppColors.primaryRed;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'en_cours':
        return 'En cours';
      case 'livre':
        return 'Livré';
      case 'annule':
        return 'Annulé';
      default:
        return status;
    }
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'en_cours':
        return 0.5;
      case 'livre':
        return 1.0;
      default:
        return 0.0;
    }
  }
}

class _RouteInfo extends StatelessWidget {
  final String label;
  final String city;
  final String? station;
  final CrossAxisAlignment align;

  const _RouteInfo({
    required this.label,
    required this.city,
    this.station,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textTertiary)),
        Text(city,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary)),
        if (station != null)
          Text(station!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String icon;
  final VoidCallback? onSend;

  const _EmptyState(
      {required this.message, required this.icon, this.onSend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            if (onSend != null) ...[
              const SizedBox(height: 8),
              const Text('Envoyez votre premier colis facilement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Envoyer un colis',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
