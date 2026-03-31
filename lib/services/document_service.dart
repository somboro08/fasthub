import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class DocumentService {
  final SupabaseClient _supabaseClient;

  DocumentService(this._supabaseClient);

  // Fetch public documents by filiere and optional filters
  Future<List<DocumentModel>> getPublicDocumentsByFiliereAndFilters(
    String filiere, {
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    var query = _supabaseClient
        .from('documents') // Assuming 'documents' is your Supabase table name
        .select()
        .eq('is_public', true)
        .eq('filiere', filiere);

    if (level != null) {
      query = query.eq('level', level);
    }
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }

    final List<Map<String, dynamic>> response = await query
        .order('created_at', ascending: false)
        .limit(50); // Limit to 50 documents for now

    return response.map((json) => DocumentModel.fromJson(json)).toList();
  }

  // Fetch all public documents with optional filters
  Future<List<DocumentModel>> getAllPublicDocuments({
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    var query = _supabaseClient
        .from('documents') // Assuming 'documents' is your Supabase table name
        .select()
        .eq('is_public', true);

    if (level != null) {
      query = query.eq('level', level);
    }
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }

    final List<Map<String, dynamic>> response = await query
        .order('created_at', ascending: false)
        .limit(50); // Limit to 50 documents for now

    return response.map((json) => DocumentModel.fromJson(json)).toList();
  }

  // Fetch documents authored by the current user with optional filters
  Future<List<DocumentModel>> getMyDocuments(
    String authorId, {
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    var query = _supabaseClient
        .from('documents')
        .select()
        .eq('author_id', authorId);

    if (level != null) {
      query = query.eq('level', level);
    }
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    if (academicYear != null) {
      query = query.eq('academic_year', academicYear);
    }

    final List<Map<String, dynamic>> response = await query
        .order('created_at', ascending: false);

    return response.map((json) => DocumentModel.fromJson(json)).toList();
  }

  // Fetch a single document by ID
  Future<DocumentModel?> getDocumentById(String id) async {
    try {
      final Map<String, dynamic>? response = await _supabaseClient
          .from('documents')
          .select()
          .eq('id', id)
          .single(); // Use single directly

      if (response != null) {
        return DocumentModel.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      print('Error fetching document by ID: ${e.message}');
      return null;
    } catch (e) {
      print('Generic error fetching document by ID: ${e.toString()}');
      return null;
    }
  }

  // Create a new document
  Future<void> createDocument(DocumentModel document) async {
    await _supabaseClient.from('documents').insert(document.toJson());
  }

  // Update an existing document
  Future<void> updateDocument(DocumentModel document) async {
    await _supabaseClient
        .from('documents')
        .update(document.toJson())
        .eq('id', document.id);
  }

  // Delete a document
  Future<void> deleteDocument(String id) async {
    await _supabaseClient.from('documents').delete().eq('id', id);
  }

  Future<List<String>> getUniqueFilieres() async {
    final response = await _supabaseClient.from('documents').select('filiere');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((item) => item['filiere'] as String).toSet().toList();
  }

  Future<List<String>> getUniqueSubjects() async {
    final response = await _supabaseClient.from('documents').select('subject');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((item) => item['subject'] as String).toSet().toList();
  }

  Future<List<String>> getUniqueDocumentTypes() async {
    final response = await _supabaseClient.from('documents').select('document_type');
    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((item) => item['document_type'] as String?)
        .where((item) => item != null)
        .cast<String>()
        .toSet()
        .toList();
  }
}
