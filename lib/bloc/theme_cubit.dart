import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState {}
class ThemeInitial extends ThemeState {}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeInitial());
}
