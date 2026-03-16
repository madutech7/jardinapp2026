import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/plant_model.dart';

/// Widget représentant une carte individuelle pour chaque plante dans la grille du jardin
class PlantCard extends StatelessWidget {
  final PlantModel plant; // Le modèle de données de la plante à afficher
  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    // Extraction des informations de santé pour l'affichage dynamique
    final health = plant.healthScore;
    final statusText = _healthText(health); // Ex: "En pleine forme", "Besoin d'eau"
    final statusColor = _statusColor(statusText); // Couleur associée au statut
    final statusIcon = _statusIcon(statusText); // Icône associée au statut

    // GestureDetector permet de naviguer vers les détails de la plante lors d'un appui
    return GestureDetector(
      onTap: () => context.push('/plant/${plant.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de base qui remplit toute la carte (Full Bleed)
              plant.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: plant.photoUrl!,
                      fit: BoxFit.cover, // Redimensionnement pour remplir sans déformer
                      placeholder: (context, url) => _PlantPlaceholder(),
                      errorWidget: (context, url, error) => _PlantPlaceholder(),
                    )
                  : _PlantPlaceholder(),

              // Dégradé supérieur (Top Gradient) pour assurer le contraste avec l'étiquette de santé
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Badge affichant le pourcentage de santé en haut à droite
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${health.toInt()}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Zone d'informations en bas avec effet de verre dépoli (Glassmorphism)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plant.species,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"${plant.name}"',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(statusIcon, color: statusColor, size: 10),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Détermine le texte descriptif de l'état de la plante basé sur son score de santé
  String _healthText(double h) {
    if (h >= 90) return 'En pleine forme';
    if (h >= 80) return 'Besoin d\'eau';
    if (h >= 70) return 'En croissance';
    if (h >= 60) return 'S\'épanouit';
    if (h >= 40) return 'Besoin d\'eau';
    return 'Critique';
  }

  /// Assigne une couleur spécifique selon le statut textuel
  Color _statusColor(String status) {
    switch (status) {
      case 'En pleine forme': return AppTheme.primaryGreen;
      case 'Besoin d\'eau': return AppTheme.infoBlue;
      case 'S\'épanouit': return AppTheme.primaryGreen;
      case 'En croissance': return AppTheme.lightGreen;
      default: return AppTheme.dangerRed;
    }
  }

  /// Assigne une icône spécifique selon le statut textuel
  IconData _statusIcon(String status) {
    switch (status) {
      case 'En pleine forme': return Icons.eco_rounded;
      case 'Besoin d\'eau': return Icons.water_drop_rounded;
      case 'S\'épanouit': return Icons.favorite_rounded;
      case 'En croissance': return Icons.eco_rounded;
      default: return Icons.warning_rounded;
    }
  }
}

/// Widget privé affichant un espace réservé (Placeholder) si la plante n'a pas d'image
class _PlantPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.paleGreen,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.yard_rounded, color: AppTheme.lightGreen, size: 40),
          ],
        ),
      ),
    );
  }
}
