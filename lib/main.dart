import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/theme.dart';
import 'app_wrapper.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/theme_cubit.dart';
import 'bloc/sync_cubit.dart';
import 'bloc/document_cubit.dart';
import 'bloc/important_info_cubit.dart'; // Import ImportantInfoCubit
import 'bloc/publication_cubit.dart'; // Import PublicationCubit
import 'services/auth_service.dart';
import 'services/document_service.dart';
import 'services/important_info_service.dart'; // Import ImportantInfoService
import 'services/publication_service.dart'; // Import PublicationService
import 'services/social_service.dart';
import 'services/ai_service.dart'; // Import AIService
import 'bloc/ai_chat_cubit.dart'; // Import AIChatCubit
import 'bloc/social_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  
  // TODO: Replace with your actual Supabase URL and Anon Key

  await AuthService.initializeSupabase(
    supabaseUrl: 'https://syfbzzgwvnfzcoirqojn.supabase.co',
    supabaseAnonKey: 'sb_publishable_hCtWQ01cbLiigcKmPZj8YQ_qReG5L2w',
  );

  final authService = AuthService(Supabase.instance.client);
  final documentService = DocumentService(Supabase.instance.client);
  final importantInfoService = ImportantInfoService(Supabase.instance.client); // Instantiate ImportantInfoService
  final publicationService = PublicationService(Supabase.instance.client); // Instantiate PublicationService
  final socialService = SocialService(Supabase.instance.client);
  final aiService = AIService();

  // Initialize the local DB to ensure file is created
  await Future.delayed(const Duration(milliseconds: 100)); // Keep for now as it was

  runApp(FastHubApp(
    authService: authService, 
    documentService: documentService, 
    importantInfoService: importantInfoService, 
    publicationService: publicationService,
    socialService: socialService,
    aiService: aiService,
  )); // Pass all services
}

class FastHubApp extends StatelessWidget {
  final AuthService authService;
  final DocumentService documentService;
  final ImportantInfoService importantInfoService; // Add ImportantInfoService
  final PublicationService publicationService; // Add PublicationService
  final SocialService socialService;
  final AIService aiService;

  const FastHubApp({
    super.key,
    required this.authService,
    required this.documentService,
    required this.importantInfoService,
    required this.publicationService,
    required this.socialService,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authService)..restoreSession()),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => SyncCubit()),
        BlocProvider(create: (_) => DocumentCubit(documentService, authService)),
        BlocProvider(create: (_) => ImportantInfoCubit(this.importantInfoService)),
        BlocProvider(create: (_) => PublicationCubit(this.publicationService)),
        BlocProvider(create: (_) => SocialCubit(this.socialService)),
        BlocProvider(create: (_) => AIChatCubit(
          aiService: this.aiService,
          apiKey: 'AIzaSyDFsaAlQs5ErTSwSGkN4Xt3DzeRqKyOZNY',
        )),
      ],
      child: MaterialApp(
        title: 'FastHub',
        theme: FastHubTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: AppWrapper(aiService: aiService),
      ),
    );
  }
}
