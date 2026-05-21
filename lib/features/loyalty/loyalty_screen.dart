import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/loyalty_service.dart';
import '../../models/loyalty_model.dart';

// ─── Provider simple ─────────────────────────────────────────────────────────

final loyaltyProvider = FutureProvider<LoyaltyAccount>((ref) async {
  return LoyaltyService().getMyLoyalty();
});

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  bool _showRedeemModal = false;
  final _redeemController = TextEditingController();
  bool _isRedeeming = false;

  static const Map<String, Color> _levelColors = {
    'bronze': Color(0xFFB45309),
    'silver': Color(0xFF6B7280),
    'gold': Color(0xFFD97706),
    'platinum': Color(0xFF7C3AED),
  };

  static const Map<String, String> _levelIcons = {
    'bronze': '🥉',
    'silver': '🥈',
    'gold': '🥇',
    'platinum': '💎',
  };

  static const Map<String, int> _levelThresholds = {
    'bronze': 0,
    'silver': 1000,
    'gold': 5000,
    'platinum': 15000,
  };

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyAsync = ref.watch(loyaltyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Programme fidélité',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: loyaltyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (_, __) => _MockLoyaltyBody(
          showRedeemModal: _showRedeemModal,
          redeemController: _redeemController,
          isRedeeming: _isRedeeming,
          onShowRedeem: () => setState(() => _showRedeemModal = true),
          onCloseRedeem: () => setState(() { _showRedeemModal = false; _redeemController.clear(); }),
          onRedeem: _redeem,
          levelColors: _levelColors,
          levelIcons: _levelIcons,
          levelThresholds: _levelThresholds,
        ),
        data: (account) => Stack(
          children: [
            _LoyaltyBody(
              account: account,
              levelColors: _levelColors,
              levelIcons: _levelIcons,
              levelThresholds: _levelThresholds,
              onShowRedeem: () => setState(() => _showRedeemModal = true),
            ),
            if (_showRedeemModal)
              _RedeemModal(
                maxPoints: account.points,
                controller: _redeemController,
                isRedeeming: _isRedeeming,
                onClose: () => setState(() { _showRedeemModal = false; _redeemController.clear(); }),
                onRedeem: _redeem,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem() async {
    final pts = int.tryParse(_redeemController.text) ?? 0;
    if (pts <= 0) return;
    setState(() => _isRedeeming = true);
    try {
      await LoyaltyService().redeemPoints(pts);
      ref.invalidate(loyaltyProvider);
      if (mounted) {
        setState(() { _isRedeeming = false; _showRedeemModal = false; _redeemController.clear(); });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pts * 10} FCFA de réduction appliqués !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedeeming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du rachat. Réessayez.')),
        );
      }
    }
  }
}

// ─── Loyalty Body ────────────────────────────────────────────────────────────

class _LoyaltyBody extends StatelessWidget {
  final LoyaltyAccount account;
  final Map<String, Color> levelColors;
  final Map<String, String> levelIcons;
  final Map<String, int> levelThresholds;
  final VoidCallback onShowRedeem;
  const _LoyaltyBody({
    required this.account, required this.levelColors, required this.levelIcons,
    required this.levelThresholds, required this.onShowRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final color = levelColors[account.level] ?? AppColors.primaryRed;
    final icon = levelIcons[account.level] ?? '🥉';
    final progress = account.progressToNext;
    final nextLevel = account.nextLevelAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 48)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Niveau ${account.level.toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1)),
                          Text('${account.points} points',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          Text('≈ ${account.points * 10} FCFA de valeur',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (account.points >= 100)
                      ElevatedButton(
                        onPressed: onShowRedeem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text('Utiliser', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (nextLevel != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prochain niveau', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      Text('$nextLevel pts', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 7,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conversion card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conversion des points', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('1 point = 10 FCFA de réduction sur vos prochains billets',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Levels card
          _LevelsCard(levelColors: levelColors, levelIcons: levelIcons, levelThresholds: levelThresholds, currentLevel: account.level),
          const SizedBox(height: 20),

          // Transactions
          if (account.transactions.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Historique des points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),
            ...account.transactions.map((t) => _TransactionTile(tx: t)),
          ],
        ],
      ),
    );
  }
}

class _LevelsCard extends StatelessWidget {
  final Map<String, Color> levelColors;
  final Map<String, String> levelIcons;
  final Map<String, int> levelThresholds;
  final String currentLevel;
  const _LevelsCard({required this.levelColors, required this.levelIcons, required this.levelThresholds, required this.currentLevel});

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
            child: Text('Niveaux de fidélité', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          ...['bronze', 'silver', 'gold', 'platinum'].map((level) {
            final isActive = level == currentLevel;
            final color = levelColors[level]!;
            final icon = levelIcons[level]!;
            final threshold = levelThresholds[level]!;
            return ListTile(
              leading: Text(icon, style: const TextStyle(fontSize: 24)),
              title: Text(level.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                      color: isActive ? color : AppColors.textSecondary)),
              subtitle: Text('À partir de $threshold points',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              trailing: isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('Actuel', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final LoyaltyTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.remove_rounded,
              color: isPositive ? const Color(0xFF166534) : AppColors.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${tx.points} pts',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: isPositive ? const Color(0xFF166534) : AppColors.primaryRed),
          ),
        ],
      ),
    );
  }
}

// ─── Redeem Modal ─────────────────────────────────────────────────────────────

class _RedeemModal extends StatelessWidget {
  final int maxPoints;
  final TextEditingController controller;
  final bool isRedeeming;
  final VoidCallback onClose, onRedeem;
  const _RedeemModal({required this.maxPoints, required this.controller, required this.isRedeeming, required this.onClose, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Utiliser mes points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Vous avez $maxPoints points disponibles (= ${maxPoints * 10} FCFA)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nombre de points',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixText: 'pts',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => controller.text = '$maxPoints',
                    child: const Text('Max', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: onClose, child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isRedeeming ? null : onRedeem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isRedeeming
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmer', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mock body (fallback offline) ────────────────────────────────────────────

class _MockLoyaltyBody extends StatelessWidget {
  final bool showRedeemModal;
  final TextEditingController redeemController;
  final bool isRedeeming;
  final VoidCallback onShowRedeem, onCloseRedeem, onRedeem;
  final Map<String, Color> levelColors;
  final Map<String, String> levelIcons;
  final Map<String, int> levelThresholds;
  const _MockLoyaltyBody({
    required this.showRedeemModal, required this.redeemController,
    required this.isRedeeming, required this.onShowRedeem,
    required this.onCloseRedeem, required this.onRedeem,
    required this.levelColors, required this.levelIcons, required this.levelThresholds,
  });

  @override
  Widget build(BuildContext context) {
    final mockAccount = LoyaltyAccount(
      points: 0, totalEarned: 0, level: 'bronze', levelLabel: 'Bronze',
      progressToNext: 0.0, nextLevelAt: 1000,
      fcfaPerPoint: 10.0, minRedeemPoints: 100,
      transactions: [],
    );
    return Stack(
      children: [
        _LoyaltyBody(
          account: mockAccount, levelColors: levelColors,
          levelIcons: levelIcons, levelThresholds: levelThresholds,
          onShowRedeem: onShowRedeem,
        ),
        if (showRedeemModal)
          _RedeemModal(
            maxPoints: mockAccount.points, controller: redeemController,
            isRedeeming: isRedeeming, onClose: onCloseRedeem, onRedeem: onRedeem,
          ),
      ],
    );
  }
}
