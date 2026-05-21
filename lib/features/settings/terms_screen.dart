import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: const Text("Conditions d'utilisation",
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dernière mise à jour: 1er Janvier 2025',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 20),
            _Section(
              title: '1. Acceptation des conditions',
              content: 'En utilisant l\'application Movia, vous acceptez les présentes conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
            ),
            _Section(
              title: '2. Description du service',
              content: 'Movia est une plateforme de réservation de billets de transport inter-urbain et d\'envoi de colis au Burkina Faso. Nous mettons en relation les voyageurs avec les compagnies de transport partenaires.',
            ),
            _Section(
              title: '3. Compte utilisateur',
              content: 'Pour utiliser Movia, vous devez créer un compte avec un numéro de téléphone valide. Vous êtes responsable de la confidentialité de votre compte et de toutes les activités qui s\'y déroulent.',
            ),
            _Section(
              title: '4. Réservations et paiements',
              content: 'Les réservations sont confirmées dès le paiement effectué. Les tarifs affichés incluent toutes les taxes applicables. Les remboursements sont traités selon la politique d\'annulation en vigueur.',
            ),
            _Section(
              title: '5. Politique d\'annulation',
              content: 'Les annulations effectuées plus de 24h avant le départ donnent droit à un remboursement complet. Les annulations de moins de 24h sont soumises à des frais selon les conditions de la compagnie.',
            ),
            _Section(
              title: '6. Responsabilités',
              content: 'Movia agit en tant qu\'intermédiaire entre les voyageurs et les compagnies de transport. Nous ne sommes pas responsables des retards, annulations ou incidents liés aux compagnies partenaires.',
            ),
            _Section(
              title: '7. Programme de fidélité',
              content: 'Les points fidélité sont accordés lors de chaque réservation payée. Ils sont valables 12 mois et peuvent être échangés contre des réductions. Les points ne sont pas échangeables contre de l\'argent.',
            ),
            _Section(
              title: '8. Modifications',
              content: 'Movia se réserve le droit de modifier ces conditions à tout moment. Les utilisateurs seront notifiés des changements importants via l\'application.',
            ),
            const SizedBox(height: 20),
            const Text('Pour toute question, contactez-nous à legal@movia.bf',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}
