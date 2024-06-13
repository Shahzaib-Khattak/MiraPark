import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mira_parkk/FAQs.dart';
import 'Login_Screen.dart';
import 'MyVehicle.dart';
import 'MyProfile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SupportScreen.dart';
import 'Privacy Policy.dart';


class Profile extends StatefulWidget {
  final Function(Locale) updateLocale;
  final String userId;

  Profile({Key? key,required this.userId, required this.updateLocale}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late SharedPreferences _prefs; // SharedPreferences instance
  String selectedLanguage = 'English (US)'; // Default language
  bool languageChanged = false;
  double screenHeight = 0.0;
  double bottomNavigationBarHeight = 0.0;
  double bottomPadding = 0.0;

  @override
  void initState() {
    super.initState();
    _initPreferences(); // Initialize SharedPreferences
  }

  // Initialize SharedPreferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    selectedLanguage = _prefs.getString('selectedLanguage') ?? selectedLanguage;
    setState(() {});
  }

  // Function to save selected language to SharedPreferences
  Future<void> _saveSelectedLanguage(String language) async {
    await _prefs.setString('selectedLanguage', language);
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    bottomNavigationBarHeight = kBottomNavigationBarHeight;
    bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: _getBackgroundColors(context),
          ),
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 25, top: 50, right: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 25, bottom: 10),
                                child: FadeInUp(
                                  duration: Duration(milliseconds: 800),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId,)),
                                      );
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.myProfile,
                                      style: TextStyle(color: Colors.white, fontSize: 30),
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: screenHeight - bottomNavigationBarHeight - 100 - bottomPadding,
                    decoration: BoxDecoration(
                      color: _getContainerColor(context),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 5, top: 20),
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MyVehicle( userId: widget.userId,)),
                              );
                            },
                            child: FadeInUp(
                              duration: Duration(milliseconds: 800),
                              child: _buildFeatureContainer(
                                AppLocalizations.of(context)?.myVehicles ?? 'My Vehicles',
                                'assets/vehicle_image.png',
                                AppLocalizations.of(context)?.saveYourVehiclesHere ?? 'save your vehicles here',
                                context,
                              ),
                            ),
                          ),
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>SupportScreen()),
                                );
                              },
                              child: _buildFeatureContainer(
                                AppLocalizations.of(context)?.support ?? 'Support',
                                'assets/Support.png',
                                AppLocalizations.of(context)?.connectUsForIssuesAndSolutions ?? 'Connect us for issues and solutions',
                                context,
                              ),
                            ),
                          ),

                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>PrivacyPolicyScreen()),
                                );
                              },
                              child: _buildFeatureContainer(
                                AppLocalizations.of(context)?.privacyPolicy ?? 'Privacy Policy',
                                'assets/PrivacyPolicy.png',
                                AppLocalizations.of(context)?.readOurPrivacyPolicy ?? 'Read our privacy policy',
                                context,
                              ),
                            ),
                          ),
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: _buildLanguageDropdown(),
                          ),
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>FAQScreen()),
                                );
                              },
                              child: _buildFeatureContainer(
                                AppLocalizations.of(context)?.faqs ?? 'FAQs',
                                'assets/FAQ.png',
                                AppLocalizations.of(context)?.getYourQuestionsAnswered ?? 'Get your questions answered',
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _logout(BuildContext context) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Ensure this is correctly being set to false during logout
    await prefs.remove('userId'); // Optionally clear the user ID if it's no longer needed

    Navigator.of(context).pushReplacementNamed('/login');// Ensure this navigates to the correct login screen
    print('User logged out');
  }


  Widget _buildFeatureContainer(String title, String imagePath, String description, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(imagePath, height: 30, width: 30),
              SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, color: textColor)),
            ],
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(description, style: TextStyle(fontSize: 12, color: textColor)),
          ),
          if (title == AppLocalizations.of(context)?.faqs) // Check if it's the FAQs section
            Column(
              children: [
                SizedBox(height: 30), // Add space between FAQs and Logout button
                Padding(
                  padding: EdgeInsets.only(right: 30 ), // Adjust this padding to move the button left

                  child: TextButton.icon(
                    onPressed: () {
                      _logout(context); // Call the logout method
                    },
                    icon: Icon(Icons.logout, color: Colors.blue.shade700), // Set the icon color to blue
                    label: Text(
                      AppLocalizations.of(context)?.logout ?? 'Logout',
                      style: TextStyle(
                        fontSize: 16, // Set the text size
                        fontWeight: FontWeight.normal, // Ensure text is not bold
                        color: isDarkMode ? Colors.white : Colors.black, // Set text color based on theme
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _getContainerColor(context),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DefaultTextStyle(
                style: TextStyle(fontWeight: FontWeight.normal), // Icon style set to normal
                child: Icon(Icons.language, size: 25, color: Colors.blueAccent), // Set color to blue
              ),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLanguage = newValue!;
                    _changeLanguage(newValue); // Call the _changeLanguage method here if necessary
                    _saveSelectedLanguage(newValue); // Save selected language
                  });
                },
                items: <String>['English (US)', 'Deutsch']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.normal, // Normal text, not bold
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeLanguage(String language) {
    print("Selected Language: $language");
    setState(() {
      selectedLanguage = language;
      if (language == 'Deutsch') {
        AppLocalizations.delegate.load(Locale('de', '')).then((_) {
          print("Loaded German Locale");
          print(AppLocalizations.of(context)?.email); // Example: Print a translated string
          setState(() {});
          // Call the updateLocale method defined in MyApp with the new locale
          widget.updateLocale(Locale('de', ''));
          print("Locale updated to German (de)");
        });
      } else if (language == 'English (US)') {
        AppLocalizations.delegate.load(Locale('en', 'US')).then((_) {
          print("Loaded English (US) Locale");
          print(AppLocalizations.of(context)?.email); // Example: Print a translated string
          setState(() {});
          // Call the updateLocale method defined in MyApp with the new locale
          widget.updateLocale.call(Locale('en', 'US'));
          print("Locale updated to English (en)");
        });
      }
    });
    languageChanged = true;
  }

  Color _getContainerColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey.shade900 : Colors.white;
  }

  List<Color> _getBackgroundColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? [Colors.grey.shade900, Colors.grey.shade800, Colors.grey.shade400]
        : [Colors.blue.shade900, Colors.blue.shade800, Colors.blue.shade400];
  }
}


class PrivacyPolicyScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'This is the Privacy Policy text. Replace this placeholder with your actual privacy policy content.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}


// Helper function to get container color based on theme
Color _getContainerColor(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return isDarkMode ? Colors.grey.shade900 : Colors.white;
}

List<Color> _getBackgroundColors(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return isDarkMode
      ? [Colors.grey.shade900, Colors.grey.shade800, Colors.grey.shade400]
      : [Colors.blue.shade900, Colors.blue.shade800, Colors.blue.shade400];
}