import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'Map_Screen.dart';
import 'Login_Screen.dart';
import 'ForgotPasswordScreen.dart';
import 'Booking.dart';
import 'Profile.dart';
import 'splash_screen.dart';
import 'package:mira_parkk/ThemeModelCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';



class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(Locale('en', ''));

  void setLocale(Locale locale) {
    emit(locale);
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure plugin services are initialized
  SharedPreferences prefs = await SharedPreferences.getInstance();
  EasyLoading.init();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;  // Retrieve login status

  AwesomeNotifications().initialize(
    'resource://mipmap/launcher_icon',

    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );


  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeModeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),  // Provide LocaleCubit here

      ],
      child: MyApp(locale: Locale('en', ''), isLoggedIn: isLoggedIn), // Pass isLoggedIn status to MyApp
    ),
  );
}


class MyApp extends StatelessWidget {
  final Locale locale;
  final bool isLoggedIn;  // Add this line


  const MyApp({Key? key, required this.locale, this.isLoggedIn = false}) : super(key: key);  // Modify this line



  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeModeCubit(), // Create the ThemeModeCubit here
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'MiPark',
            theme: ThemeData.light(),
            builder: EasyLoading.init(),  // Add this line


            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.grey.shade900,
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
                titleLarge: TextStyle(color: Colors.white),
              ),
            ),
            themeMode: themeMode,
            initialRoute: '/',
            debugShowCheckedModeBanner: false,
            routes: {
              '/': (context) => SplashScreen(),
              '/login': (context) => Login_Screen(updateLocale: updateLocale ),
              '/MainScreen': (context) => MainScreen(updateLocale: updateLocale, userId: '123', locationName: '',),
              '/main_screen': (context) => MainScreen(updateLocale: updateLocale, userId: '123', locationName: '',),
              // '/ProfileScreen': (context) => Profile(updateLocale: updateLocale),
              // '/BookingsScreen': (context) => BookingScreen(userId: '123'),
              // '/SignUpVerificationScreen': (context) => SignUpVerificationScreen(isFromForgotPassword: false),
              // '/SignUpVerificationScreenForgotPassword': (context) => SignUpVerificationScreen(isFromForgotPassword: true),
              // '/forgot_password': (context) => ForgotPasswordScreen(showPasswordFields: false)
            },
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,  // Set locale dynamically
          );
        },
      ),
    );
  }

}


// Define a method to update the locale
void updateLocale(Locale locale) {
  if (locale.languageCode == 'de') {
    // Load German translations
    print('Loading German translations...');
    AppLocalizations.delegate.load(locale).then((_) {
      // Update the locale to German
      // No need to use setState, just pass the new locale directly
      print('German translations loaded.');
      runApp(MyApp(locale: locale));
    });
  } else {
    // Load English translations by default
    print('Loading English translations...');
    AppLocalizations.delegate.load(Locale('en', 'US')).then((_) {
      print('English Translations loaded.');
      runApp(MyApp(locale: locale));
    });
  }
}


class MainScreen extends StatefulWidget {
  final String userId;
  final Function(Locale) updateLocale;
  // final void Function(Locale) updateLocale;

  const MainScreen({Key? key, required this.updateLocale, required this.userId, required String locationName}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late Function(Locale) _updateLocale;

  @override
  void initState() {
    super.initState();

    // Create an instance of AwesomeNotifications
    AwesomeNotifications awesomeNotifications = AwesomeNotifications();

    // Check if notification is allowed
    awesomeNotifications.isNotificationAllowed().then((isAllowed) {

      if (!isAllowed) {
        // Notification is not allowed, show a prompt to enable it
        AlertDialog alert = AlertDialog(
          title: Text('Notification Permission'),
          content: Text('Please enable notification permission to use this app.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await awesomeNotifications.requestPermissionToSendNotifications();
              },
              child: Text('Enable'),
            ),
          ],
        );
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
          // Prompt user to turn on notifications
        );
      }

    }


    );


    _updateLocale = widget.updateLocale;
    _screens = [
      CombinedScreen(userId: widget.userId,), // Map Screen
      PreviouseBooking(userId: widget.userId, licensePlate: '', locationName: '', distance: '', latitude: 2, longitude: 1, StartTime: '', EndTime: '',), // Booking Screen
      Profile(updateLocale: _updateLocale, userId: widget.userId,), // Profile Screen
    ];
    _checkLocationService();


  }
  Future<void> _checkLocationService() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Location Services Disabled'),
            content: Text('Please enable location services to use this app.'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openLocationSettings();
                },
                child: Text('Enable'),
              ),
            ],
          );
        },
      );
    } else if (permission == LocationPermission.deniedForever) {
      // Handle case where user has previously denied permission permanently
      // You may want to provide some guidance to the user on how to enable the permission
    }
  }
  @override

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pages = [
      AppLocalizations.of(context)!.map,
      AppLocalizations.of(context)!.booking,
      AppLocalizations.of(context)!.profile,
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavWithAnimatedIcons(
        selectedIndex: _selectedIndex,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
            // Update locale here
            if (index == 0) {
              // Handle other locales if needed
            } else if (index == 1) {
              // Handle other locales if needed
            } else if (index == 2) {
              // Handle other locales if needed
            }
          });
        },
        pages: pages,
      ),
    );
  }
}

class BottomNavWithAnimatedIcons extends StatelessWidget {
  final List<IconData> icons = [Icons.map, Icons.book_online, Icons.person];
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<String> pages;

  BottomNavWithAnimatedIcons({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.pages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(0, 20),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          pages.length,
              (index) => GestureDetector(
            onTap: () {
              onIndexChanged(index);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBar(isActive: index == selectedIndex),
                Icon(
                  icons[index],
                  color: index == selectedIndex ? Colors.white : Colors.grey,
                ),
                Text(
                  pages[index],
                  style: TextStyle(
                    color: index == selectedIndex ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 2),
      height: 4,
      width: isActive ? 20 : 0,
      decoration: const BoxDecoration(
        color: Color(0xFF576778),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}