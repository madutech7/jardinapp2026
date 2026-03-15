import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // À remplacer par vos identifiants Cloudinary
  static const String cloudName = 'dlqdhyydm';
  static const String uploadPreset = 'monjardin_preset';

  static Future<String> uploadImage(File file, String path) async {
    // Dans Cloudinary, le path peut servir de dossier/nom de fichier via public_id
    // Mais avec un upload non signé, on a souvent juste 'upload_preset', on peut
    // passer 'folder' si le preset le permet.

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      // Dossier optionnel pour organiser sur Cloudinary
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

  static Future<void> deleteImage(String url) async {
    // La suppression nécessite généralement une authentification signée API (Secret)
    // Nous l'ignorons silencieusement pour une configuration côté client.
  }
}
