import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _ticketNotifs = true;
  bool _colisNotifs = true;
  bool _promoNotifs = true;
  bool _infoNotifs = true;
  bool _pushEnabled = true;

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
        title: const Text('Paramètres notifications',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Section(
              title: 'Général',
              children: [
                _Toggle(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications push',
                  subtitle: 'Activer toutes les notifications',
                  value: _pushEnabled,
                  onChanged: (v) => setState(() {
                    _pushEnabled = v;
                    if (!v) { _ticketNotifs = false; _colisNotifs = false; _promoNotifs = false; _infoNotifs = false; }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Types de notifications',
              children: [
                _Toggle(
                  icon: Icons.confirmation_num_rounded,
                  label: 'Tickets & Réservations',
                  subtitle: 'Confirmation, rappels, annulations',
                  value: _ticketNotifs && _pushEnabled,
                  onChanged: _pushEnabled ? (v) => setState(() => _ticketNotifs = v) : null,
                ),
                _Toggle(
                  icon: Icons.inventory_2_rounded,
                  label: 'Suivi de colis',
                  subtitle: 'Mises à jour de statut des colis',
                  value: _colisNotifs && _pushEnabled,
                  onChanged: _pushEnabled ? (v) => setState(() => _colisNotifs = v) : null,
                ),
                _Toggle(
                  icon: Icons.local_offer_rounded,
                  label: 'Promotions & Offres',
                  subtitle: 'Réductions et offres spéciales',
                  value: _promoNotifs && _pushEnabled,
                  onChanged: _pushEnabled ? (v) => setState(() => _promoNotifs = v) : null,
                ),
                _Toggle(
                  icon: Icons.info_rounded,
                  label: 'Informations',
                  subtitle: 'Actualités et mises à jour Movia',
                  value: _infoNotifs && _pushEnabled,
                  onChanged: _pushEnabled ? (v) => setState(() => _infoNotifs = v) : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Préférences sauvegardées !'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sauvegarder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: List.generate(children.length, (i) => Column(
              children: [
                children[i],
                if (i < children.length - 1) const Divider(height: 1, indent: 54),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _Toggle({required this.icon, required this.label, this.subtitle, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryRed.withValues(alpha: 0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: value ? AppColors.primaryRed : Colors.grey[400], size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onChanged != null ? AppColors.textPrimary : AppColors.textTertiary)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryRed,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
