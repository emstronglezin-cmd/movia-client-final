import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../constants/west_africa_countries.dart';

class CountryCodePicker extends StatefulWidget {
  final WestAfricanCountry selected;
  final ValueChanged<WestAfricanCountry> onChanged;

  const CountryCodePicker({super.key, required this.selected, required this.onChanged});

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        selected: widget.selected,
        onSelected: (c) {
          widget.onChanged(c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              widget.selected.dialCode,
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final WestAfricanCountry selected;
  final ValueChanged<WestAfricanCountry> onSelected;
  const _CountryPickerSheet({required this.selected, required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';
  List<WestAfricanCountry> get _filtered => westAfricaCountries
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.dialCode.contains(_query) ||
          c.code.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choisir un pays',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 14),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search, color: AppColors.textGray, size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un pays…',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final country = _filtered[i];
                  final isSelected = country.code == widget.selected.code;
                  return ListTile(
                    onTap: () => widget.onSelected(country),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Text(country.flag, style: const TextStyle(fontSize: 28)),
                    title: Text(country.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryRed : AppColors.textDark,
                      )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(country.dialCode,
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primaryRed : AppColors.textGray,
                          )),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 18),
                        ],
                      ],
                    ),
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
