import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mira_parkk/ThemeModelCubit.dart';
import 'package:mira_parkk/main.dart';
import  'package:mira_parkk/Login_Screen.dart';
import 'package:mira_parkk/splash_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('App starts and displays SplashScreen', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeModeCubit()),
          BlocProvider(create: (context) => LocaleCubit()),
        ],
        child: MyApp(locale: Locale('en', ''), isLoggedIn: false),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
     expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('Navigates to Login Screen on tap', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeModeCubit()),
          BlocProvider(create: (context) => LocaleCubit()),
        ],
        child: MyApp(locale: Locale('en', ''), isLoggedIn: false),
      ),
    );

    await tester.pumpAndSettle();

    // Act
    // Assuming there's a button or something to navigate to login
    await tester.tap(find.byType(TextButton)); // Change this to the actual widget that navigates to Login_Screen
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(Login_Screen), findsOneWidget);
  });

  testWidgets('Navigates to Main Screen when logged in', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeModeCubit()),
          BlocProvider(create: (context) => LocaleCubit()),
        ],
        child: MyApp(locale: Locale('en', ''), isLoggedIn: true),
      ),
    );

    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
