import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/sensor_reading.dart';
import '../../services/firebase_service.dart';
import '../../widgets/sensor_gauge.dart';

class SensorReadingsScreen extends ConsumerWidget {
  final String plantId;
  const SensorReadingsScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(sensorReadingsProvider(plantId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Historique Capteurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: readingsAsync.when(
        data: (readings) {
          if (readings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors_off_outlined, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text('Aucune lecture enregistrée', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: readings.length,
            itemBuilder: (context, index) => Dismissible(
              key: Key(readings[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la lecture ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                await FirebaseService.deleteDocument(
                  FirebaseService.sensorReadingsRef(plantId),
                  readings[index].id,
                );
              },
              child: _ReadingCard(reading: readings[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final SensorReading reading;
  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EB)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('dd MMM yyyy – HH:mm', 'fr').format(reading.timestamp),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.healthColor(reading.healthScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${reading.healthScore.toInt()}% santé',
                  style: TextStyle(
                    color: AppTheme.healthColor(reading.healthScore),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SensorGauge(label: 'Humidité', value: reading.soilMoisture, unit: '%', icon: Icons.water_drop_outlined, color: AppTheme.infoBlue, isAlert: reading.needsWatering)),
              const SizedBox(width: 10),
              Expanded(child: SensorGauge(label: 'Temp.', value: reading.temperature, unit: '°C', icon: Icons.thermostat_outlined, color: AppTheme.earthBrown, isAlert: reading.tooCold || reading.tooHot, max: 40)),
              const SizedBox(width: 10),
              Expanded(child: SensorGauge(label: 'Lumière', value: reading.light, unit: '%', icon: Icons.wb_sunny_outlined, color: AppTheme.warningAmber, isAlert: reading.insufficientLight)),
            ],
          ),
          if (reading.notes != null && reading.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(reading.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
