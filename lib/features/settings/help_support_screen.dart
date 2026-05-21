import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/app_config.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: const Text('Aide & Support',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryRed, Color(0xFF8B2E2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text('🛟', style: TextStyle(fontSize: 36)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Besoin d\'aide ?',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Notre équipe est disponible pour vous aider 7j/7',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact options
            const Text('Nous contacter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.phone_rounded,
                    label: 'Appel téléphonique',
                    subtitle: AppConfig.supportPhone,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF059669),
                    onTap: () => _launch('tel:${AppConfig.supportPhone}'),
                    isFirst: true,
                  ),
                  const Divider(height: 1, indent: 70),
                  _ContactTile(
                    icon: Icons.message_rounded,
                    label: 'WhatsApp',
                    subtitle: 'Discutez avec un agent',
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF25D366),
                    onTap: () => _launch('https://wa.me/${AppConfig.supportPhone.replaceAll('+', '')}'),
                  ),
                  const Divider(height: 1, indent: 70),
                  _ContactTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    subtitle: 'support@movia.bf',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => _launch('mailto:support@movia.bf'),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ
            const Text('Questions fréquentes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ..._faqs.map((faq) => _FAQItem(q: faq['q']!, a: faq['a']!)),
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text('Movia v1.0.0 • Burkina Faso\nsupport@movia.bf',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static const List<Map<String, String>> _faqs = [
    {'q': 'Comment annuler ma réservation ?', 'a': 'Rendez-vous dans "Mes Tickets", sélectionnez votre billet et appuyez sur "Annuler ce billet". Un remboursement sera traité sous 48h.'},
    {'q': 'Comment suivre mon colis ?', 'a': 'Dans "Mes Colis", sélectionnez votre colis pour voir le suivi en temps réel avec la timeline de livraison.'},
    {'q': 'Quels moyens de paiement sont acceptés ?', 'a': 'Movia accepte Orange Money et Moov Money. Vous pouvez aussi réserver et payer à la gare.'},
    {'q': 'Comment gagner des points fidélité ?', 'a': 'Vous gagnez des points à chaque réservation payée. 1 trajet = 1 point. Utilisez vos points pour des réductions.'},
    {'q': 'Mon OTP n\'arrive pas, que faire ?', 'a': 'Vérifiez que votre numéro est correct et attendez 60 secondes avant de renvoyer. Contactez le support si le problème persiste.'},
  ];
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color iconBg, iconColor;
  final VoidCallback onTap;
  final bool isFirst, isLast;
  const _ContactTile({
    required this.icon, required this.label, required this.subtitle,
    required this.iconBg, required this.iconColor, required this.onTap,
    this.isFirst = false, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String q, a;
  const _FAQItem({required this.q, required this.a});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          trailing: Icon(_expanded ? Icons.remove_rounded : Icons.add_rounded, color: AppColors.primaryRed, size: 20),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(widget.a, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
