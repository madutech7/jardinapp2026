import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service centralisant toutes les interactions avec Firebase (Authentification et Base de données Firestore)
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === Authentification (Auth) ===
  /// Écoute les changements d'état de connexion de l'utilisateur en temps réel
  static Stream<User?> get userChanges => _auth.userChanges();
  /// Récupère l'utilisateur actuellement connecté de manière synchrone
  static User? get currentUser => _auth.currentUser;

  /// Connecte un utilisateur existant avec email et mot de passe
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Crée un nouveau compte utilisateur avec email et mot de passe
  static Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Met à jour le nom d'affichage de l'utilisateur connecté
  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Met à jour la photo de profil de l'utilisateur connecté (via une URL)
  static Future<void> updateProfilePhoto(String photoUrl) async {
    await _auth.currentUser?.updatePhotoURL(photoUrl);
  }

  /// Modifie le mot de passe de l'utilisateur
  static Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Supprime définitivement le compte utilisateur
  static Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Déconnecte l'utilisateur actuel
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envoie un email à l'utilisateur pour réinitialiser son mot de passe
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }


  // === Accès aux collections Firestore ===
  
  /// Référence à la collection 'plants' globale
  static CollectionReference<Map<String, dynamic>> get plantsRef =>
      _firestore.collection('plants');

  /// Référence à la collection 'reminders' globale
  static CollectionReference<Map<String, dynamic>> get remindersRef =>
      _firestore.collection('reminders');

  /// Référence à la sous-collection 'sensor_readings' pour une plante spécifique
  static CollectionReference<Map<String, dynamic>> sensorReadingsRef(String plantId) =>
      _firestore.collection('plants').doc(plantId).collection('sensor_readings');

  /// Référence à la sous-collection 'notes' pour une plante spécifique
  static CollectionReference<Map<String, dynamic>> plantNotesRef(String plantId) =>
      _firestore.collection('plants').doc(plantId).collection('notes');

  // === Fonctions utilitaires CRUD (Create, Read, Update, Delete) pour Firestore ===

  /// Ajoute un nouveau document généré automatiquement avec ses données
  static Future<DocumentReference> addDocument(
    CollectionReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    return await ref.add(data);
  }

  /// Met à jour un document existant identifié par son [id]
  static Future<void> updateDocument(
    CollectionReference<Map<String, dynamic>> ref,
    String id,
    Map<String, dynamic> data,
  ) async {
    await ref.doc(id).update(data);
  }

  /// Supprime le document correspondant à l'[id] spécifié
  static Future<void> deleteDocument(
    CollectionReference<Map<String, dynamic>> ref,
    String id,
  ) async {
    await ref.doc(id).delete();
  }

  /// Récupère un flux (Stream) de données depuis une collection avec des filtres optionnels.
  /// Pratique pour s'abonner aux changements en temps réel (Read).
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    CollectionReference<Map<String, dynamic>> ref, {
    List<QueryFilter>? filters, // Liste de conditions d'égalité
    String? orderBy, // Champ à utiliser pour le tri
    bool descending = false, // Ordre décroissant si vrai
    int? limit, // Nombre maximum de documents à retourner
  }) {
    Query<Map<String, dynamic>> query = ref;
    if (filters != null) {
      for (final f in filters) {
        query = query.where(f.field, isEqualTo: f.value);
      }
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }
}

/// Classe utilitaire représentant un filtre d'égalité simple pour une requête Firestore
class QueryFilter {
  final String field; // Le nom du champ ciblé
  final dynamic value; // La valeur à comparer (doit être égale)
  QueryFilter(this.field, this.value);
}
