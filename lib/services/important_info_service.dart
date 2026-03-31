import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/important_info_model.dart';

class ImportantInfoService {
  final SupabaseClient _supabaseClient;

  ImportantInfoService(this._supabaseClient);

  // Creates a new important info entry in the database
  Future<void> createImportantInfo(ImportantInfoModel info) async {
    try {
      await _supabaseClient.from('important_info').insert(info.toJson());
    } on PostgrestException catch (e) {
      throw Exception("Erreur de base de données lors de la création de l'information importante: ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue lors de la création de l'information importante: ${e.toString()}");
    }
  }

  Future<List<ImportantInfoModel>> getImportantInfo() async {
    try {
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from('important_info')
          .select()
          .order('published_at', ascending: false)
          .limit(10); // Fetch recent 10 important infos

      return response.map((json) => ImportantInfoModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur de base de données lors du chargement des informations importantes: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue lors du chargement des informations importantes: ${e.toString()}');
    }
  }
}
