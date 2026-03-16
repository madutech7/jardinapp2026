import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/reminder.dart';
import '../../services/firebase_service.dart';

/// Écran 'Rappels' affichant la liste des tâches à accomplir (arrosage, engrais, etc.)
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  /// Affiche le formulaire (BottomSheet) pour ajouter un nouveau rappel
  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Écoute des rappels depuis le fournisseur (provider) asynchrone
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderSheet,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add_task_rounded, size: 24),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          // Tri et filtrage des rappels en différentes catégories
          // Rappels dont la date est dépassée
          final overdue = reminders.where((r) => r.isOverdue).toList();
          // Rappels prévus pour aujourd'hui
          final dueToday = reminders.where((r) => r.isDueToday).toList();
          // Rappels futurs non terminés
          final upcoming = reminders.where((r) => !r.isOverdue && !r.isDueToday && !r.isCompleted).toList();
          // Rappels déjà terminés
          final completed = reminders.where((r) => r.isCompleted).toList();

          return CustomScrollView(
            slivers: [
              // Stunning Header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withValues(alpha: 0.8),
                        const Color(0xFF1B4332),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rappels',
                                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${reminders.where((r) => !r.isCompleted).length} tâches en attente',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                                  onPressed: () {},
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

              if (reminders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tout est à jour !',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aucun rappel pour le moment.\nProfitez de votre jardin !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (overdue.isNotEmpty) ...[
                        _SectionHeader('En retard', count: overdue.length, color: AppTheme.dangerRed),
                        ...overdue.map((r) => _ReminderCard(reminder: r, plantId: r.plantId)),
                        const SizedBox(height: 24),
                      ],
                      if (dueToday.isNotEmpty) ...[
                        _SectionHeader("Aujourd'hui", count: dueToday.length, color: AppTheme.warningAmber),
                        ...dueToday.map((r) => _ReminderCard(reminder: r, plantId: r.plantId)),
                        const SizedBox(height: 24),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _SectionHeader('À venir', count: upcoming.length, color: AppTheme.primaryGreen),
                        ...upcoming.map((r) => _ReminderCard(reminder: r, plantId: r.plantId)),
                        const SizedBox(height: 24),
                      ],
                      if (completed.isNotEmpty) ...[
                        _SectionHeader('Terminés', count: completed.length, color: AppTheme.textMuted),
                        ...completed.map((r) => _ReminderCard(reminder: r, plantId: r.plantId)),
                      ],
                    ]),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

/// En-tête de section pour les différentes listes de rappels (ex: "En retard", "Aujourd'hui")
class _SectionHeader extends StatelessWidget {
  final String title; // Titre de la section
  final int count; // Nombre d'éléments dans la section
  final Color color; // Couleur de la section

  const _SectionHeader(this.title, {required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget privé représentant une carte pour un rappel spécifique
class _ReminderCard extends ConsumerWidget {
  final Reminder reminder; // L'objet rappel contenant les données
  final String plantId; // ID de la plante associée
  const _ReminderCard({required this.reminder, required this.plantId});

  /// Détermine la couleur de l'icône selon le type de rappel
  Color get _typeColor {
    switch (reminder.type) {
      case ReminderType.watering:
        return AppTheme.infoBlue;
      case ReminderType.fertilization:
        return const Color(0xFF7B5EA7);
      case ReminderType.pruning:
        return AppTheme.earthBrown;
      case ReminderType.repotting:
        return const Color(0xFF6B8E23);
      case ReminderType.treatment:
        return AppTheme.dangerRed;
      case ReminderType.other:
        return AppTheme.textMuted;
    }
  }

  /// Détermine l'icône selon le type de rappel
  IconData get _typeIcon {
    switch (reminder.type) {
      case ReminderType.watering:
        return Icons.water_drop_outlined;
      case ReminderType.fertilization:
        return Icons.eco_outlined;
      case ReminderType.pruning:
        return Icons.content_cut_outlined;
      case ReminderType.repotting:
        return Icons.yard_outlined;
      case ReminderType.treatment:
        return Icons.medical_services_outlined;
      case ReminderType.other:
        return Icons.notifications_outlined;
    }
  }  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = reminder.isCompleted
        ? AppTheme.textMuted
        : reminder.isOverdue
            ? AppTheme.dangerRed
            : reminder.isDueToday
                ? AppTheme.warningAmber
                : AppTheme.primaryGreen;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.dangerRed, size: 28),
      ),
      onDismissed: (_) async {
        await FirebaseService.deleteDocument(FirebaseService.remindersRef, reminder.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_typeIcon, color: _typeColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: reminder.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                               reminder.plantName,
                               style: TextStyle(
                                 color: AppTheme.textMuted.withValues(alpha: 0.8),
                                 fontSize: 13,
                                 fontWeight: FontWeight.w500,
                               ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 12, color: statusColor.withValues(alpha: 0.7)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'fr_FR').format(reminder.nextDueDate),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interaction Area
                      if (!reminder.isCompleted)
                        GestureDetector(
                          onTap: () async {
                            await FirebaseService.updateDocument(
                              FirebaseService.remindersRef,
                              reminder.id,
                              {'isCompleted': true},
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE8F0EB), width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                         Container(
                           width: 32,
                           height: 32,
                           decoration: const BoxDecoration(
                             color: AppTheme.lightGreen,
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                         ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add Reminder Sheet
/// Panneau (BottomSheet) affichant le formulaire de création d'un nouveau rappel
class _AddReminderSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  // Contrôleurs pour les champs de saisie de texte
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Variables d'état pour les champs du formulaire
  ReminderType _type = ReminderType.watering;
  ReminderFrequency _frequency = ReminderFrequency.weekly;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedPlantId;
  String _selectedPlantName = '';
  
  // Indicateur de chargement
  bool _loading = false;

  /// Sauvegarde du nouveau rappel dans Firebase
  Future<void> _save() async {
    // Vérification des champs requis
    if (_titleController.text.isEmpty || _selectedPlantId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final reminder = Reminder(
        id: '',
        plantId: _selectedPlantId!,
        plantName: _selectedPlantName,
        type: _type,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        nextDueDate: _dueDate,
        frequency: _frequency,
        createdAt: DateTime.now(),
      );

      final data = reminder.toFirestore();
      data['userId'] = user.uid;
      await FirebaseService.addDocument(FirebaseService.remindersRef, data);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(plantsStreamProvider).value ?? [];

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Nouveau rappel', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            // Plant picker
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Plante', prefixIcon: Icon(Icons.yard_outlined)),
              initialValue: _selectedPlantId,
              items: plants.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedPlantId = v;
                  _selectedPlantName = plants.firstWhere((p) => p.id == v).name;
                });
              },
              hint: const Text('Sélectionner une plante'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre du rappel', prefixIcon: Icon(Icons.title_rounded)),
            ),
            const SizedBox(height: 14),
            // Type picker
            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderType.values.map((t) {
                final labels = {
                  ReminderType.watering: 'Arrosage',
                  ReminderType.fertilization: 'Engrais',
                  ReminderType.pruning: 'Taille',
                  ReminderType.repotting: 'Rempotage',
                  ReminderType.treatment: 'Traitement',
                  ReminderType.other: 'Autre',
                };
                final selected = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey[300]!),
                    ),
                    child: Text(labels[t]!, style: TextStyle(color: selected ? Colors.white : AppTheme.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // Frequency
            DropdownButtonFormField<ReminderFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Fréquence', prefixIcon: Icon(Icons.repeat_rounded)),
              items: [
                const DropdownMenuItem(value: ReminderFrequency.once, child: Text('Une seule fois')),
                const DropdownMenuItem(value: ReminderFrequency.daily, child: Text('Quotidien')),
                const DropdownMenuItem(value: ReminderFrequency.weekly, child: Text('Hebdomadaire')),
                const DropdownMenuItem(value: ReminderFrequency.biweekly, child: Text('Bi-hebdomadaire')),
                const DropdownMenuItem(value: ReminderFrequency.monthly, child: Text('Mensuel')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date prévue',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: DateFormat('dd/MM/yyyy').format(_dueDate),
                  ),
                  controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_dueDate)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_loading || _selectedPlantId == null) ? null : _save,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Créer le rappel'),
            ),
          ],
        ),
      ),
    );
  }
}
