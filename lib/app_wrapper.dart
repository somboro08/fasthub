import 'package:fasthub/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/ai_chat_cubit.dart';
import 'services/ai_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class AppWrapper extends StatelessWidget {
  final AIService aiService;

  const AppWrapper({super.key, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AppAuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // You could use Navigator here if you weren't using the builder for switching
        }
      },
      builder: (context, state) {
        if (state is AppAuthInitial || state is AppAuthLoading) {
          return const SplashScreen();
        } else if (state is Authenticated) {
          return const HomeScreen();
        } else if (state is AuthNeedsConfirmation) {
          return const LoginScreen();
        } else {
          return WelcomeScreen();
        }
      },
    );
  }
}
