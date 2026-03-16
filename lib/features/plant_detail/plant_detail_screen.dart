import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/plant_model.dart';
import '../../models/sensor_reading.dart';
import '../../services/firebase_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/health_ring.dart';
import '../../widgets/sensor_gauge.dart';
import '../../models/species_info.dart';

/// Écran affichant les détails complets d'une plante spécifique
class PlantDetailScreen extends ConsumerWidget {
  final String plantId; // L'identifiant unique de la plante
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des données asynchrones via Riverpod
    final plantAsync = ref.watch(plantProvider(plantId));
    final latestReading = ref.watch(latestSensorReadingProvider(plantId));
    final readingsAsync = ref.watch(sensorReadingsProvider(plantId));

    return plantAsync.when(
      data: (plant) {
        if (plant == null) {
          return Scaffold(body: Center(child: Text('Plante introuvable')));
        }
        return _PlantDetailContent(
          plant: plant,
          latestReading: latestReading,
          readingsAsync: readingsAsync,
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }
}

class _PlantDetailContent extends ConsumerStatefulWidget {
  final PlantModel plant;
  final SensorReading? latestReading;
  final AsyncValue<List<SensorReading>> readingsAsync;

  const _PlantDetailContent({
    required this.plant,
    required this.latestReading,
    required this.readingsAsync,
  });

  @override
  ConsumerState<_PlantDetailContent> createState() => _PlantDetailContentState();
}

class _PlantDetailContentState extends ConsumerState<_PlantDetailContent> {
  // Indicateur de chargement pour la simulation
  bool _simulating = false;

  /// Fonction pour générer de fausses données de capteur (pour la démo)
  Future<void> _simulateReading() async {
    setState(() => _simulating = true);
    try {
      final reading = SensorSimulator.generateReading(
        widget.plant.id,
        previous: widget.latestReading,
      );
      await FirebaseService.addDocument(
        FirebaseService.sensorReadingsRef(widget.plant.id),
        reading.toFirestore(),
      );
      // Met à jour le score de santé de la plante en fonction des nouvelles lectures
      await FirebaseService.updateDocument(
        FirebaseService.plantsRef,
        widget.plant.id,
        {
          'healthScore': reading.healthScore,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture simulée ajoutée'), backgroundColor: AppTheme.lightGreen),
        );
      }
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  /// Affiche une boîte de dialogue pour confirmer la suppression de la plante
  Future<void> _deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la plante ?'),
        content: Text('Cette action supprimera définitivement "${widget.plant.name}" et toutes ses données.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    // Si l'utilisateur a confirmé la suppression
    if (confirm == true) {
      if (widget.plant.photoUrl != null) {
        await CloudinaryService.deleteImage(widget.plant.photoUrl!);
      }
      await FirebaseService.deleteDocument(FirebaseService.plantsRef, widget.plant.id);
      // Redirection vers le jardin après la suppression
      if (mounted) context.go('/garden');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final latest = widget.latestReading;
    final readings = widget.readingsAsync.value ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Stunning App bar with plant image
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            elevation: 0,
            leadingWidth: 70,
            centerTitle: true,
            title: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) => Text(
                plant.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: value),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            leading: Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 2), // Tiny offset for visual balance of IOS arrow
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Center(
                child: GestureDetector(
                  onTap: _deletePlant,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  plant.photoUrl != null
                      ? CachedNetworkImage(imageUrl: plant.photoUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(gradient: AppTheme.heroGradient),
                          child: const Center(child: Icon(Icons.yard_rounded, color: Colors.white, size: 120)),
                        ),
                  // Top protection gradient (for status bar and buttons)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Dark bottom gradient for text contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                        stops: const [0.35, 1.0],
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
                          plant.species.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.accentGreen.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoTag(
                              icon: Icons.location_on_rounded,
                              label: plant.location ?? 'Non localisée',
                            ),
                            const SizedBox(width: 10),
                            _InfoTag(
                              icon: Icons.calendar_today_rounded,
                              label: 'Depuis ${DateFormat('MM/yyyy').format(plant.acquisitionDate)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                transform: Matrix4.translationValues(0, -32, 0),
                padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne affichant l'anneau de santé et les infos rapides
                    Row(
                      children: [
                        HealthRing(percent: plant.healthScore, size: 90, strokeWidth: 9),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('État de santé', style: Theme.of(context).textTheme.labelMedium),
                              Text(
                                AppTheme.healthLabel(plant.healthScore),
                                style: TextStyle(
                                  color: AppTheme.healthColor(plant.healthScore),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Acquise le ${DateFormat('dd/MM/yyyy').format(plant.acquisitionDate)}',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                              if (plant.location != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                                    const SizedBox(width: 5),
                                    Text(plant.location!, style: Theme.of(context).textTheme.labelMedium),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (plant.description != null && plant.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('À propos', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.paleGreen.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          plant.description!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: AppTheme.textDark.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],

                    // Lien vers la page de l'encyclopédie de l'espèce
                    _SpeciesEncyclopediaLink(speciesName: plant.species),
                    if (latest != null && (latest.needsWatering || latest.tooCold || latest.tooHot || latest.insufficientLight)) ...[
                      const SizedBox(height: 24),
                      _AlertsSection(reading: latest),
                    ],

                    const SizedBox(height: 32),
                    // Section des données des capteurs en temps réel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Capteurs en Temps Réel', style: Theme.of(context).textTheme.headlineLarge),
                        if (latest != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_rounded, size: 10, color: AppTheme.lightGreen),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm').format(latest.timestamp),
                                  style: const TextStyle(color: AppTheme.lightGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (latest != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SensorGauge(
                              label: 'Humidité',
                              value: latest.soilMoisture,
                              unit: '%',
                              icon: Icons.water_drop_outlined,
                              color: AppTheme.infoBlue,
                              isAlert: latest.needsWatering,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SensorGauge(
                              label: 'Temp.',
                              value: latest.temperature,
                              unit: '°C',
                              icon: Icons.thermostat_outlined,
                              color: AppTheme.earthBrown,
                              isAlert: latest.tooCold || latest.tooHot,
                              max: 40,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SensorGauge(
                              label: 'Lumière',
                              value: latest.light,
                              unit: '%',
                              icon: Icons.wb_sunny_outlined,
                              color: AppTheme.warningAmber,
                              isAlert: latest.insufficientLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Dernière lecture : ${DateFormat('dd/MM à HH:mm').format(latest.timestamp)}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8F0EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sensors_outlined, color: AppTheme.textMuted, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Aucune lecture capteur. Simulez votre première lecture.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Bouton pour lancer une simulation de capteurs
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _simulating ? null : _simulateReading,
                      icon: _simulating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sensors_rounded),
                      label: const Text('Simuler une lecture capteur'),
                    ),

                    // Chart
                    if (readings.length >= 2) ...[
                      const SizedBox(height: 28),
                      Text("Évolution de l'humidité", style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 16),
                      _SensorChart(readings: readings.reversed.toList()),
                    ],

                    const SizedBox(height: 24),
                    // Boutons d'actions rapides (Arroser, Ajouter Note, Historique)
                    Text('Actions', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.water_drop_rounded,
                            label: 'Arroser\nMaintenant',
                            color: AppTheme.infoBlue,
                            onTap: _simulateReading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_note_rounded,
                            label: 'Ajouter une\nNote',
                            color: AppTheme.primaryGreen,
                            onTap: () => context.push('/plant/${plant.id}/notes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.history_rounded,
                            label: 'Historique\nCapteurs',
                            color: AppTheme.warningAmber,
                            onTap: () => context.push('/plant/${plant.id}/readings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Tag d'information privé stylisé avec effet de verre (Glassmorphism)
class _InfoTag extends StatelessWidget {
  final IconData icon; // Icône à afficher
  final String label; // Texte du tag

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 13),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget privé affichant un lien visuel vers l'encyclopédie pour l'espèce de la plante
class _SpeciesEncyclopediaLink extends StatelessWidget {
  final String speciesName; // Nom de l'espèce à rechercher
  const _SpeciesEncyclopediaLink({required this.speciesName});

  @override
  Widget build(BuildContext context) {
    final species = SpeciesDatabase.findByName(speciesName);
    if (species == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: InkWell(
        onTap: () => context.push('/species/${species.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen.withValues(alpha: 0.05), AppTheme.primaryGreen.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Encyclopédie Veridia',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'En savoir plus sur le ${species.name}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGreen, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget affichant les alertes de santé basées sur les dernières lectures de capteurs
class _AlertsSection extends StatelessWidget {
  final SensorReading reading; // Les données capteurs à analyser
  const _AlertsSection({required this.reading});

  @override
  Widget build(BuildContext context) {
    final alerts = <String>[];
    if (reading.needsWatering) alerts.add('Le sol est trop sec. Pensez à arroser.');
    if (reading.tooCold) alerts.add('Température trop basse. Protégez votre plante.');
    if (reading.tooHot) alerts.add('Température trop élevée. Déplacez en zone ombragée.');
    if (reading.insufficientLight) alerts.add('Lumière insuffisante. Rapprochez-vous d\'une fenêtre.');

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 18),
              const SizedBox(width: 8),
              Text('Alertes', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w700)),
                Expanded(child: Text(a, style: const TextStyle(color: AppTheme.textDark, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Widget graphique affichant l'évolution de l'humidité du sol
class _SensorChart extends StatelessWidget {
  final List<SensorReading> readings; // Liste historique des données capteurs
  const _SensorChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final displayReadings = readings.take(10).toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EB)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE8F0EB), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: displayReadings.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.soilMoisture);
              }).toList(),
              isCurved: true,
              color: AppTheme.infoBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.infoBlue,
                  strokeColor: Colors.white,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.infoBlue.withValues(alpha: 0.2), AppTheme.infoBlue.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit bouton rond d'action personnalisable
class _ActionButton extends StatelessWidget {
  final IconData icon; // Icône du bouton
  final String label;  // Texte affiché sous l'icône
  final Color? color;  // Couleur principale du bouton
  final VoidCallback onTap; // Action exécutée au clic

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: activeColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: activeColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
