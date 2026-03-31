import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart'; // Import for UUID
import '../models/important_info_model.dart';
import '../services/important_info_service.dart';
import '../models/profile_model.dart'; // Import ProfileModel for author info

// --- States ---
abstract class ImportantInfoState {}

class ImportantInfoInitial extends ImportantInfoState {}
class ImportantInfoLoading extends ImportantInfoState {}
class ImportantInfoLoaded extends ImportantInfoState {
  final List<ImportantInfoModel> infos;
  ImportantInfoLoaded(this.infos);
}
class ImportantInfoError extends ImportantInfoState {
  final String message;
  ImportantInfoError(this.message);
}

// --- Cubit ---
class ImportantInfoCubit extends Cubit<ImportantInfoState> {
  final ImportantInfoService _importantInfoService;
  final _uuid = const Uuid(); // Instantiate Uuid

  ImportantInfoCubit(this._importantInfoService) : super(ImportantInfoInitial());

  Future<void> loadImportantInfo() async {
    emit(ImportantInfoLoading());
    try {
      final infos = await _importantInfoService.getImportantInfo();
      emit(ImportantInfoLoaded(infos));
    } catch (e) {
      emit(ImportantInfoError('Erreur lors du chargement des informations importantes: ${e.toString()}'));
    }
  }

  Future<void> addImportantInfo({
    required String title,
    required String content,
    required String authorId,
    required Profile? authorProfile, // Pass the author's profile
  }) async {
    emit(ImportantInfoLoading());
    try {
      final newInfo = ImportantInfoModel(
        id: _uuid.v4(),
        authorId: authorId,
        author: '${authorProfile?.firstName ?? ''} ${authorProfile?.lastName ?? ''}',
        title: title,
        publishedAt: DateTime.now(),
        content: content,
      );

      await _importantInfoService.createImportantInfo(newInfo);
      await loadImportantInfo(); // Reload important info to include the new one
    } catch (e) {
      emit(ImportantInfoError("Erreur lors de l'ajout de l'information importante: ${e.toString()}"));
    }
  }
}