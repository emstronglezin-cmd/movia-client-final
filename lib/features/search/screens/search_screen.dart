import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/constants/app_data.dart';
import '../../../services/favorites_service.dart';
import '../../../models/loyalty_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? prefFrom;
  final String? prefTo;
  const SearchScreen({super.key, this.prefFrom, this.prefTo});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late String _from;
  late String _to;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _isRoundTrip = false;
  DateTime? _returnDate;
  int _passengers = 1;
  String? _selectedTime;
  bool _isFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();

  final List<String> _timeSlots = [
    'Tous horaires', '06:00-09:00', '09:00-12:00',
    '12:00-15:00', '15:00-18:00', '18:00-21:00',
  ];

  @override
  void initState() {
    super.initState();
    _from = widget.prefFrom ?? '';
    _to = widget.prefTo ?? '';
    _selectedTime = _timeSlots[0];
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFavorite());
  }

  Future<void> _checkFavorite() async {
    if (_from.isNotEmpty && _to.isNotEmpty) {
      final fav = await _favoritesService.isFavorite(_from, _to);
      if (mounted) setState(() => _isFavorite = fav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_from.isEmpty || _to.isEmpty) return;
    if (_isFavorite) {
      final all = await _favoritesService.getAll();
      final fav = all.firstWhere(
        (f) => f.from == _from && f.to == _to,
        orElse: () => FavoriteRoute(id: '', from: _from, to: _to, fromStation: '', toStation: '', savedAt: DateTime.now()),
      );
      if (fav.id.isNotEmpty) await _favoritesService.remove(fav.id);
    } else {
      await _favoritesService.add(
        from: _from, to: _to,
        fromStation: '', toStation: '',
      );
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _swapCities() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  void _search() {
    if (_from.isEmpty || _to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la ville de départ et d\'arrivée')),
      );
      return;
    }
    context.push('/results', extra: {
      'from': _from,
      'to': _to,
      'date': _date.toIso8601String(),
      'passengers': _passengers,
      'isRoundTrip': _isRoundTrip,
      'returnDate': _returnDate?.toIso8601String(),
      'timeFilter': _selectedTime,
    });
  }

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
        title: const Text('Rechercher un trajet',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
        actions: [
          if (_from.isNotEmpty && _to.isNotEmpty)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: _isFavorite ? AppColors.primaryRed : AppColors.textTertiary,
              ),
              onPressed: _toggleFavorite,
              tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type trajet
            _RoundTripToggle(
              isRoundTrip: _isRoundTrip,
              onChanged: (v) => setState(() => _isRoundTrip = v),
            ),
            const SizedBox(height: 16),

            // Route selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.shadowMedium, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _CityField(
                    label: 'Départ',
                    value: _from,
                    icon: Icons.radio_button_checked_rounded,
                    iconColor: AppColors.primaryRed,
                    onTap: () => _showCityPicker(isFrom: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200])),
                        GestureDetector(
                          onTap: _swapCities,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.swap_vert_rounded, color: AppColors.primaryRed, size: 18),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200])),
                      ],
                    ),
                  ),
                  _CityField(
                    label: 'Arrivée',
                    value: _to,
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF059669),
                    onTap: () => _showCityPicker(isFrom: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Date aller',
                    date: _date,
                    onTap: () => _pickDate(isReturn: false),
                  ),
                ),
                if (_isRoundTrip) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Date retour',
                      date: _returnDate,
                      onTap: () => _pickDate(isReturn: true),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Passengers
            _PassengerSelector(
              count: _passengers,
              onChanged: (v) => setState(() => _passengers = v),
            ),
            const SizedBox(height: 16),

            // Time filter
            _TimeFilter(
              selected: _selectedTime ?? _timeSlots[0],
              slots: _timeSlots,
              onChanged: (v) => setState(() => _selectedTime = v),
            ),
            const SizedBox(height: 32),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: AppColors.primaryRed.withValues(alpha: 0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('Rechercher', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Popular routes
            _PopularRoutes(onSelect: (from, to) {
              setState(() { _from = from; _to = to; });
            }),
          ],
        ),
      ),
    );
  }

  void _showCityPicker({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(
        title: isFrom ? 'Ville de départ' : 'Ville d\'arrivée',
        onSelected: (city) {
          setState(() {
            if (isFrom) _from = city;
            else _to = city;
          });
          _checkFavorite();
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isReturn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isReturn ? (_returnDate ?? _date.add(const Duration(days: 1))) : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryRed),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) _returnDate = picked;
        else _date = picked;
      });
    }
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _RoundTripToggle extends StatelessWidget {
  final bool isRoundTrip;
  final ValueChanged<bool> onChanged;
  const _RoundTripToggle({required this.isRoundTrip, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeBtn(label: 'Aller simple', isSelected: !isRoundTrip, onTap: () => onChanged(false)),
        const SizedBox(width: 12),
        _TypeBtn(label: 'Aller-retour', isSelected: isRoundTrip, onTap: () => onChanged(true)),
      ],
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryRed : Colors.grey[300]!),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _CityField({required this.label, required this.value, required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? 'Sélectionner une ville' : value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted = date != null
        ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
        : 'Choisir une date';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Text(formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null ? AppColors.textPrimary : AppColors.textTertiary,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerSelector extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _PassengerSelector({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.people_rounded, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Passagers', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text('$count passager${count > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Row(
            children: [
              _CountBtn(icon: Icons.remove, onTap: count > 1 ? () => onChanged(count - 1) : null),
              const SizedBox(width: 16),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(width: 16),
              _CountBtn(icon: Icons.add, onTap: count < 10 ? () => onChanged(count + 1) : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primaryRed.withValues(alpha: 0.1) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primaryRed : Colors.grey[400]),
      ),
    );
  }
}

class _TimeFilter extends StatelessWidget {
  final String selected;
  final List<String> slots;
  final ValueChanged<String> onChanged;
  const _TimeFilter({required this.selected, required this.slots, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horaire de départ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = slot == selected;
            return GestureDetector(
              onTap: () => onChanged(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primaryRed : Colors.grey[300]!),
                ),
                child: Text(slot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PopularRoutes extends StatelessWidget {
  final Function(String, String) onSelect;
  const _PopularRoutes({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final routes = [
      ('Ouagadougou', 'Bobo-Dioulasso'),
      ('Bobo-Dioulasso', 'Ouagadougou'),
      ('Ouagadougou', 'Koudougou'),
      ('Ouagadougou', 'Banfora'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trajets populaires',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...routes.map((r) => GestureDetector(
          onTap: () => onSelect(r.$1, r.$2),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_rounded, color: AppColors.primaryRed, size: 18),
                const SizedBox(width: 10),
                Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const Spacer(),
                const Icon(Icons.north_east_rounded, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

// ─── City Picker Sheet ───────────────────────────────────────────────────────

class _CityPickerSheet extends StatefulWidget {
  final String title;
  final ValueChanged<String> onSelected;
  const _CityPickerSheet({required this.title, required this.onSelected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = cities.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ville...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final city = filtered[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_city_rounded, color: AppColors.primaryRed, size: 20),
                    ),
                    title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('${city.stations.length} gares', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelected(city.name);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
