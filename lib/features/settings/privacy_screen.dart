import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
        title: const Text('Politique de confidentialité',
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
              title: '1. Données collectées',
              content: 'Movia collecte les informations suivantes: numéro de téléphone, nom complet, adresse email (optionnel), numéro CNIB, historique des réservations et préférences de navigation.',
            ),
            _Section(
              title: '2. Utilisation des données',
              content: 'Vos données sont utilisées pour: traiter vos réservations, améliorer nos services, envoyer des notifications de voyage, gérer votre programme de fidélité et vous contacter en cas de problème.',
            ),
            _Section(
              title: '3. Protection des données',
              content: 'Toutes vos données sont chiffrées et stockées de manière sécurisée. Nous utilisons des protocoles SSL/TLS pour toutes les communications. Vos informations de paiement ne sont jamais stockées sur nos serveurs.',
            ),
            _Section(
              title: '4. Partage des données',
              content: 'Nous partageons uniquement les données nécessaires avec les compagnies de transport partenaires pour effectuer vos réservations. Nous ne vendons jamais vos données à des tiers.',
            ),
            _Section(
              title: '5. Vos droits',
              content: 'Vous avez le droit d\'accéder à vos données, de les corriger, de les supprimer ou de demander leur portabilité. Contactez-nous à privacy@movia.bf pour exercer ces droits.',
            ),
            _Section(
              title: '6. Cookies et traceurs',
              content: 'L\'application utilise des traceurs analytiques anonymisés pour améliorer l\'expérience utilisateur. Vous pouvez désactiver cette collecte dans les paramètres de l\'application.',
            ),
            _Section(
              title: '7. Conservation des données',
              content: 'Vos données de compte sont conservées tant que votre compte est actif. Les données de réservation sont conservées 5 ans pour des raisons légales et fiscales.',
            ),
            _Section(
              title: '8. Contact',
              content: 'Pour toute question relative à la confidentialité: privacy@movia.bf\nAdresse: Ouagadougou, Burkina Faso\nTéléphone: +226 XX XX XX XX',
            ),
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
