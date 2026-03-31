import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../services/auth_service.dart';
import '../models/profile_model.dart';

// --- Custom App Authentication States ---
abstract class AppAuthState {}
class AppAuthInitial extends AppAuthState {}
class AppAuthLoading extends AppAuthState {}
class Authenticated extends AppAuthState {
  final supabase_flutter.User user;
  final Profile? profile;
  Authenticated({required this.user, this.profile});
}
class Unauthenticated extends AppAuthState {}
class AuthNeedsConfirmation extends AppAuthState {
  final String email;
  AuthNeedsConfirmation(this.email);
}
class AuthPasswordResetSent extends AppAuthState {}
class AuthError extends AppAuthState {
  final String message;
  AuthError(this.message);
}
class ProfilesLoading extends AppAuthState {}
class AllProfilesLoaded extends AppAuthState {
  final List<Profile> profiles;
  AllProfilesLoaded(this.profiles);
}

// --- Auth Cubit ---
class AuthCubit extends Cubit<AppAuthState> {
  final AuthService _authService;
  StreamSubscription<supabase_flutter.AuthState>? _supabaseAuthStateSubscription;

  AuthCubit(this._authService) : super(AppAuthInitial()) {
    _supabaseAuthStateSubscription = _authService.authStateChanges.listen((data) async {
      final supabase_flutter.AuthChangeEvent event = data.event;
      final supabase_flutter.Session? session = data.session;
      final supabase_flutter.User? user = session?.user;

      if (event == supabase_flutter.AuthChangeEvent.signedIn && user != null) {
        final profile = await _authService.getProfile(user.id);
        emit(Authenticated(user: user, profile: profile));
      } else if (event == supabase_flutter.AuthChangeEvent.signedOut) {
        emit(Unauthenticated());
      } else if (event == supabase_flutter.AuthChangeEvent.initialSession) {
        if (user != null) {
          final profile = await _authService.getProfile(user.id);
          emit(Authenticated(user: user, profile: profile));
        } else {
          emit(Unauthenticated());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _supabaseAuthStateSubscription?.cancel();
    return super.close();
  }

  Future<void> restoreSession() async {
    emit(AppAuthLoading());
    final supabase_flutter.User? currentUser = _authService.currentUser;
    if (currentUser != null) {
      final profile = await _authService.getProfile(currentUser.id);
      emit(Authenticated(user: currentUser, profile: profile));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AppAuthLoading());
    try {
      final response = await _authService.signIn(email: email, password: password);
      if (response.user != null) {
        final profile = await _authService.getProfile(response.user!.id);
        emit(Authenticated(user: response.user!, profile: profile));
      } else {
        emit(Unauthenticated());
      }
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      emit(Unauthenticated());
    }
  }

  Future<void> signUp(String email, String password, Map<String, dynamic> data) async {
    emit(AppAuthLoading());
    try {
      final response = await _authService.signUp(email: email, password: password, data: data);
      
      // If email confirmation is enabled, session might be null
      if (response.session == null) {
        emit(AuthNeedsConfirmation(email));
      } else if (response.user != null) {
        final profile = await _authService.getProfile(response.user!.id);
        emit(Authenticated(user: response.user!, profile: profile));
      } else {
        emit(Unauthenticated());
      }
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      emit(Unauthenticated());
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AppAuthLoading());
    try {
      await _authService.resetPasswordForEmail(email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    emit(AppAuthLoading());
    try {
      await _authService.signOut();
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      final supabase_flutter.User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _authService.getProfile(currentUser.id);
        emit(Authenticated(user: currentUser, profile: profile));
      } else {
        emit(AppAuthInitial());
      }
    } catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
      final supabase_flutter.User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _authService.getProfile(currentUser.id);
        emit(Authenticated(user: currentUser, profile: profile));
      } else {
        emit(AppAuthInitial());
      }
    }
  }

  Future<void> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? userType,
    String? phone,
    String? studentOption,
    String? faculty,
    String? filiere,
    String? level,
    String? matricule,
    DateTime? dateOfBirth,
    String? adminOption,
    String? otherRole,
    String? teachingDomain,
    List<String>? taughtSubjects,
    File? imageFile,
  }) async {
    final currentState = state;
    if (currentState is Authenticated && _authService.currentUser != null) {
      emit(AppAuthLoading());
      try {
        String? newAvatarUrl = currentState.profile?.avatarUrl;

        if (imageFile != null) {
          newAvatarUrl = await _authService.uploadAvatar(imageFile, _authService.currentUser!.id);
        }

        await _authService.updateProfile(
          userId: _authService.currentUser!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          userType: userType,
          phone: phone,
          studentOption: studentOption,
          faculty: faculty,
          filiere: filiere,
          level: level,
          matricule: matricule,
          dateOfBirth: dateOfBirth,
          adminOption: adminOption,
          otherRole: otherRole,
          teachingDomain: teachingDomain,
          taughtSubjects: taughtSubjects,
          avatarUrl: newAvatarUrl,
        );
        final updatedProfile = await _authService.getProfile(_authService.currentUser!.id);
        emit(Authenticated(user: currentState.user, profile: updatedProfile));
      } on supabase_flutter.PostgrestException catch (e) {
        emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
        emit(Authenticated(user: currentState.user, profile: currentState.profile));
      } on Exception catch (e) {
        emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
        emit(Authenticated(user: currentState.user, profile: currentState.profile));
      }
    }
  }

  Future<void> loadAllProfiles() async {
    emit(ProfilesLoading());
    try {
      final profiles = await _authService.getAllProfiles();
      emit(AllProfilesLoaded(profiles));
    } catch (e) {
      emit(AuthError(_mapAuthExceptionToUserFriendlyMessage(e)));
    }
  }

  String _mapAuthExceptionToUserFriendlyMessage(Object e) {
    if (e is supabase_flutter.AuthException) {
      if (e.message.contains('User already registered')) {
        return "Cet email est déjà enregistré. Veuillez vous connecter ou utiliser un autre email.";
      } else if (e.message.contains('Invalid login credentials')) {
        return "Email ou mot de passe incorrect. Veuillez vérifier vos identifiants.";
      } else if (e.message.contains('Email not confirmed')) {
        return "Votre email n'est pas confirmé. Veuillez vérifier votre boîte de réception.";
      } else if (e.message.contains('Email link is expired')) {
        return "Le lien de confirmation a expiré. Veuillez demander un nouveau lien.";
      } else if (e.message.contains('Password should be at least 6 characters')) {
        return "Le mot de passe doit contenir au moins 6 caractères.";
      } else if (e.message.contains('User not found')) {
        return "Utilisateur introuvable. Veuillez vérifier l'email.";
      } else {
        return "Erreur d'authentification: ${e.message}";
      }
    } else if (e is supabase_flutter.PostgrestException) {
      if (e.message.contains('duplicate key value violates unique constraint')) {
        return "Cette entrée existe déjà. Veuillez vérifier les informations saisies.";
      }
      return "Erreur de base de données: ${e.message}";
    } else {
      return "Une erreur inattendue est survenue: ${e.toString()}";
    }
  }
}
