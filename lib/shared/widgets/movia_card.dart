import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Carte Movia avec ombres renforcées — "faire ressortir les cartes du background"
class MoviaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final double elevation;

  const MoviaCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.onTap,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(16);
    final bg = color ?? AppColors.white;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        boxShadow: _buildShadows(elevation),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          child: InkWell(
            onTap: onTap,
            borderRadius: br,
            child: card,
          ),
        ),
      );
    }
    return card;
  }

  static List<BoxShadow> _buildShadows(double elevation) {
    if (elevation <= 0) return [];
    // Ombres renforcées pour faire ressortir les cartes du background
    return [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 8 + elevation * 4,
        offset: Offset(0, 2 + elevation * 1.5),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 2,
        offset: const Offset(0, 1),
        spreadRadius: 0,
      ),
    ];
  }

  /// Variante haute élévation (promo cards, hero cards)
  static List<BoxShadow> get elevatedShadows => [
        const BoxShadow(
          color: Color(0x30000000),
          blurRadius: 20,
          offset: Offset(0, 6),
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x18000000),
          blurRadius: 6,
          offset: Offset(0, 2),
          spreadRadius: 0,
        ),
      ];
}
