import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/plant_card.dart';
import '../../models/reminder.dart';

/// Écran principal "Jardin" affichant le tableau de bord, les statistiques globales et la liste des plantes de l'utilisateur
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des données du jardin en temps réel via les fournisseurs d'état (providers)
    final plantsAsync = ref.watch(plantsStreamProvider);
    final stats = ref.watch(gardenStatsProvider);
    final overdueReminders = ref.watch(overdueRemindersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8), // From design / Couleur de fond inspirée du design MonJardin
      body: CustomScrollView(
        slivers: [
          // En-tête unifié et zone du tableau de bord (Header)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.paleGreen.withValues(alpha: 0.8),
                    AppTheme.paleGreen.withValues(alpha: 0.2),
                    const Color(0xFFF7FAF8),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTimeGreeting(),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Text(
                                  'Mon Jardin',
                                  style: TextStyle(
                                    color: AppTheme.darkGreen,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.search_rounded, color: AppTheme.textDark, size: 24),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: ref.watch(currentUserProvider)?.photoURL != null
                                        ? CachedNetworkImage(
                                            imageUrl: ref.watch(currentUserProvider)!.photoURL!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                            errorWidget: (context, url, error) => const Icon(Icons.person, color: AppTheme.primaryGreen),
                                          )
                                        : const CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.person, color: AppTheme.primaryGreen, size: 22),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _MonJardinDashboard(
                    stats: stats,
                    pendingCount: overdueReminders.length +
                        ref.watch(pendingRemindersProvider).length,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Titre de la section
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Mes Plantes',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark),
              ),
            ),
          ),
          // Grille affichant la liste des plantes de l'utilisateur
          plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyGarden());
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plant = plants[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600 + (index * 150)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: PlantCard(plant: plant),
                      );
                    },
                    childCount: plants.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShimmerCard(),
                  childCount: 4,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
              ),
            ),
            error: (e, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: _RecommendedTasks(reminders: ref.watch(pendingRemindersProvider)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plant/add'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// Génère un message d'accueil dynamique en fonction de l'heure locale
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }
}

/// Widget privé affichant le tableau de bord global "MonJardin" (Statistiques et anneau de santé global)
class _MonJardinDashboard extends StatelessWidget {
  final GardenStats stats; // Les statistiques globales
  final int pendingCount;  // Le nombre de tâches en attente

  const _MonJardinDashboard({required this.stats, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Mon Jardin',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'État Global',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, size: 16, color: AppTheme.warningAmber),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pendingCount rappels',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: stats.averageHealth / 100),
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _GradientRingPainter(
                          progress: value,
                          primaryColor: AppTheme.primaryGreen,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.averageHealth.toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'SANTÉ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dessinateur personnalisé (CustomPainter) pour tracer l'anneau de santé en dégradé
class _GradientRingPainter extends CustomPainter {
  final double progress; // Niveau de complétion de l'anneau (0.0 à 1.0)
  final Color primaryColor; // Couleur principale du tracé

  _GradientRingPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Dessin du cercle d'arrière-plan semi-transparent
    final bgPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Dessin de l'arc de progression avec un dégradé (SweepGradient) coloré
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final progPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.6),
          primaryColor,
          primaryColor,
          primaryColor.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
        transform: const GradientRotation(-1.57),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -1.57, progress * 2 * 3.14159, false, progPaint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Widget privé affichant une liste horizontale de tâches recommandées (rappels)
class _RecommendedTasks extends StatelessWidget {
  final List<Reminder> reminders; // Liste des tâches recommandées à afficher
  const _RecommendedTasks({required this.reminders});

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.watering: return Icons.water_drop_outlined;
      case ReminderType.fertilization: return Icons.eco_outlined;
      case ReminderType.pruning: return Icons.content_cut_outlined;
      case ReminderType.repotting: return Icons.yard_outlined;
      case ReminderType.treatment: return Icons.medical_services_outlined;
      case ReminderType.other: return Icons.notifications_none;
    }
  }

  /// Formate et renvoie le texte combiné de l'action et du nom de la plante
  String _getTaskString(Reminder r) {
    final act = {
      ReminderType.watering: 'Arroser',
      ReminderType.fertilization: 'Fertiliser',
      ReminderType.pruning: 'Tailler',
      ReminderType.repotting: 'Rempoter',
      ReminderType.treatment: 'Traiter',
      ReminderType.other: 'Vérifier',
    }[r.type]!;
    
    // Tente d'extraire le prénom ou le premier mot du nom de la plante (ex: "Léo" dans Ficus "Léo")
    final nicknameMatch = RegExp(r'"([^"]*)"').firstMatch(r.plantName);
    final plantName = nicknameMatch != null ? nicknameMatch.group(1)! : r.plantName.split(' ').first;
    return '$act $plantName';
  }

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tâches recommandées',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: reminders.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final r = reminders[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.paleGreen.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                      ),
                      child: Icon(_getTypeIcon(r.type), size: 14, color: AppTheme.lightGreen),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTaskString(r),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Vue affichée lorsque l'utilisateur n'a ajouté aucune plante à son jardin
class _EmptyGarden extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F0EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.yard_outlined, size: 48, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          Text('Votre jardin est vide', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter votre première plante pour suivre sa santé',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Effet visuel temporaire (squelette gris) affiché pendant le chargement des plantes
class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
