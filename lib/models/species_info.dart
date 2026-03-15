class SpeciesInfo {
  final String id;
  final String name;
  final String scientificName;
  final String family;
  final String description;
  final String wateringNeeds; // 'low', 'medium', 'high'
  final String lightNeeds; // 'low', 'medium', 'high', 'direct'
  final String soilType;
  final String humidity; // 'low', 'medium', 'high'
  final double minTemp;
  final double maxTemp;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? imageUrl;
  final List<String> commonProblems;
  final List<String> careTips;

  SpeciesInfo({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.wateringNeeds,
    required this.lightNeeds,
    required this.soilType,
    required this.humidity,
    required this.minTemp,
    required this.maxTemp,
    required this.difficulty,
    this.imageUrl,
    required this.commonProblems,
    required this.careTips,
  });

  factory SpeciesInfo.fromMap(Map<String, dynamic> map) {
    return SpeciesInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      family: map['family'] ?? '',
      description: map['description'] ?? '',
      wateringNeeds: map['wateringNeeds'] ?? 'medium',
      lightNeeds: map['lightNeeds'] ?? 'medium',
      soilType: map['soilType'] ?? '',
      humidity: map['humidity'] ?? 'medium',
      minTemp: (map['minTemp'] ?? 15).toDouble(),
      maxTemp: (map['maxTemp'] ?? 30).toDouble(),
      difficulty: map['difficulty'] ?? 'medium',
      imageUrl: map['imageUrl'],
      commonProblems: List<String>.from(map['commonProblems'] ?? []),
      careTips: List<String>.from(map['careTips'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'family': family,
      'description': description,
      'wateringNeeds': wateringNeeds,
      'lightNeeds': lightNeeds,
      'soilType': soilType,
      'humidity': humidity,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
      'commonProblems': commonProblems,
      'careTips': careTips,
    };
  }
}

// Built-in species database
class SpeciesDatabase {
  static final List<SpeciesInfo> species = [
    SpeciesInfo(
      id: 'baobab',
      name: 'Baobab',
      scientificName: 'Adansonia digitata',
      family: 'Malvaceae',
      description: 'L\'emblème du Sénégal. Un arbre majestueux et sacré qui peut vivre des millénaires et stocker des milliers de litres d\'eau.',
      wateringNeeds: 'low',
      lightNeeds: 'direct',
      soilType: 'Sol sablonneux bien drainé',
      humidity: 'low',
      minTemp: 15,
      maxTemp: 45,
      difficulty: 'easy',
      commonProblems: ['Pourriture des racines (excès d\'eau)', 'Cochenilles'],
      careTips: ['Arroser très peu en saison sèche', 'Plein soleil obligatoire', 'Ne supporte pas le gel'],
    ),
    SpeciesInfo(
      id: 'manguier',
      name: 'Manguier',
      scientificName: 'Mangifera indica',
      family: 'Anacardiaceae',
      description: 'Arbre fruitier tropical produisant des mangues succulentes. Très commun en Casamance et dans les Niayes.',
      wateringNeeds: 'medium',
      lightNeeds: 'direct',
      soilType: 'Sol profond et riche',
      humidity: 'medium',
      minTemp: 18,
      maxTemp: 40,
      difficulty: 'medium',
      commonProblems: ['Oïdium', 'Mouche de la mangue', 'Anthracnose'],
      careTips: ['Taille régulière après récolte', 'Apport de compost organique', 'Arrosage régulier pour les jeunes sujets'],
    ),
    SpeciesInfo(
      id: 'bissap',
      name: 'Bissap',
      scientificName: 'Hibiscus sabdariffa',
      family: 'Malvaceae',
      description: 'Plante dont les calices rouges sont utilisés pour préparer la célèbre boisson nationale du Sénégal.',
      wateringNeeds: 'medium',
      lightNeeds: 'high',
      soilType: 'Sol léger et riche',
      humidity: 'medium',
      minTemp: 20,
      maxTemp: 35,
      difficulty: 'easy',
      commonProblems: ['Pucerons', 'Altises'],
      careTips: ['Arrosage régulier sans excès', 'Récolter les calices quand ils sont charnus', 'Aime la chaleur'],
    ),
    SpeciesInfo(
      id: 'bougainvillea',
      name: 'Bougainvillier',
      scientificName: 'Bougainvillea',
      family: 'Nyctaginaceae',
      description: 'Arbuste grimpant aux couleurs éclatantes (violet, rouge, orange), omniprésent dans les jardins sénégalais.',
      wateringNeeds: 'low',
      lightNeeds: 'direct',
      soilType: 'Tout type de sol drainant',
      humidity: 'low',
      minTemp: 10,
      maxTemp: 40,
      difficulty: 'easy',
      commonProblems: ['Araignées rouges', 'Pucerons'],
      careTips: ['Tailler pour favoriser la floraison', 'Peu d\'eau favorise les fleurs', 'Plein soleil incontournable'],
    ),
    SpeciesInfo(
      id: 'neem',
      name: 'Neem',
      scientificName: 'Azadirachta indica',
      family: 'Meliaceae',
      description: 'Arbre protecteur réputé pour ses vertus médicinales (paludisme) et ses propriétés pesticides naturelles.',
      wateringNeeds: 'low',
      lightNeeds: 'direct',
      soilType: 'Sol pauvre ou caillouteux',
      humidity: 'low',
      minTemp: 12,
      maxTemp: 48,
      difficulty: 'easy',
      commonProblems: ['Cochenilles farineuses', 'Excès d\'humidité'],
      careTips: ['Très résistant à la sécheresse', 'Tailler les branches basses', 'Produit une ombre protectrice'],
    ),
    SpeciesInfo(
      id: 'flamboyant',
      name: 'Flamboyant',
      scientificName: 'Delonix regia',
      family: 'Fabaceae',
      description: 'Un des plus beaux arbres du monde avec sa floraison rouge éclatante marquant le début de l\'hivernage.',
      wateringNeeds: 'medium',
      lightNeeds: 'direct',
      soilType: 'Sol riche et léger',
      humidity: 'medium',
      minTemp: 15,
      maxTemp: 35,
      difficulty: 'medium',
      commonProblems: ['Termites', 'Champignons racinaires'],
      careTips: ['Prévoir beaucoup d\'espace', 'Arrosage régulier pendant la croissance', 'Lumière vive'],
    ),
    SpeciesInfo(
      id: 'gommier',
      name: 'Gommier',
      scientificName: 'Acacia senegal',
      family: 'Fabaceae',
      description: 'Arbre du Sahel produisant la gomme arabique. Crucial pour la lutte contre la désertification.',
      wateringNeeds: 'low',
      lightNeeds: 'direct',
      soilType: 'Sol sableux ou aride',
      humidity: 'low',
      minTemp: 10,
      maxTemp: 50,
      difficulty: 'medium',
      commonProblems: ['Sauterelles', 'Termites'],
      careTips: ['Demande très peu d\'entretien', 'Plein soleil', 'Aide à enrichir le sol en azote'],
    ),
    SpeciesInfo(
      id: 'palmier_huile',
      name: 'Palmier à huile',
      scientificName: 'Elaeis guineensis',
      family: 'Arecaceae',
      description: 'Typique de la Casamance, ce palmier produit les noix pour l\'huile de palme et le vin de palme.',
      wateringNeeds: 'high',
      lightNeeds: 'high',
      soilType: 'Sol profond et humide',
      humidity: 'high',
      minTemp: 22,
      maxTemp: 35,
      difficulty: 'medium',
      commonProblems: ['Fusariose', 'Rongeurs'],
      careTips: ['Aime les zones humides', 'Protéger le bourgeon terminal', 'Besoin de beaucoup de lumière'],
    ),
    SpeciesInfo(
      id: 'fromager',
      name: 'Fromager',
      scientificName: 'Ceiba pentandra',
      family: 'Malvaceae',
      description: 'Arbre géant aux racines impressionnantes, souvent considéré comme un arbre à palabres sacré au Sénégal.',
      wateringNeeds: 'high',
      lightNeeds: 'high',
      soilType: 'Sol alluvionnaire riche',
      humidity: 'high',
      minTemp: 18,
      maxTemp: 35,
      difficulty: 'hard',
      commonProblems: ['Chenilles leaf-roller', 'Taches foliaires'],
      careTips: ['Croissance extrêmement rapide', 'Nécessite énormément d\'espace', 'Symbolique forte'],
    ),
    SpeciesInfo(
      id: 'citronnier',
      name: 'Citronnier',
      scientificName: 'Citrus aurantifolia',
      family: 'Rutaceae',
      description: 'Petit agrume produisant les petits citrons verts (limettes) essentiels à la cuisine sénégalaise (Yassa).',
      wateringNeeds: 'medium',
      lightNeeds: 'direct',
      soilType: 'Sol fertile bien drainé',
      humidity: 'medium',
      minTemp: 15,
      maxTemp: 35,
      difficulty: 'medium',
      commonProblems: ['Mineuse des agrumes', 'Pucerons', 'Cochenilles'],
      careTips: ['Engrais spécial agrumes', 'Arrosage régulier en saison sèche', 'Tailler le centre pour la lumière'],
    ),
  ];

  static SpeciesInfo? findByName(String name) {
    final lower = name.toLowerCase();
    try {
      return species.firstWhere(
        (s) => s.name.toLowerCase().contains(lower) || s.scientificName.toLowerCase().contains(lower),
      );
    } catch (_) {
      return null;
    }
  }
}
