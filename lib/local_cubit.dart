import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(Locale('en', 'US')); // Default to English locale

  void setLocale(Locale newLocale) {
    emit(newLocale); // Update the locale state
  }
}
