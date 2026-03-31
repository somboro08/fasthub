import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:uuid/uuid.dart'; // Import for UUID
import '../models/publication_model.dart';
import '../services/publication_service.dart';
import '../models/profile_model.dart'; // Ensure ProfileModel is imported if needed for author info

// --- States ---
abstract class PublicationState {}

class PublicationInitial extends PublicationState {}
class PublicationLoading extends PublicationState {}
class PublicationLoaded extends PublicationState {
  final List<PublicationModel> publications;
  PublicationLoaded(this.publications);
}
class PublicationError extends PublicationState {
  final String message;
  PublicationError(this.message);
}

// --- Cubit ---
class PublicationCubit extends Cubit<PublicationState> {
  final PublicationService _publicationService;
  final _uuid = const Uuid(); // Instantiate Uuid

  PublicationCubit(this._publicationService) : super(PublicationInitial());

  Future<void> loadRecentPublications() async {
    emit(PublicationLoading());
    try {
      final publications = await _publicationService.getRecentPublications();
      emit(PublicationLoaded(publications));
    } catch (e) {
      emit(PublicationError('Erreur lors du chargement des publications: ${e.toString()}'));
    }
  }

  Future<void> addPublication({
    required String content,
    required File? imageFile,
    required String authorId,
    required Profile? authorProfile, // Pass the author's profile
  }) async {
    emit(PublicationLoading());
    try {
      final currentUser = _publicationService.getCurrentUser();
      print('DEBUG CUBIT: authorId fourni = $authorId');
      print('DEBUG CUBIT: currentUser.id Supabase = ${currentUser?.id}');
      
      if (currentUser == null) {
        throw Exception("Utilisateur non authentifié dans Supabase.");
      }
      
      if (currentUser.id != authorId) {
        print('ATTENTION: L\'ID fourni ($authorId) ne correspond pas à l\'ID de session (${currentUser.id})');
      }

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _publicationService.uploadPublicationImage(imageFile, authorId);
      }

      final newPublication = PublicationModel(
        id: _uuid.v4(),
        authorId: authorId,
        authorName: '${authorProfile?.firstName ?? ''} ${authorProfile?.lastName ?? ''}',
        authorFiliere: authorProfile?.filiere ?? 'N/A',
        authorLevel: authorProfile?.level ?? 'N/A',
        authorStatus: authorProfile?.userType ?? 'N/A', // Assuming userType maps to status
        authorAvatarUrl: authorProfile?.avatarUrl ?? 'https://cdn.icon-icons.com/icons2/1378/PNG/512/avatardefault_92824.png',
        content: content,
        publishedAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _publicationService.createPublication(newPublication);
      await loadRecentPublications(); // Reload publications to include the new one
    } catch (e) {
      emit(PublicationError("Erreur lors de l'ajout de la publication: ${e.toString()}"));
    }
  }
}