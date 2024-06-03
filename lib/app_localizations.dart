import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get login {
    return 'Anmelden'; // German
  }

  String get welcomeToMiPark {
    return 'Willkommen bei MiPark'; // German
  }

  String get myProfile {
    return 'Mein Profil'; // German
  }

  String get myVehicles {
    return 'Meine Fahrzeuge'; // German
  }

  String get support {
    return 'Unterstützung'; // German
  }

  String get privacyPolicy {
    return 'Datenschutzrichtlinie'; // German
  }

  String get changeLanguage {
    return 'Sprache ändern'; // German
  }

  String get faqs {
    return 'FAQs'; // German
  }


  String get email {
    return 'Email'; // English
  }

  String get password {
    return 'Password'; // English
  }

  String get forgotPassword {
    return 'Forgot Password?'; // English
  }

  String get orContinueWith {
    return 'Or continue with'; // English
  }

  String get appleID {
    return 'Apple ID'; // English
  }

  String get google {
    return 'Google'; // English
  }

  String get signUp {
    return 'Do you have an account? Sign up'; // English
  }

  // German translations
  String get loginGerman {
    return 'Anmelden';
  }

  String get welcomeToMiParkGerman {
    return 'Willkommen bei MiPark';
  }

  String get emailGerman {
    return 'E-Mail';
  }

  String get passwordGerman {
    return 'Passwort';
  }

  String get forgotPasswordGerman {
    return 'Passwort vergessen?';
  }

  String get orContinueWithGerman {
    return 'Oder weiter mit';
  }

  String get appleIDGerman {
    return 'Apple-ID';
  }

  String get googleGerman {
    return 'Google';
  }

  String get signUpGerman {
    return 'Haben Sie ein Konto? Registrieren';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}