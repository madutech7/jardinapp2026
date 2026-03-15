import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth
  static Stream<User?> get userChanges => _auth.userChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  static Future<void> updateProfilePhoto(String photoUrl) async {
    await _auth.currentUser?.updatePhotoURL(photoUrl);
  }

  static Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  static Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }


  // Plants Collection
  static CollectionReference<Map<String, dynamic>> get plantsRef =>
      _firestore.collection('plants');

  static CollectionReference<Map<String, dynamic>> get remindersRef =>
      _firestore.collection('reminders');

  static CollectionReference<Map<String, dynamic>> sensorReadingsRef(String plantId) =>
      _firestore.collection('plants').doc(plantId).collection('sensor_readings');

  static CollectionReference<Map<String, dynamic>> plantNotesRef(String plantId) =>
      _firestore.collection('plants').doc(plantId).collection('notes');

  // Firestore helpers
  static Future<DocumentReference> addDocument(
    CollectionReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    return await ref.add(data);
  }

  static Future<void> updateDocument(
    CollectionReference<Map<String, dynamic>> ref,
    String id,
    Map<String, dynamic> data,
  ) async {
    await ref.doc(id).update(data);
  }

  static Future<void> deleteDocument(
    CollectionReference<Map<String, dynamic>> ref,
    String id,
  ) async {
    await ref.doc(id).delete();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    CollectionReference<Map<String, dynamic>> ref, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
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

class QueryFilter {
  final String field;
  final dynamic value;
  QueryFilter(this.field, this.value);
}
