import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../services/firebase_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/plant_model.dart';
import '../../models/species_info.dart';

class AddPlantScreen extends ConsumerStatefulWidget {
  const AddPlantScreen({super.key});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _acquisitionDate = DateTime.now();
  File? _selectedImage;
  bool _loading = false;
  SpeciesInfo? _matchedSpecies;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
    if (mounted) Navigator.pop(context);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquisitionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _acquisitionDate = picked);
  }

  void _onSpeciesChanged(String value) {
    final match = SpeciesDatabase.findByName(value);
    setState(() => _matchedSpecies = match);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      String? photoUrl;
      if (_selectedImage != null) {
        final path = 'plants/${user.uid}/${const Uuid().v4()}.jpg';
        photoUrl = await CloudinaryService.uploadImage(_selectedImage!, path);
      }

      final plant = PlantModel(
        id: '',
        userId: user.uid,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        photoUrl: photoUrl,
        acquisitionDate: _acquisitionDate,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        healthScore: 80,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.addDocument(FirebaseService.plantsRef, plant.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plante ajoutée avec succès !'), backgroundColor: AppTheme.lightGreen),
        );
        context.go('/garden');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            collapsedHeight: 60,
            toolbarHeight: 60,
            pinned: true,
            backgroundColor: AppTheme.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textDark),
              onPressed: () => context.pop(),
            ),
            title: const Text('Nouvelle Plante', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800)),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sauver', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Photo picker
                _AnimatedField(
                  index: 0,
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      margin: const EdgeInsets.only(bottom: 32),
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
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen, size: 48),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ajouter une magnifique photo',
                                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                                ),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.all(24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Changer la photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _AnimatedField(index: 1, child: _SectionLabel('Informations générales')),
                      const SizedBox(height: 12),
                      _AnimatedField(
                        index: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nom de la plante *', prefixIcon: Icon(Icons.spa_outlined)),
                          validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedField(
                        index: 3,
                        child: TextFormField(
                          controller: _speciesController,
                          decoration: const InputDecoration(labelText: 'Espèce / Variété *', prefixIcon: Icon(Icons.local_florist_outlined)),
                          onChanged: _onSpeciesChanged,
                          validator: (v) => v == null || v.isEmpty ? 'Espèce requise' : null,
                        ),
                      ),
                      if (_matchedSpecies != null) ...[
                        const SizedBox(height: 8),
                        _AnimatedField(
                          index: 4,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.paleGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Espèce reconnue : ${_matchedSpecies!.name}',
                                    style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _AnimatedField(
                        index: 5,
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Date d\'acquisition',
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                hintText: DateFormat('dd/MM/yyyy').format(_acquisitionDate),
                              ),
                              controller: TextEditingController(
                                text: DateFormat('dd/MM/yyyy').format(_acquisitionDate),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedField(
                        index: 6,
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Emplacement (optionnel)', prefixIcon: Icon(Icons.location_on_outlined)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedField(
                        index: 7,
                        child: TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Description (optionnel)', prefixIcon: Icon(Icons.notes_outlined)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900));
  }
}

class _AnimatedField extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedField({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
