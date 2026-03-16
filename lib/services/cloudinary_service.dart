import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Identifiants Cloudinary pour l'upload d'images
  static const String cloudName = 'dlqdhyydm';
  static const String uploadPreset = 'monjardin_preset';

  /// Téléverse (upload) une image vers le service Cloudinary
  /// [file] : Le fichier image physique à envoyer
  /// [path] : Le chemin/nom souhaité
  static Future<String> uploadImage(File file, String path) async {
    // Dans Cloudinary, l'upload non signé utilise le 'upload_preset' configuré côté serveur.
    // On peut spécifier un dossier ('folder') si le preset le permet.

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    
    // Création d'une requête multipart pour envoyer le fichier binaire
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      // Définit le dossier cible sur Cloudinary pour organiser les images
      ..fields['folder'] = 'jardinapp'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      return jsonMap['secure_url'];
    } else {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      throw Exception(
        'Erreur de téléversement Cloudinary: ${response.statusCode} - $responseString',
      );
    }
  }

  /// Tente de supprimer une image hébergée sur Cloudinary (non implémenté côté client pour des raisons de sécurité)
  static Future<void> deleteImage(String url) async {
    // La suppression via l'API Cloudinary nécessite généralement une signature générée avec l'API Secret.
    // Pour des raisons de sécurité (ne pas exposer le secret dans l'application cliente), 
    // l'implémentation est volontairement laissée vide ici. Idéalement gérée via une Cloud Function.
  }
}
