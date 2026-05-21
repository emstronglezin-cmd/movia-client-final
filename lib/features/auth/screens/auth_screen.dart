import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/country_code_picker.dart';
import '../../../shared/constants/west_africa_countries.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Form step: form | otp
  String _step = 'form';
  String _activeTab = 'connexion'; // connexion | inscription

  // Form fields
  final _phoneController = TextEditingController();
  final _cnibController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());

  WestAfricanCountry _selectedCountry = westAfricaCountries.first; // Burkina Faso par défaut

  String? _debugOtp;
  bool _isLoading = false;
  String? _error;
  int _resendCountdown = 0;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _activeTab = _tabController.index == 0 ? 'inscription' : 'connexion';
        _clearForm();
      });
    });
    _startResendTimer();
  }

  void _clearForm() {
    _phoneController.clear();
    _cnibController.clear();
    for (final c in _otpControllers) c.clear();
    setState(() { _error = null; _step = 'form'; _debugOtp = null; });
  }

  void _startResendTimer() {
    if (_resendCountdown > 0) return;
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown = (_resendCountdown - 1).clamp(0, 60));
      return _resendCountdown > 0;
    });
  }

  String get _fullPhone => '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

  bool _validateCnib(String v) {
    final regex = RegExp(r'^[A-Za-z]{1,2}[0-9]{5,}$');
    return regex.hasMatch(v);
  }

  Future<void> _sendOtp() async {
    setState(() { _error = null; _isLoading = true; });
    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) throw Exception('Veuillez entrer votre numéro de téléphone');
      if (_activeTab == 'inscription') {
        final cnib = _cnibController.text.trim();
        if (cnib.isEmpty) throw Exception('Veuillez entrer votre CNIB');
        if (!_validateCnib(cnib)) throw Exception('Format CNIB invalide (ex: B10488329)');
        if (!_acceptedTerms) throw Exception('Veuillez accepter les conditions d\'utilisation');
      }
      final result = await ref.read(authProvider.notifier).initiateAuth(
        phone: _fullPhone,
        cnib: _activeTab == 'inscription' ? _cnibController.text.trim().toUpperCase() : null,
        isRegistration: _activeTab == 'inscription',
      );
      setState(() {
        _debugOtp = result['otp']?.toString();
        _step = 'otp';
        _resendCountdown = 0;
      });
      _startResendTimer();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _error = 'Veuillez entrer le code complet à 6 chiffres');
      return;
    }
    setState(() { _error = null; _isLoading = true; });
    try {
      await ref.read(authProvider.notifier).verifyOtp(phone: _fullPhone, code: otp);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _cnibController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionExpired = ref.watch(authProvider).sessionExpiredMessage;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  const Text('MOVIA', style: TextStyle(
                    color: AppColors.primaryRed, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const SizedBox(height: 4),
                  const Text('Transport & Colis • Burkina Faso',
                    style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                  const SizedBox(height: 24),

                  // Session expired banner
                  if (sessionExpired != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(sessionExpired,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)))),
                        GestureDetector(
                          onTap: () => ref.read(authProvider.notifier).clearSessionExpired(),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF92400E))),
                      ]),
                    ),

                  if (_step == 'form') ...[
                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.tabBgInactive,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.primaryRed,
                        unselectedLabelColor: AppColors.textGray,
                        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        tabs: const [Tab(text: 'Inscription'), Tab(text: 'Connexion')],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _step == 'form' ? _buildForm() : _buildOtp(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) _errorBanner(),
        const SizedBox(height: 8),

        // Phone field with country selector
        _label('Numéro de téléphone'),
        const SizedBox(height: 8),
        Row(
          children: [
            CountryCodePicker(
              selected: _selectedCountry,
              onChanged: (c) => setState(() => _selectedCountry = c),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'XX-XX-XX-XX',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ],
        ),

        if (_activeTab == 'inscription') ...[
          const SizedBox(height: 20),
          _label('Numéro CNIB'),
          const SizedBox(height: 8),
          TextField(
            controller: _cnibController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            onChanged: (v) => _cnibController.value = _cnibController.value.copyWith(
              text: v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''),
              selection: TextSelection.collapsed(offset: v.length),
            ),
            decoration: InputDecoration(
              hintText: 'ex: B10488329',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.credit_card_outlined, color: AppColors.textGray, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          // Terms acceptance
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _acceptedTerms ? AppColors.primaryRed : AppColors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _acceptedTerms ? AppColors.primaryRed : AppColors.border, width: 1.5),
                  ),
                  child: _acceptedTerms ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.4),
                      children: [
                        const TextSpan(text: "J'accepte les "),
                        TextSpan(
                          text: 'Conditions d\'utilisation',
                          style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                        ),
                        const TextSpan(text: ' et la '),
                        TextSpan(
                          text: 'Politique de confidentialité',
                          style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_activeTab == 'inscription' ? 'S\'inscrire' : 'Se connecter',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_error != null) _errorBanner(),
        const SizedBox(height: 8),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.lightRed, borderRadius: BorderRadius.circular(36)),
          child: const Icon(Icons.sms_outlined, color: AppColors.primaryRed, size: 32),
        ),
        const SizedBox(height: 20),
        const Text('Code de vérification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('Un code à 6 chiffres a été envoyé au\n$_fullPhone',
          style: const TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.5),
          textAlign: TextAlign.center),
        if (_debugOtp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
            child: Text('Code test: $_debugOtp',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E), fontSize: 14)),
          ),
        ],
        const SizedBox(height: 32),
        // OTP inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Container(
            width: 46, height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _otpControllers[i],
              focusNode: _otpFocuses[i],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 2)),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) {
                  _otpFocuses[i + 1].requestFocus();
                } else if (v.isEmpty && i > 0) {
                  _otpFocuses[i - 1].requestFocus();
                }
                if (i == 5 && v.isNotEmpty) _verifyOtp();
              },
            ),
          )),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Vérifier', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        // Resend
        _resendCountdown > 0
            ? Text('Renvoyer dans ${_resendCountdown}s',
                style: const TextStyle(fontSize: 14, color: AppColors.textGray))
            : TextButton(
                onPressed: _sendOtp,
                child: const Text('Renvoyer le code', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() { _step = 'form'; _error = null; }),
          child: const Text('← Modifier le numéro', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _errorBanner() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFCA5A5)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error))),
    ]),
  );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark));
}
