import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant_model.dart';
import '../models/sensor_reading.dart';
import '../models/plant_note.dart';

/// Gestionnaire SQLite pour la copie locale (cache/hors-ligne) des données
class LocalDatabase {
  static Database? _db; // Instance unique (Singleton) de la base de données
  static const _dbName = 'jardinapp.db'; // Nom du fichier de la base SQLite
  static const _dbVersion = 1; // Version (utile pour les migrations futures)

  /// Récupère l'instance de la base de données ou l'initialise si elle n'existe pas
  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  /// Initialise la base de données : crée le fichier et ouvre la connexion
  static Future<Database> _initDb() async {
    // getDatabasesPath() récupère le chemin sécurisé de stockage propre à l'OS (iOS ou Android)
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Exécuté une seule fois lors de la création initiale du fichier de base de données
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        photoUrl TEXT,
        acquisitionDate INTEGER NOT NULL,
        location TEXT,
        description TEXT,
        healthScore REAL NOT NULL DEFAULT 80,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sensor_readings (
        id TEXT PRIMARY KEY,
        plantId TEXT NOT NULL,
        soilMoisture REAL NOT NULL,
        temperature REAL NOT NULL,
        light REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (plantId) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_notes (
        id TEXT PRIMARY KEY,
        plantId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        photoUrl TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (plantId) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');
  }

  // === Opérations CRUD sur les Plantes (Plants) ===

  /// Insère une plante ou la met à jour si elle existe déjà (basé sur l'id)
  static Future<void> upsertPlant(PlantModel plant) async {
    final db = await database;
    await db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les plantes mises en cache pour un utilisateur spécifique
  static Future<List<PlantModel>> getPlants(String userId) async {
    final db = await database;
    final maps = await db.query(
      'plants',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(PlantModel.fromMap).toList();
  }

  /// Récupère une plante spécifique depuis le cache local via son identifiant
  static Future<PlantModel?> getPlant(String id) async {
    final db = await database;
    final maps = await db.query('plants', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return PlantModel.fromMap(maps.first);
  }

  /// Supprime définitivement une plante du cache local
  static Future<void> deletePlant(String id) async {
    final db = await database;
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  // === Opérations sur les lectures de capteurs (Sensor Readings) ===

  /// Sauvegarde une nouvelle lecture de capteur
  static Future<void> upsertSensorReading(SensorReading reading) async {
    final db = await database;
    await db.insert(
      'sensor_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère l'historique récent (limité à [limit]) des capteurs d'une plante
  static Future<List<SensorReading>> getSensorReadings(String plantId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'sensor_readings',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(SensorReading.fromMap).toList();
  }

  static Future<void> deleteSensorReading(String id) async {
    final db = await database;
    await db.delete('sensor_readings', where: 'id = ?', whereArgs: [id]);
  }

  // === Opérations sur les notes/journal (Plant Notes) ===
  
  /// Ajoute ou met à jour une note pour une plante
  static Future<void> upsertNote(PlantNote note) async {
    final db = await database;
    await db.insert(
      'plant_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les notes classées par date de création (les plus récentes en premier)
  static Future<List<PlantNote>> getNotes(String plantId) async {
    final db = await database;
    final maps = await db.query(
      'plant_notes',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(PlantNote.fromMap).toList();
  }

  /// Supprime une note spécifique du cache local
  static Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('plant_notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Ferme la connexion à la base de données (utile pour libérer les ressources, par ex pendant les tests)
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
