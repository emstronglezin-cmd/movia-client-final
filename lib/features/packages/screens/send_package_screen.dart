import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/packages_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/packages_service.dart';
import '../../../shared/constants/app_data.dart';

class SendPackageScreen extends ConsumerStatefulWidget {
  const SendPackageScreen({super.key});

  @override
  ConsumerState<SendPackageScreen> createState() => _SendPackageScreenState();
}

class _SendPackageScreenState extends ConsumerState<SendPackageScreen> {
  int _step = 0; // 0=itinéraire, 1=colis, 2=confirmation
  bool _isSubmitting = false;
  String? _successReference;

  // Step 0
  String _from = '';
  String _to = '';
  String? _fromStation;
  String? _toStation;
  String? _selectedCompanyId;

  // Step 1
  final _descController = TextEditingController();
  final _weightController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  double get _estimatedPrice {
    final weight = double.tryParse(_weightController.text) ?? 0;
    return 1500 + (weight.ceil() * 1000);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _senderNameController.text = user.name;
        _senderPhoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _weightController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 0) return _from.isNotEmpty && _to.isNotEmpty && _selectedCompanyId != null;
    if (_step == 1) {
      return _senderNameController.text.isNotEmpty &&
          _senderPhoneController.text.length >= 8 &&
          _recipientNameController.text.isNotEmpty &&
          _recipientPhoneController.text.length >= 8;
    }
    return true;
  }

  Future<void> _send() async {
    setState(() => _isSubmitting = true);
    try {
      final request = CreatePackageRequest(
        companyId: _selectedCompanyId!,
        from: _from,
        to: _to,
        fromStation: _fromStation ?? '',
        toStation: _toStation ?? '',
        senderName: _senderNameController.text.trim(),
        senderPhone: _senderPhoneController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        description: _descController.text.trim(),
        weight: _weightController.text.isNotEmpty ? _weightController.text : null,
        price: _estimatedPrice,
      );
      await ref.read(packagesProvider.notifier).create(request);
      final ref2 = 'PKG${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      if (mounted) setState(() { _successReference = ref2; _isSubmitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_successReference != null) return _SuccessScreen(reference: _successReference!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _step == 0 ? () => context.pop() : () => setState(() => _step--),
        ),
        title: Text(
          ['Itinéraire', 'Informations colis', 'Confirmation'][_step],
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(height: 3, color: i <= _step ? AppColors.primaryRed : Colors.grey[200]),
            )),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: [_buildStep0(), _buildStep1(), _buildStep2()][_step],
            ),
          ),
          _BottomBar(
            label: _step == 2 ? 'Envoyer le colis' : 'Continuer',
            canProceed: _canProceed,
            isSubmitting: _isSubmitting,
            onTap: _step == 2 ? _send : () => setState(() => _step++),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              _CityField(label: 'Ville d\'expédition', value: _from, onTap: () => _pickCity(isFrom: true)),
              Divider(height: 1, color: Colors.grey[100]),
              _CityField(label: 'Ville de destination', value: _to, onTap: () => _pickCity(isFrom: false)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Company picker
        const Text('Compagnie de transport',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...companies.map((c) {
          final isSelected = _selectedCompanyId == c.id;
          final color = getCompanyColor(c.id);
          return GestureDetector(
            onTap: () => setState(() => _selectedCompanyId = c.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primaryRed : Colors.grey[200]!, width: isSelected ? 2 : 1),
                boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(getCompanyShortName(c.id), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                        Text('Transport de colis', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Expéditeur',
          children: [
            _Field(controller: _senderNameController, label: 'Nom complet', hint: 'Votre nom'),
            const SizedBox(height: 10),
            _Field(controller: _senderPhoneController, label: 'Téléphone', hint: '70 00 00 00', keyboardType: TextInputType.phone),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Destinataire',
          children: [
            _Field(controller: _recipientNameController, label: 'Nom complet', hint: 'Nom du destinataire'),
            const SizedBox(height: 10),
            _Field(controller: _recipientPhoneController, label: 'Téléphone', hint: '70 00 00 00', keyboardType: TextInputType.phone),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Colis',
          children: [
            _Field(controller: _descController, label: 'Description', hint: 'Ex: Vêtements, Documents...'),
            const SizedBox(height: 10),
            _Field(controller: _weightController, label: 'Poids (kg)', hint: '2.5', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            if (_weightController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_rounded, color: AppColors.primaryRed, size: 18),
                    const SizedBox(width: 8),
                    Text('Prix estimé: ${formatPrice(_estimatedPrice.toInt())} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryRed)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _SummaryRow(label: 'De', value: _from),
        _SummaryRow(label: 'À', value: _to),
        _SummaryRow(label: 'Compagnie', value: _selectedCompanyId != null ? getCompanyFullName(_selectedCompanyId!) : ''),
        _SummaryRow(label: 'Expéditeur', value: _senderNameController.text),
        _SummaryRow(label: 'Destinataire', value: _recipientNameController.text),
        _SummaryRow(label: 'Description', value: _descController.text.isEmpty ? 'N/A' : _descController.text),
        _SummaryRow(label: 'Poids', value: _weightController.text.isEmpty ? 'N/A' : '${_weightController.text} kg'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prix total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('${formatPrice(_estimatedPrice.toInt())} FCFA',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryRed)),
            ],
          ),
        ),
      ],
    );
  }

  void _pickCity({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitySheet(
        title: isFrom ? 'Ville d\'expédition' : 'Ville de destination',
        onSelected: (city) => setState(() {
          if (isFrom) { _from = city; _fromStation = null; }
          else { _to = city; _toStation = null; }
        }),
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _CityField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  Text(
                    value.isEmpty ? 'Sélectionner...' : value,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType keyboardType;
  const _Field({required this.controller, required this.label, required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final bool canProceed, isSubmitting;
  final VoidCallback onTap;
  const _BottomBar({required this.label, required this.canProceed, required this.isSubmitting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed && !isSubmitting ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isSubmitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _CitySheet extends StatefulWidget {
  final String title;
  final ValueChanged<String> onSelected;
  const _CitySheet({required this.title, required this.onSelected});

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = cities.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: filtered.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.location_city_rounded, color: AppColors.primaryRed),
                  title: Text(filtered[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () { Navigator.pop(context); widget.onSelected(filtered[i].name); },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String reference;
  const _SuccessScreen({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 24),
              const Text('Colis enregistré !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text('Référence: $reference',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryRed, letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text('Votre colis a été enregistré avec succès. Vous pouvez suivre son statut dans "Mes Colis".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/colis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Voir mes colis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l\'accueil', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
