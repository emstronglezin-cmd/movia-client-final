import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Méthodes de paiement',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Opérateurs disponibles',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _PaymentCard(
              icon: '🟠',
              name: 'Orange Money',
              description: 'Paiement mobile Orange Burkina Faso',
              color: const Color(0xFFFF6600),
              isDefault: true,
            ),
            const SizedBox(height: 10),
            _PaymentCard(
              icon: '🔵',
              name: 'Moov Money',
              description: 'Paiement mobile Moov Africa Burkina',
              color: const Color(0xFF005BAC),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFF0284C7), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vos paiements sont sécurisés. Aucune information bancaire n\'est stockée sur nos serveurs.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String icon, name, description;
  final Color color;
  final bool isDefault;
  const _PaymentCard({
    required this.icon, required this.name, required this.description,
    required this.color, this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault ? Border.all(color: AppColors.primaryRed, width: 2) : null,
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: const Text('Par défaut', style: TextStyle(color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.w600)),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
      ),
    );
  }
}
