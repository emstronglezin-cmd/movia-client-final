import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/packages_provider.dart';
import '../../../models/package_model.dart';
import '../../../shared/constants/app_data.dart';

class PackageDetailScreen extends ConsumerWidget {
  final String packageId;
  const PackageDetailScreen({super.key, required this.packageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packagesProvider);
    PackageItem? package;
    try {
      package = state.all.firstWhere((p) => p.id == packageId);
    } catch (_) {}

    if (package == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Suivi colis',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Reference card
            _RefCard(package: package),
            const SizedBox(height: 16),

            // Tracking timeline
            _TrackingTimeline(steps: package.steps),
            const SizedBox(height: 16),

            // Sender info
            _InfoCard(
              title: 'Expéditeur',
              icon: '📤',
              children: [
                _InfoRow(label: 'Nom', value: package.senderName),
                _InfoRow(label: 'Téléphone', value: package.senderPhone),
                _InfoRow(label: 'Ville', value: package.from),
                _InfoRow(label: 'Gare', value: package.fromStation ?? ''),
              ],
            ),
            const SizedBox(height: 16),

            // Recipient info
            _InfoCard(
              title: 'Destinataire',
              icon: '📥',
              children: [
                _InfoRow(label: 'Nom', value: package.recipientName),
                _InfoRow(label: 'Téléphone', value: package.recipientPhone),
                _InfoRow(label: 'Ville', value: package.to),
                _InfoRow(label: 'Gare', value: package.toStation ?? ''),
              ],
            ),
            const SizedBox(height: 16),

            // Package info
            _InfoCard(
              title: 'Informations du colis',
              icon: '📦',
              children: [
                _InfoRow(label: 'Description', value: package.description ?? 'N/A'),
                _InfoRow(label: 'Poids', value: package.weight != null ? '${package.weight} kg' : 'N/A'),
                _InfoRow(label: 'Prix', value: '${formatPrice(package.price.toInt())} FCFA'),
                _InfoRow(label: 'Compagnie', value: getCompanyFullName(package.companyId)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  final PackageItem package;
  const _RefCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final statusColor = package.status == 'livre'
        ? const Color(0xFF059669)
        : package.status == 'annule'
            ? AppColors.primaryRed
            : const Color(0xFF2563EB);
    final statusLabel = package.status == 'livre' ? 'Livré' : package.status == 'annule' ? 'Annulé' : 'En cours';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Référence colis', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(package.reference,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('De', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(package.from, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('À', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(package.to, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), textAlign: TextAlign.end),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  final List<PackageStep> steps;
  const _TrackingTimeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Suivi en temps réel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: steps.isEmpty
                ? const Text('Aucune mise à jour disponible',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                : Column(
                    children: List.generate(steps.length, (i) {
                      final step = steps[i];
                      final isLast = i == steps.length - 1;
                      final isCompleted = step.status == 'completed';
                      final isActive = step.status == 'active';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.primaryRed
                                      : isActive
                                          ? AppColors.primaryRed.withValues(alpha: 0.15)
                                          : Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: isActive
                                      ? Border.all(color: AppColors.primaryRed, width: 2)
                                      : null,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                      : isActive
                                          ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle))
                                          : Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2, height: 40,
                                  color: isCompleted ? AppColors.primaryRed.withValues(alpha: 0.3) : Colors.grey[200],
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textTertiary,
                                      )),
                                  if (step.description != null)
                                    Text(step.description!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (step.time != null)
                                    Text(step.time!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, icon;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
