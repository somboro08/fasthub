import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  static Future<void> initializeSupabase({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  Session? get currentSession => _supabaseClient.auth.currentSession;
  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(_mapAuthExceptionToMessage(e.message));
    } on SocketException {
      throw Exception("Erreur de réseau. Veuillez vérifier votre connexion internet et réessayer.");
    } catch (e) {
      if (e.toString().contains('PostgrestException')) {
        throw Exception("Erreur de base de données en sauvegardant le nouvel utilisateur. Veuillez vérifier les policies RLS et la fonction trigger sur votre table 'profiles'.");
      }
      throw Exception("Une erreur inattendue est survenue lors de l'inscription: ${e.toString()}");
    }
  }

  String _mapAuthExceptionToMessage(String originalMessage) {
    if (originalMessage.contains('Email already registered')) {
      return "L'adresse e-mail est déjà enregistrée. Veuillez vous connecter ou utiliser un autre e-mail.";
    } else if (originalMessage.contains('Password should be at least 6 characters')) {
      return "Le mot de passe doit contenir au moins 6 caractères.";
    } else if (originalMessage.contains('Invalid login credentials')) {
      return "Identifiants de connexion invalides. Veuillez vérifier votre e-mail et votre mot de passe.";
    } else if (originalMessage.contains('User already confirmed')) {
      return "Cet utilisateur est déjà confirmé. Veuillez vous connecter.";
    } else if (originalMessage.contains('Email link expired')) {
      return "Le lien de confirmation de l'e-mail a expiré. Veuillez en demander un nouveau.";
    } else if (originalMessage.contains('Error sending confirmation mail')) {
      return "Erreur lors de l'envoi de l'e-mail de confirmation. Veuillez réessayer plus tard.";
    }
    return "Erreur d'authentification: $originalMessage";
  }

  Future<String> uploadAvatar(File imageFile, String userId) async {
    final String path = '$userId/avatars/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final String fileExtension = imageFile.path.split('.').last;
      await _supabaseClient.storage.from('avatars').upload(
            path,
            imageFile,
            fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true),
          );
      final String publicUrl = _supabaseClient.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception("Erreur de téléchargement d'avatar: ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue lors du téléchargement d'avatar: ${e.toString()}");
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthExceptionToMessage(e.message));
    } on SocketException {
      throw Exception("Erreur de réseau. Veuillez vérifier votre connexion internet et réessayer.");
    } catch (e) {
      throw Exception("Une erreur inattendue est survenue lors de la connexion: ${e.toString()}");
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  Future<Profile?> getProfile(String userId) async {
    try {
      final Map<String, dynamic>? response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? Profile.fromJson(response) : null;
    } on PostgrestException catch (e) {
      throw Exception("Erreur de base de données lors du chargement du profil: ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue lors du chargement du profil: ${e.toString()}");
    }
  }

  Future<List<Profile>> getAllProfiles() async {
    try {
      final List<Map<String, dynamic>> response = await _supabaseClient.from('profiles').select();
      return response.map((json) => Profile.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception("Erreur lors du chargement des profils: ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue lors du chargement des profils.");
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    String? userType,
    String? phone,
    String? avatarUrl,
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
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (email != null) updates['email'] = email;
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (userType != null) updates['user_type'] = userType;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (studentOption != null) updates['student_option'] = studentOption;
    if (faculty != null) updates['faculty'] = faculty;
    if (filiere != null) updates['filiere'] = filiere;
    if (level != null) updates['level'] = level;
    if (matricule != null) updates['matricule'] = matricule;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
    if (adminOption != null) updates['admin_option'] = adminOption;
    if (otherRole != null) updates['other_role'] = otherRole;
    if (teachingDomain != null) updates['teaching_domain'] = teachingDomain;
    if (taughtSubjects != null) updates['taught_subjects'] = taughtSubjects;

    try {
      if (updates.isNotEmpty) {
        await _supabaseClient.from('profiles').update(updates).eq('id', userId);
      }
    } on PostgrestException catch (e) {
      throw Exception("Erreur de base de données lors de la mise à jour du profil: ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue lors de la mise à jour du profil: ${e.toString()}");
    }
  }

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_mapAuthExceptionToMessage(e.message));
    } catch (e) {
      throw Exception("Erreur lors de la demande de réinitialisation: ${e.toString()}");
    }
  }
}
