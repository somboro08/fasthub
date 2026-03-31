import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/publication_model.dart';
import '../models/profile_model.dart'; // Import ProfileModel

class PublicationService {
  final SupabaseClient _supabaseClient;

  PublicationService(this._supabaseClient);

  User? getCurrentUser() => _supabaseClient.auth.currentUser;

  // Uploads an image to Supabase Storage and returns its public URL
  Future<String> uploadPublicationImage(File imageFile, String userId) async {
    final String path = '$userId/publications/${DateTime.now().millisecondsSinceEpoch}.png';
    print('DEBUG STORAGE: Tentative d\'upload d\'image vers publication_images/$path');
    try {
      final String fileExtension = imageFile.path.split('.').last;
      await _supabaseClient.storage.from('publication_images').upload(
            path,
            imageFile,
            fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true),
          );
      print('DEBUG STORAGE: Upload réussi');
      final String publicUrl = _supabaseClient.storage.from('publication_images').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      print('--- ERREUR STORAGE ---');
      print('Message: ${e.message}');
      print('Status: ${e.statusCode}');
      print('-----------------------');
      throw Exception("Erreur de stockage [${e.statusCode}]: ${e.message}");
    } catch (e) {
      print('DEBUG STORAGE: Erreur inattendue: $e');
      throw Exception("Erreur inattendue lors du téléchargement d'image: ${e.toString()}");
    }
  }

  // Creates a new publication in the database
  Future<void> createPublication(PublicationModel publication) async {
    try {
      print('DEBUG: Tentative d\'insertion de la publication: ${publication.toJson()}');
      await _supabaseClient.from('publications').insert(publication.toJson());
      print('DEBUG: Insertion réussie');
    } on PostgrestException catch (e) {
      print('--- ERREUR SUPABASE ---');
      print('Message: ${e.message}');
      print('Code: ${e.code}');
      print('Details: ${e.details}');
      print('Hint: ${e.hint}');
      print('-----------------------');
      throw Exception("Erreur Supabase [${e.code}]: ${e.message} (Détails: ${e.details}, Hint: ${e.hint})");
    } catch (e) {
      print('DEBUG: Erreur inattendue: $e');
      throw Exception("Erreur inattendue lors de la création de la publication: ${e.toString()}");
    }
  }

  Future<List<PublicationModel>> getRecentPublications() async {
    try {
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from('publications')
          .select()
          .order('published_at', ascending: false)
          .limit(10); // Fetch recent 10 publications

      return response.map((json) => PublicationModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur de base de données lors du chargement des publications: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue lors du chargement des publications: ${e.toString()}');
    }
  }
}
