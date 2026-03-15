import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/plant_note.dart';
import '../../services/firebase_service.dart';
import '../../services/cloudinary_service.dart';

class PlantNotesScreen extends ConsumerStatefulWidget {
  final String plantId;
  const PlantNotesScreen({super.key, required this.plantId});

  @override
  ConsumerState<PlantNotesScreen> createState() => _PlantNotesScreenState();
}

class _PlantNotesScreenState extends ConsumerState<PlantNotesScreen> {
  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddNoteSheet(plantId: widget.plantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(plantNotesProvider(widget.plantId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notes & Observations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteSheet,
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: AppTheme.paleGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_note_rounded, size: 48, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text('Aucune note', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Appuyez sur + pour ajouter une observation', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
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
                child: Dismissible(
                  key: Key(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppTheme.dangerRed, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Supprimer la note ?'),
                        content: const Text('Cette action est irréversible.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    await FirebaseService.deleteDocument(
                      FirebaseService.plantNotesRef(widget.plantId),
                      note.id,
                    );
                  },
                  child: _NoteCard(note: note),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final PlantNote note;
  const _NoteCard({required this.note});

  Color get _typeColor {
    switch (note.type) {
      case NoteType.problem:
        return AppTheme.dangerRed;
      case NoteType.treatment:
        return AppTheme.infoBlue;
      case NoteType.observation:
        return AppTheme.warningAmber;
      case NoteType.general:
        return AppTheme.primaryGreen;
    }
  }

  String get _typeLabel {
    switch (note.type) {
      case NoteType.problem:
        return 'Problème';
      case NoteType.treatment:
        return 'Traitement';
      case NoteType.observation:
        return 'Observation';
      case NoteType.general:
        return 'Général';
    }
  }

  IconData get _typeIcon {
    switch (note.type) {
      case NoteType.problem:
        return Icons.bug_report_outlined;
      case NoteType.treatment:
        return Icons.medical_services_outlined;
      case NoteType.observation:
        return Icons.visibility_outlined;
      case NoteType.general:
        return Icons.notes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _typeColor.withValues(alpha: 0.2)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_typeIcon, color: _typeColor, size: 16),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_typeLabel, style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy', 'fr').format(note.createdAt),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Text(note.content, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
                if (note.photoUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: note.photoUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNoteSheet extends ConsumerStatefulWidget {
  final String plantId;
  const _AddNoteSheet({required this.plantId});

  @override
  ConsumerState<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<_AddNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  NoteType _selectedType = NoteType.general;
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      String? photoUrl;
      if (_selectedImage != null) {
        final path = 'notes/${widget.plantId}/${const Uuid().v4()}.jpg';
        photoUrl = await CloudinaryService.uploadImage(_selectedImage!, path);
      }

      final note = PlantNote(
        id: '',
        plantId: widget.plantId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await FirebaseService.addDocument(
        FirebaseService.plantNotesRef(widget.plantId),
        note.toFirestore(),
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Nouvelle note', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          // Type selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NoteType.values.map((type) {
                final selected = type == _selectedType;
                final color = selected ? AppTheme.primaryGreen : AppTheme.textMuted;
                final label = {
                  NoteType.general: 'Général',
                  NoteType.problem: 'Problème',
                  NoteType.treatment: 'Traitement',
                  NoteType.observation: 'Observation',
                }[type]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.paleGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey[300]!),
                      ),
                      child: Text(label, style: TextStyle(color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre', prefixIcon: Icon(Icons.title_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Photo'),
                style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check_circle, color: AppTheme.lightGreen, size: 18),
                const SizedBox(width: 4),
                const Text('Photo ajoutée', style: TextStyle(color: AppTheme.lightGreen, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Enregistrer la note'),
          ),
        ],
      ),
    );
  }
}
