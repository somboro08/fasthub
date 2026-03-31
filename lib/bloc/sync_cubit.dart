import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_service.dart';

abstract class SyncState {}
class SyncInitial extends SyncState {}
class SyncInProgress extends SyncState {}
class SyncOffline extends SyncState {}
class SyncCompleted extends SyncState {}
class SyncError extends SyncState {
  final String message;
  SyncError(this.message);
}

class SyncCubit extends Cubit<SyncState> {
  final FastHubDatabase _database;
  final Connectivity _connectivity;
  Timer? _syncTimer;

  SyncCubit()
      : _database = FastHubDatabase.instance,
        _connectivity = Connectivity(),
        super(SyncInitial()) {
    _initSync();
  }

  void _initSync() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncWithCloud();
      } else {
        emit(SyncOffline());
      }
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncWithCloud();
    });
  }

  Future<void> syncWithCloud() async {
    final status = await _connectivity.checkConnectivity();
    if (status == ConnectivityResult.none) {
      emit(SyncOffline());
      return;
    }

    emit(SyncInProgress());
    try {
      await _database.syncWithSupabase();
      emit(SyncCompleted());
      Future.delayed(const Duration(seconds: 2), () {
        if (state is SyncCompleted) emit(SyncInitial());
      });
    } catch (e) {
      emit(SyncError(e.toString()));
      Future.delayed(const Duration(seconds: 3), () {
        if (state is SyncError) emit(SyncInitial());
      });
    }
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }
}
