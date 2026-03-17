// Importation de la bibliothèque 'dart:ui' pour les effets visuels (comme BackdropFilter)
import 'dart:ui';
// Importation du framework Flutter et de ses widgets de base
import 'package:flutter/material.dart';
// Importation de Riverpod pour la gestion de l'état global de l'application
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importation des fichiers nécessaires du projet : thème, fournisseurs d'état, services
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/firebase_service.dart';
import 'package:go_router/go_router.dart';
// Importation pour charger et mettre en cache les images depuis le réseau
import 'package:cached_network_image/cached_network_image.dart';

/// Écran 'Profil' permettant de visualiser les informations de l'utilisateur,
/// ses statistiques générales et d'accéder aux paramètres de l'application.
class ProfileScreen extends ConsumerWidget {
  // Constructeur constant pour optimiser les performances
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute de l'état d'authentification pour obtenir l'utilisateur connecté
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    
    // Écoute des données statistiques du jardin (nombre de plantes, d'espèces, santé moyenne)
    final stats = ref.watch(gardenStatsProvider);
    
    // Écoute des préférences de l'utilisateur (thème sombre/clair, langue, notifications)
    final settings = ref.watch(settingsProvider);
    
    // Vérification de sécurité : si aucun utilisateur n'est connecté, 
    // on affiche une interface vide (un garde de route devrait éviter d'arriver ici)
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Premium Header with Glassmorphism Effect
          SliverToBoxAdapter(
            child: SizedBox(
              height: 420,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Abstract Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          const Color(0xFF1B4332),
                          const Color(0xFF081C15),
                        ],
                      ),
                    ),
                  ),
                  // Background Pattern (Circles)
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  
                  // Profile Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
                            child: user.photoURL == null ? Text(
                              user.email?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGreen,
                              ),
                            ) : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name/Email
                        Text(
                          user.displayName ?? user.email?.split('@')[0] ?? 'Jardinier',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Quick Stats Row in Glassmorphism
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatItem(label: 'Plantes', value: stats.totalPlants.toString()),
                                    _VerticalDivider(),
                                    _StatItem(label: 'Santé Moy.', value: '${stats.averageHealth.toInt()}%'),
                                    _VerticalDivider(),
                                    _StatItem(label: 'Espèces', value: stats.varietiesCount.toString()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Profile Options
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionTitle('Paramètres du compte'),
                const SizedBox(height: 12),
                _ProfileTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Modifier le profil',
                  subtitle: 'Nom, photo, informations personnelles',
                  onTap: () => context.pushNamed('edit-profile'),
                ),
                _ProfileTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Rappels d\'arrosage, alertes santé',
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (v) => ref.read(settingsProvider.notifier).toggleNotifications(v),
                    activeThumbColor: AppTheme.primaryGreen,
                    activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.security_outlined,
                  title: 'Sécurité',
                  subtitle: 'Mot de passe, authentification',
                  onTap: () => context.pushNamed('edit-profile'),
                ),
                const SizedBox(height: 32),
                const _SectionTitle('Préférences'),
                const SizedBox(height: 12),
                _ProfileTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode sombre',
                  trailing: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (v) => ref.read(settingsProvider.notifier).updateThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    activeThumbColor: AppTheme.primaryGreen,
                    activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.language_rounded,
                  title: 'Langue',
                  subtitle: settings.language == 'fr' ? 'Français (France)' : 'English (US)',
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                const SizedBox(height: 32),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () => _confirmSignOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.dangerRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppTheme.dangerRed.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 12),
                        Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: TextButton(
                    onPressed: () => _confirmDeleteAccount(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed.withValues(alpha: 0.6),
                    ),
                    child: const Text('Supprimer mon compte définitvement', 
                      style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Version 2.0.0 • MonJardin',
                    style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue de confirmation avant la déconnexion
  void _confirmSignOut(BuildContext context) async {
    // Attendre le choix de l'utilisateur dans la boîte de dialogue
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion ?'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, déconnexion', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseService.signOut();
  }

  /// Affiche une boîte de dialogue de confirmation avant la suppression définitive du compte
  void _confirmDeleteAccount(BuildContext context) async {
    // Demander la confirmation à travers une boîte de dialogue (dialogue d'alerte)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos plantes et données seront supprimées définitivement.'
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseService.deleteAccount();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
          );
        }
      }
    }
  }

  /// Affiche un menu modal pour sélectionner la langue de l'application
  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    // Affichage d'un panneau glissant (BottomSheet) depuis le bas de l'écran
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisir la langue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Français'),
              trailing: ref.watch(settingsProvider).language == 'fr' ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateLanguage('fr');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: ref.watch(settingsProvider).language == 'en' ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateLanguage('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget privé pour afficher un élément de statistique dans l'en-tête (ex: nombre de plantes)
class _StatItem extends StatelessWidget {
  final String label; // Nom de la statistique (ex: "Plantes")
  final String value; // Valeur associée (ex: "12")
  
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

/// Widget privé pour créer un séparateur vertical stylisé entre les statistiques
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.15));
  }
}

/// Widget privé pour afficher un titre de section dans la liste des options (ex: "Paramètres")
class _SectionTitle extends StatelessWidget {
  final String text; // Le texte du titre
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Widget privé pour créer une tuile de paramètre (option cliquable avec icône)
class _ProfileTile extends StatelessWidget {
  final IconData icon; // Icône à afficher à gauche
  final String title; // Titre principal de l'option
  final String? subtitle; // Sous-titre optionnel
  final Widget? trailing; // Widget personnalisé à afficher à droite (ex: un interrupteur Switch)
  final VoidCallback onTap; // Action exécutée au clic

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.paleGreen.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5)),
      ),
    );
  }
}
