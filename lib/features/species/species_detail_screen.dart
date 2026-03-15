import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/species_info.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final String speciesId;
  const SpeciesDetailScreen({super.key, required this.speciesId});

  @override
  Widget build(BuildContext context) {
    final species = SpeciesDatabase.species.firstWhere(
      (s) => s.id == speciesId,
      orElse: () => SpeciesDatabase.species.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            elevation: 0,
            leadingWidth: 70,
            leading: Center(
              child: IconButton(
                icon: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withValues(alpha: 0.8),
                          AppTheme.accentGreen,
                        ],
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 140),
                  ),
                  // Bottom gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.scientificName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Family & difficulty
                  Row(
                    children: [
                      _Chip(label: species.family, icon: Icons.category_outlined, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      _Chip(
                        label: species.difficulty == 'easy'
                            ? 'Facile'
                            : species.difficulty == 'hard'
                                ? 'Difficile'
                                : 'Intermédiaire',
                        icon: Icons.stars_rounded,
                        color: species.difficulty == 'easy'
                            ? AppTheme.lightGreen
                            : species.difficulty == 'hard'
                                ? AppTheme.dangerRed
                                : AppTheme.warningAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Description', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(species.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),

                  const SizedBox(height: 24),
                  Text('Besoins', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _NeedCard(icon: Icons.water_drop_outlined, label: 'Arrosage', value: _needLabel(species.wateringNeeds), color: AppTheme.infoBlue),
                      _NeedCard(icon: Icons.wb_sunny_outlined, label: 'Exposition', value: _lightLabel(species.lightNeeds), color: AppTheme.warningAmber),
                      _NeedCard(icon: Icons.thermostat_outlined, label: 'Température', value: '${species.minTemp.toInt()}-${species.maxTemp.toInt()}°C', color: AppTheme.earthBrown),
                      _NeedCard(icon: Icons.water_outlined, label: 'Humidité', value: _needLabel(species.humidity), color: AppTheme.primaryGreen),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grass_rounded, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Sol : ${species.soilType}', style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Conseils d\'entretien', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 14),
                  ...species.careTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: const BoxDecoration(color: AppTheme.paleGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 14),
                        ),
                        Expanded(child: Text(tip, style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5))),
                      ],
                    ),
                  )),

                  const SizedBox(height: 24),
                  Text('Problèmes courants', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 14),
                  ...species.commonProblems.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 14),
                        ),
                        Expanded(child: Text(p, style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _needLabel(String level) {
    switch (level) {
      case 'low': return 'Faible';
      case 'high': return 'Élevé';
      default: return 'Moyen';
    }
  }

  String _lightLabel(String level) {
    switch (level) {
      case 'low': return 'Mi-ombre';
      case 'high': return 'Lumière vive';
      case 'direct': return 'Plein soleil';
      default: return 'Indirect';
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _NeedCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
