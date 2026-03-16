import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/species_info.dart';

/// Écran 'Encyclopédie' affichant la liste de toutes les espèces de plantes disponibles
class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});

  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  // Texte de recherche tapé par l'utilisateur
  String _query = '';
  // Filtre de difficulté sélectionné (all, easy, medium, hard)
  String _filter = 'all'; // 'all', 'easy', 'medium', 'hard'

  /// Fonction qui retourne la liste des espèces filtrées selon la recherche et la difficulté
  List<SpeciesInfo> get _filteredSpecies {
    return SpeciesDatabase.species.where((s) {
      // Vérifie si le nom commun ou le nom scientifique contient le texte recherché
      final matchesQuery = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.scientificName.toLowerCase().contains(_query.toLowerCase());
      
      // Vérifie si la difficulté de l'espèce correspond au filtre sélectionné
      final matchesFilter = _filter == 'all' || s.difficulty == _filter;
      
      // La plante doit correspondre aux deux critères pour être affichée
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final species = _filteredSpecies;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with search
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.heroGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encyclopédie',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${SpeciesDatabase.species.length} espèces répertoriées',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher une plante...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Toutes', value: 'all', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Facile', value: 'easy', selected: _filter == 'easy', onTap: () => setState(() => _filter = 'easy'), color: AppTheme.lightGreen),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Intermédiaire', value: 'medium', selected: _filter == 'medium', onTap: () => setState(() => _filter = 'medium'), color: AppTheme.warningAmber),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Difficile', value: 'hard', selected: _filter == 'hard', onTap: () => setState(() => _filter = 'hard'), color: AppTheme.dangerRed),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Species list
          if (species.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text('Aucune espèce trouvée', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final s = species[index];
                    // Animation d'apparition progressive (fondu) des cartes d'espèces
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      // La durée de l'animation augmente légèrement pour chaque élément (effet en cascade)
                      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            // Déplacement de la carte de la droite vers la gauche
                            offset: Offset(30 * (1 - value), 0),
                            child: child,
                          ),
                        );
                      },
                      // Affichage de la carte pour cette espèce spécifique
                      child: _SpeciesCard(species: s),
                    );
                  },
                  // Nombre total d'éléments à afficher
                  childCount: species.length,
                ),
              ),
            ),
          // Espace vide en bas pour permettre de scroller jusqu'au bout
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Widget privé représentant une "puce" (chip) pour filtrer les espèces par difficulté
class _FilterChip extends StatelessWidget {
  final String label; // Texte affiché (ex: "Facile")
  final String value; // Valeur associée (ex: "easy")
  final bool selected; // Indique si ce filtre est actuellement actif
  final VoidCallback onTap; // Action au clic
  final Color? color; // Couleur de la puce quand elle est sélectionnée

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.grey[300]!),
          boxShadow: selected ? AppTheme.cardShadow : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Widget privé représentant la carte d'une espèce dans la liste
class _SpeciesCard extends StatelessWidget {
  final SpeciesInfo species; // L'objet contenant les informations de l'espèce
  const _SpeciesCard({required this.species});

  /// Retourne la couleur associée à la difficulté (vert pour facile, rouge pour difficile)
  Color get _difficultyColor {
    switch (species.difficulty) {
      case 'easy':
        return AppTheme.lightGreen;
      case 'hard':
        return AppTheme.dangerRed;
      default:
        return AppTheme.warningAmber;
    }
  }

  /// Retourne le libellé français correspondant au niveau de difficulté
  String get _difficultyLabel {
    switch (species.difficulty) {
      case 'easy':
        return 'Facile';
      case 'hard':
        return 'Difficile';
      default:
        return 'Intermédiaire';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/species/${species.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 100,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                            AppTheme.primaryGreen.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            species.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppTheme.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            species.scientificName,
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoPill(icon: Icons.water_drop_outlined, label: _waterLabel(species.wateringNeeds), color: AppTheme.infoBlue),
                              const SizedBox(width: 8),
                              _InfoPill(icon: Icons.wb_sunny_outlined, label: _lightLabel(species.lightNeeds), color: AppTheme.warningAmber),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _difficultyColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            _difficultyLabel,
                            style: TextStyle(color: _difficultyColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D1D6), size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _waterLabel(String need) {
    switch (need) {
      case 'low': return 'Peu';
      case 'high': return 'Beaucoup';
      default: return 'Moyen';
    }
  }

  String _lightLabel(String need) {
    switch (need) {
      case 'low': return 'Ombre';
      case 'high': return 'Lumière';
      case 'direct': return 'Plein soleil';
      default: return 'Mi-ombre';
    }
  }
}

/// Widget privé pour afficher une petite icône avec un texte d'information (ex: besoins en eau)
class _InfoPill extends StatelessWidget {
  final IconData icon; // Icône (ex: goutte d'eau, soleil)
  final String label; // Texte de l'information (ex: "Peu", "Soleil")
  final Color color; // Couleur principale du pillule

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
