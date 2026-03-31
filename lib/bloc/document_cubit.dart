import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart'; // To get current user ID and filiere
import '../models/document_model.dart';
import '../models/profile_model.dart'; // To get profile details

// --- Document States ---
abstract class DocumentState {}

class DocumentInitial extends DocumentState {}
class DocumentLoading extends DocumentState {}

class DocumentsLoaded extends DocumentState {
  final List<DocumentModel> documents;
  DocumentsLoaded(this.documents);
}

class CombinedDocumentsLoaded extends DocumentState {
  final List<DocumentModel> publicDocuments;
  final List<DocumentModel> myDocuments;
  CombinedDocumentsLoaded(this.publicDocuments, this.myDocuments);
}


class DocumentOperationSuccess extends DocumentState {
  final String message;
  DocumentOperationSuccess(this.message);
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}

// --- Document Cubit ---
class DocumentCubit extends Cubit<DocumentState> {
  final DocumentService _documentService;
  final AuthService _authService; // To get current user and profile

  DocumentCubit(this._documentService, this._authService) : super(DocumentInitial());

  Future<void> loadAllPublicDocumentsForFiliere(
    String filiere, {
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    emit(DocumentLoading());
    try {
      final documents = await _documentService.getPublicDocumentsByFiliereAndFilters(
        filiere,
        level: level,
        subject: subject,
        academicYear: academicYear,
      );
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError('Erreur lors du chargement des documents: ${e.toString()}'));
    }
  }

  Future<void> loadMyDocuments({
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    emit(DocumentLoading());
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      emit(DocumentError('Utilisateur non authentifié pour charger les documents.'));
      return;
    }
    try {
      final documents = await _documentService.getMyDocuments(
        currentUser.id,
        level: level,
        subject: subject,
        academicYear: academicYear,
      );
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError('Erreur lors du chargement de mes documents: ${e.toString()}'));
    }
  }

  Future<void> createDocument(DocumentModel document) async {
    emit(DocumentLoading()); // Optionally emit loading, or manage a separate state for operation
    try {
      await _documentService.createDocument(document);
      emit(DocumentOperationSuccess('Document créé avec succès.'));
      // Reload documents after creation if needed
      // For now, will need manual reload from UI or another event
    } on PostgrestException catch (e) {
      emit(DocumentError('Erreur Postgrest: ${e.message}'));
    } catch (e) {
      emit(DocumentError('Erreur lors de la création du document: ${e.toString()}'));
    }
  }

  Future<void> updateDocument(DocumentModel document) async {
    emit(DocumentLoading()); // Optionally emit loading
    try {
      await _documentService.updateDocument(document);
      emit(DocumentOperationSuccess('Document mis à jour avec succès.'));
    } on PostgrestException catch (e) {
      emit(DocumentError('Erreur Postgrest: ${e.message}'));
    } catch (e) {
      emit(DocumentError('Erreur lors de la mise à jour du document: ${e.toString()}'));
    }
  }

  Future<void> deleteDocument(String id) async {
    emit(DocumentLoading()); // Optionally emit loading
    try {
      await _documentService.deleteDocument(id);
      emit(DocumentOperationSuccess('Document supprimé avec succès.'));
    } on PostgrestException catch (e) {
      emit(DocumentError('Erreur Postgrest: ${e.message}'));
    } catch (e) {
      emit(DocumentError('Erreur lors de la suppression du document: ${e.toString()}'));
    }
  }

  Future<void> loadCombinedDocuments(
    String? filiere,
    String? userId, {
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    emit(DocumentLoading());
    List<DocumentModel> publicDocs = [];
    List<DocumentModel> myDocs = [];

    try {
      // Load ALL public documents for the "Todos" tab, regardless of filiere
      publicDocs = await _documentService.getAllPublicDocuments(
        level: level,
        subject: subject,
        academicYear: academicYear,
      );

      if (userId != null) {
        // Load user's own documents
        myDocs = await _documentService.getMyDocuments(
          userId,
          level: level,
          subject: subject,
          academicYear: academicYear,
        );
      }
      emit(CombinedDocumentsLoaded(publicDocs, myDocs));
    } catch (e) {
      emit(DocumentError('Erreur lors du chargement des documents combinés: ${e.toString()}'));
    }
  }

  Future<void> loadDocumentsByAuthor(
    String authorId, {
    String? level,
    String? subject,
    String? academicYear,
  }) async {
    emit(DocumentLoading()); // Indicate loading state
    try {
      final documents = await _documentService.getMyDocuments( // Reuse getMyDocuments logic
        authorId,
        level: level,
        subject: subject,
        academicYear: academicYear,
      );
      emit(DocumentsLoaded(documents)); // Emit loaded state with the author's documents
    } catch (e) {
      emit(DocumentError('Erreur lors du chargement des documents de l\'auteur: ${e.toString()}'));
    }
  }

  // Helper method to clear documents if needed (e.g., on sign out)
  void clearDocuments() {
    emit(DocumentsLoaded([]));
  }
}
