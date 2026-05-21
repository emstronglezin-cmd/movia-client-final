import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _darkMode = false;
  bool _biometrics = false;
  bool _autoRefresh = true;
  String _currency = 'FCFA';
  String _defaultPayment = 'orange_money';

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
        title: const Text('Préférences',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PrefSection(
              title: 'Apparence',
              children: [
                _PrefToggle(
                  icon: Icons.dark_mode_rounded,
                  label: 'Mode sombre',
                  subtitle: 'Thème foncé pour l\'interface',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PrefSection(
              title: 'Sécurité',
              children: [
                _PrefToggle(
                  icon: Icons.fingerprint_rounded,
                  label: 'Authentification biométrique',
                  subtitle: 'Déverrouillez l\'app avec votre empreinte',
                  value: _biometrics,
                  onChanged: (v) => setState(() => _biometrics = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PrefSection(
              title: 'Application',
              children: [
                _PrefToggle(
                  icon: Icons.refresh_rounded,
                  label: 'Rafraîchissement auto',
                  subtitle: 'Actualiser les données automatiquement',
                  value: _autoRefresh,
                  onChanged: (v) => setState(() => _autoRefresh = v),
                ),
                _PrefSelector(
                  icon: Icons.attach_money_rounded,
                  label: 'Devise',
                  value: _currency,
                  options: const ['FCFA', 'EUR', 'USD'],
                  onChanged: (v) => setState(() => _currency = v),
                ),
                _PrefSelector(
                  icon: Icons.payment_rounded,
                  label: 'Paiement par défaut',
                  value: _defaultPayment == 'orange_money' ? 'Orange Money' : 'Moov Money',
                  options: const ['Orange Money', 'Moov Money'],
                  onChanged: (v) => setState(() => _defaultPayment = v == 'Orange Money' ? 'orange_money' : 'moov_money'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Préférences sauvegardées !'), backgroundColor: Colors.green),
                  );
                  context.pop();
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

class _PrefSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PrefSection({required this.title, required this.children});

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

class _PrefToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrefToggle({required this.icon, required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryRed, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryRed),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _PrefSelector extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _PrefSelector({required this.icon, required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryRed, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600, fontSize: 13),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
