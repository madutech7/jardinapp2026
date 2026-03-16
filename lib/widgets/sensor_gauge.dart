import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Widget affichant une jauge de capteur (température, humidité, lumière)
/// sous forme de carte avec une icône, une valeur textuelle et une barre de progression.
class SensorGauge extends StatelessWidget {
  final String label; // Nom de la mesure (ex: "Humidité")
  final double value; // Valeur actuelle de la mesure
  final String unit; // Unité de mesure (ex: "%" ou "°C")
  final IconData icon; // Icône associée au capteur
  final Color color; // Couleur principale de la jauge
  final bool isAlert; // Indique si la valeur est hors des limites normales (déclenche un style d'alerte)
  final double max; // Valeur maximale possible pour calculer le remplissage de la barre
  
  const SensorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isAlert = false,
    this.max = 100,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul de la fraction de remplissage de la barre (entre 0.0 et 1.0)
    final fraction = (value / max).clamp(0.0, 1.0);
    // Si la valeur est en alerte, on force la couleur en rouge, sinon on utilise la couleur fournie
    final displayColor = isAlert ? AppTheme.dangerRed : color;
    // Si en alerte, le fond de la carte est légèrement teinté, sinon il est blanc
    final bgColor = isAlert ? displayColor.withValues(alpha: 0.05) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAlert ? displayColor.withValues(alpha: 0.3) : const Color(0xFFE8F0EB),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // En-tête de la carte : Icône et badge d'alerte éventuel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isAlert ? Icons.warning_amber_rounded : icon, color: displayColor, size: 22),
              ),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Alerte',
                    style: TextStyle(color: AppTheme.dangerRed, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Libellé du capteur (ex: "Temp.")
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Valeur chiffrée animée (ex: "24.5°C")
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) => Text(
              '${val.toStringAsFixed(1)}$unit',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Barre de progression linéaire animée
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: displayColor.withValues(alpha: 0.12),
                color: displayColor,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
