import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_Slide> _slides = const [
    _Slide(
      icon: Icons.confirmation_num_outlined,
      title: 'Réservez en un clic',
      subtitle: 'Trouvez et réservez votre billet de bus en quelques secondes, sans file d\'attente.',
      color: AppColors.primaryRed,
    ),
    _Slide(
      icon: Icons.inventory_2_outlined,
      title: 'Expédiez sans stress',
      subtitle: 'Envoyez vos colis partout au Burkina Faso avec un suivi en temps réel.',
      color: Color(0xFF2980B9),
    ),
    _Slide(
      icon: Icons.qr_code_2,
      title: 'Zéro papier, zéro perte',
      subtitle: 'Vos billets sont numériques. Présentez simplement votre QR code au contrôleur.',
      color: Color(0xFF009E67),
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.onboardingKey, true);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MOVIA', style: TextStyle(
                    color: AppColors.primaryRed, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _complete,
                      child: const Text('Passer', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _SlideWidget(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppColors.primaryRed : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _complete();
                        }
                      },
                      child: Text(
                        _currentPage < _slides.length - 1 ? 'Suivant' : 'Commencer',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
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

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _Slide({required this.icon, required this.title, required this.subtitle, required this.color});
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(slide.icon, size: 56, color: slide.color),
          ),
          const SizedBox(height: 40),
          Text(slide.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(slide.subtitle,
            style: const TextStyle(fontSize: 16, color: AppColors.textGray, height: 1.6),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
