import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/auth_cubit.dart';
import '../theme/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _matriculeController = TextEditingController();
  final _filiereController = TextEditingController();
  final _levelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _selectedImageFile;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FastHubTheme.errorColor : FastHubTheme.successColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated && authState.profile != null) {
      _matriculeController.text = authState.profile!.matricule ?? '';
      _filiereController.text = authState.profile!.filiere ?? '';
      _levelController.text = authState.profile!.level ?? '';
    }
  }

  void _handleUpdateProfile({File? imageFile}) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().updateProfile(
        matricule: _matriculeController.text.trim(),
        filiere: _filiereController.text.trim(),
        level: _levelController.text.trim(),
        imageFile: imageFile,
      );
    }
  }

  void _handleSignOut() {
    context.read<AuthCubit>().signOut();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
      _handleUpdateProfile(imageFile: File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _filiereController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AppAuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSnackBar(state.message, isError: true);
          } else if (state is Authenticated) {
            _showSnackBar('Profil mis à jour avec succès !');
            _matriculeController.text = state.profile!.matricule ?? '';
            _filiereController.text = state.profile!.filiere ?? '';
            _levelController.text = state.profile!.level ?? '';
          }
        },
        builder: (context, state) {
          if (state is AppAuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! Authenticated) {
            return Center(
              child: Text(
                'Non authentifié',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FastHubTheme.textSecondary),
              ),
            );
          }

          final user = state.user;
          final profile = state.profile;
          final isLoading = state is AppAuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Card(
                  color: FastHubTheme.surfaceColor,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: FastHubTheme.accentColor.withOpacity(0.2),
                              backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(profile!.avatarUrl!) as ImageProvider
                                  : (_selectedImageFile != null ? FileImage(_selectedImageFile!) : null),
                              child: (profile?.avatarUrl == null && _selectedImageFile == null)
                                  ? Icon(
                                      Icons.camera_alt,
                                      size: 50,
                                      color: FastHubTheme.accentColor,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Informations du Compte',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(context, 'Email', user.email ?? 'N/A'),
                        const Divider(height: 30, color: FastHubTheme.textSecondary),
                        Text(
                          'Informations Personnelles',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: FastHubTheme.textColor),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _matriculeController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Numéro Matricule',
                            hintText: 'Votre numéro matricule',
                            prefixIcon: Icon(Icons.badge, color: FastHubTheme.accentColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FastHubTheme.textColor),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre numéro matricule';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _filiereController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Filière',
                            hintText: 'Votre filière',
                            prefixIcon: Icon(Icons.school, color: FastHubTheme.accentColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FastHubTheme.textColor),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre filière';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _levelController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Niveau d'étude",
                            hintText: 'Ex: Licence 1, Master 2',
                            prefixIcon: Icon(Icons.grade, color: FastHubTheme.accentColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FastHubTheme.textColor),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Veuillez entrer votre niveau d'étude";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleUpdateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FastHubTheme.accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Mettre à jour le profil',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _handleSignOut,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: FastHubTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: FastHubTheme.errorColor)
                                : Text(
                                    'Se déconnecter',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FastHubTheme.errorColor, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FastHubTheme.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
