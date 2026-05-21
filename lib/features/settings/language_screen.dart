import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'fr';

  static const List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'native': 'Français'},
    {'code': 'en', 'name': 'Anglais', 'flag': '🇬🇧', 'native': 'English'},
    {'code': 'moore', 'name': 'Mooré', 'flag': '🇧🇫', 'native': 'Mooré'},
    {'code': 'dioula', 'name': 'Dioula', 'flag': '🇧🇫', 'native': 'Dioula'},
  ];

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
        title: const Text('Langue',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir la langue de l\'application',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: List.generate(_languages.length, (i) {
                  final lang = _languages[i];
                  final isSelected = lang['code'] == _selected;
                  return Column(
                    children: [
                      ListTile(
                        onTap: () => setState(() => _selected = lang['code']!),
                        leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                        title: Text(lang['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15,
                              color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
                            )),
                        subtitle: Text(lang['native']!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 22)
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      if (i < _languages.length - 1) const Divider(height: 1, indent: 70),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Langue mise à jour !'), backgroundColor: Colors.green),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
