import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Représente l'état immuable des paramètres de l'application.
class SettingsState {
  final ThemeMode themeMode; // Mode sombre, clair ou système
  final String language; // Code langue (ex: 'fr', 'en')
  final bool notificationsEnabled; // Si les notifications sont activées

  SettingsState({
    required this.themeMode,
    required this.language,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

/// Fournisseur Riverpod permettant d'accéder et de modifier l'état des paramètres.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Charge les paramètres sauvegardés de manière asynchrone
    _loadSettings();
    // Retourne un état par défaut propre en attendant le chargement
    return SettingsState(
      themeMode: ThemeMode.light,
      language: 'fr',
      notificationsEnabled: true,
    );
  }

  // Clés utilisées pour le stockage local via SharedPreferences
  static const _themeKey = 'theme_mode';
  static const _langKey = 'language';
  static const _notifKey = 'notifications';

  /// Charge les paramètres depuis le stockage persistant de l'appareil
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // 1 correspond à ThemeMode.light par défaut (0: system, 1: light, 2: dark)
    final themeIndex = prefs.getInt(_themeKey) ?? 1; 
    final language = prefs.getString(_langKey) ?? 'fr';
    final notifications = prefs.getBool(_notifKey) ?? true;

    state = SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      language: language,
      notificationsEnabled: notifications,
    );
  }

  /// Met à jour le thème et sauvegarde la préférence
  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  /// Met à jour la langue de l'application et sauvegarde la préférence
  Future<void> updateLanguage(String lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  /// Active ou désactive les notifications et sauvegarde la préférence
  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, enabled);
  }
}
