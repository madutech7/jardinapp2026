// Ceci est un test unitaire de base pour un widget Flutter.
//
// Pour interagir avec un widget dans votre test, utilisez l'utilitaire WidgetTester
// fourni par le package flutter_test. Par exemple, vous pouvez simuler des appuis
// et des glissements. Vous pouvez aussi utiliser WidgetTester pour trouver des widgets 
// enfants dans l'arbre des widgets, lire du texte et vérifier leurs propriétés.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jardinapp/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construit notre application et déclenche le rendu d'une image (frame)
    await tester.pumpWidget(const ProviderScope(child: JardinApp()));
    
    // On vérifie simplement que l'application démarre bien en trouvant le MaterialApp principal
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

