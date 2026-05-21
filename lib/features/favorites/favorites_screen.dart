import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/favorites_service.dart';
import '../../models/loyalty_model.dart';
import '../../shared/constants/app_data.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final FavoritesService _service = FavoritesService();
  List<FavoriteRoute> _favorites = [];
  bool _isLoading = true;
  bool _showAddModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final favs = await _service.getAll();
    if (mounted) setState(() { _favorites = favs; _isLoading = false; });
  }

  Future<void> _delete(FavoriteRoute fav) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le favori', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "${fav.from} → ${fav.to}" de vos favoris ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.remove(fav.id);
      _load();
    }
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
        title: const Text('Trajets favoris',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryRed, size: 28),
            onPressed: () => setState(() => _showAddModal = true),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : _favorites.isEmpty
                  ? _EmptyState(onAdd: () => setState(() => _showAddModal = true))
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (_, i) => _FavoriteCard(
                          favorite: _favorites[i],
                          onBook: () => context.push('/search', extra: {
                            'prefFrom': _favorites[i].from,
                            'prefTo': _favorites[i].to,
                          }),
                          onDelete: () => _delete(_favorites[i]),
                        ),
                      ),
                    ),
          if (_showAddModal)
            _AddFavoriteModal(
              onClose: () => setState(() => _showAddModal = false),
              onAdd: (from, to) async {
                await _service.add(
                  from: from, to: to,
                  fromStation: '', toStation: '',
                );
                setState(() => _showAddModal = false);
                _load();
              },
            ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteRoute favorite;
  final VoidCallback onBook, onDelete;
  const _FavoriteCard({required this.favorite, required this.onBook, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    favorite.label ?? '${favorite.from} → ${favorite.to}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _CityChip(city: favorite.from, isFrom: true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textTertiary),
                ),
                _CityChip(city: favorite.to, isFrom: false),
                const Spacer(),
                Text(
                  _formatDate(favorite.savedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
            if (favorite.fromStation.isNotEmpty || favorite.toStation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${favorite.fromStation} → ${favorite.toStation}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 16),
                label: const Text('Rechercher ce trajet', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

class _CityChip extends StatelessWidget {
  final String city;
  final bool isFrom;
  const _CityChip({required this.city, required this.isFrom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFrom ? AppColors.primaryRed.withValues(alpha: 0.08) : const Color(0xFF059669).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(city, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: isFrom ? AppColors.primaryRed : const Color(0xFF059669),
      )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun favori', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Ajoutez vos trajets fréquents pour les retrouver facilement',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Ajouter un favori', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String, String) onAdd;
  const _AddFavoriteModal({required this.onClose, required this.onAdd});

  @override
  State<_AddFavoriteModal> createState() => _AddFavoriteModalState();
}

class _AddFavoriteModalState extends State<_AddFavoriteModal> {
  String _from = '';
  String _to = '';

  void _pickCity({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitySheet(
        title: isFrom ? 'Ville de départ' : 'Ville d\'arrivée',
        onSelected: (city) => setState(() { if (isFrom) _from = city; else _to = city; }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Ajouter un favori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _CityBtn(label: 'Départ', value: _from, onTap: () => _pickCity(isFrom: true)),
              const SizedBox(height: 10),
              _CityBtn(label: 'Arrivée', value: _to, onTap: () => _pickCity(isFrom: false)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _from.isNotEmpty && _to.isNotEmpty ? () => widget.onAdd(_from, _to) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityBtn extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _CityBtn({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primaryRed, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  Text(value.isEmpty ? 'Sélectionner...' : value,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)),
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

class _CitySheet extends StatefulWidget {
  final String title;
  final ValueChanged<String> onSelected;
  const _CitySheet({required this.title, required this.onSelected});

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = cities.where((c) => c.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
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
                  Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search_rounded),
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
