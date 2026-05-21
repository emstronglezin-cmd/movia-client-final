import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/home/screens/home_shell.dart';
import '../features/home/screens/trajets_screen.dart';
import '../features/packages/screens/packages_screen.dart';
import '../features/tickets/screens/tickets_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/results/screens/results_screen.dart';
import '../features/booking/screens/booking_screen.dart';
import '../features/tickets/screens/ticket_detail_screen.dart';
import '../features/packages/screens/package_detail_screen.dart';
import '../features/packages/screens/send_package_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/account/screens/personal_info_screen.dart';
import '../features/account/screens/payment_methods_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/loyalty/loyalty_screen.dart';
import '../features/companies/companies_screen.dart';
import '../features/settings/notification_settings_screen.dart';
import '../features/settings/language_screen.dart';
import '../features/settings/preferences_screen.dart';
import '../features/settings/help_support_screen.dart';
import '../features/settings/terms_screen.dart';
import '../features/settings/privacy_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      if (authState.status == AuthStatus.loading) return '/splash';

      if (authState.status == AuthStatus.unauthenticated) {
        // Check onboarding
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool(AppConfig.onboardingKey) ?? false;
        if (!onboardingDone && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        if (state.matchedLocation != '/auth' && state.matchedLocation != '/onboarding') {
          return '/auth';
        }
        return null;
      }

      // Authenticated
      if (state.matchedLocation == '/auth' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/splash') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),

      // Shell (tabs)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TrajetsScreen()),
          GoRoute(path: '/colis', builder: (_, __) => const PackagesScreen()),
          GoRoute(path: '/tickets', builder: (_, __) => const TicketsScreen()),
          GoRoute(path: '/compte', builder: (_, __) => const AccountScreen()),
        ],
      ),

      // Nested screens (full screen)
      GoRoute(path: '/search', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchScreen(
          prefFrom: extra?['prefFrom'] as String?,
          prefTo: extra?['prefTo'] as String?,
        );
      }),
      GoRoute(path: '/results', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ResultsScreen(params: extra);
      }),
      GoRoute(path: '/booking', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BookingScreen(params: extra);
      }),
      GoRoute(path: '/ticket-detail', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TicketDetailScreen(bookingId: extra?['bookingId'] as String? ?? '');
      }),
      GoRoute(path: '/package-detail', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PackageDetailScreen(packageId: extra?['packageId'] as String? ?? '');
      }),
      GoRoute(path: '/send-package', builder: (_, __) => const SendPackageScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/personal-info', builder: (_, __) => const PersonalInfoScreen()),
      GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsScreen()),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/loyalty', builder: (_, __) => const LoyaltyScreen()),
      GoRoute(path: '/companies', builder: (_, __) => const CompaniesScreen()),
      GoRoute(path: '/notification-settings', builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/preferences', builder: (_, __) => const PreferencesScreen()),
      GoRoute(path: '/help-support', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
    ],
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFB53C3C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MOVIA', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 4)),
            SizedBox(height: 8),
            Text('Transport & Colis', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
