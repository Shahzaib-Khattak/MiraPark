import 'dart:async';
import 'dart:convert';
import 'package:abstract_bloc/abstract_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mira_parkk/Map_Screen.dart';
import 'ForgotPasswordScreen.dart';
import 'ThemeModelCubit.dart';
import 'main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mira_parkk/SignUpVerificationScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';



class Login_Screen extends StatefulWidget {
  final Function(Locale) updateLocale; // Add a callback function to update the locale

  Login_Screen({Key? key, required this.updateLocale, required String email}) : super(key: key);


  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login_Screen> {
  bool isLoggedIn = false;
  String selectedLanguage = 'English';
  bool showSignUp = false;
  bool _isPasswordVisible = false;
  bool isProcessingRequest = false;
  bool isLoginSuccessful = false;
  bool isNotLoginSuccessful = true;
// Declare and initialize isLoginSuccessful
  Color buttonColor = Colors.blue.shade900;
  FocusNode _emailFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();
  FocusNode _fullnameFocus = FocusNode();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _fullnameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  // DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  Future<void> signin() async {
    await GoogleSignInApi.logout(); // Ensure previous user is signed out
    final user = await GoogleSignInApi.login();
    if (user != null) {
      print('Name: ${user.displayName}');
      print('Email: ${user.email}');
      print('Profile Picture: ${user.photoUrl}');

      // Check if user already exists
      final userQuery = await _firestore.collection('googleuser').where('email', isEqualTo: user.email).get();
      String userId;

      if (userQuery.docs.isNotEmpty) {
        userId = userQuery.docs.first.id;
        print('Existing user ID: $userId');
      } else {
        var uuid = Uuid();
        userId = uuid.v4().replaceAll('-', '').substring(0, 24); // Generate a 24 character alphanumeric string
        await _firestore.collection('googleuser').doc(userId).set({
          'name': user.displayName,
          'email': user.email,
          'PhoneNumber': 'N/A',
          'profilePic': user.photoUrl,
        });
        print('New user ID generated: $userId');
      }

      Fluttertoast.showToast(
        msg: 'Sign in Successful',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Pass user ID to MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userId: userId, // Pass the user ID here
            updateLocale: widget.updateLocale,
            locationName: 'Mira Park',
          ),
        ),
      );

      print('User information saved to Firestore');
    } else {
      print('Sign in failed');
    }
  }


  Future<void> signup() async {
    await GoogleSignInApi.logout(); // Ensure previous user is signed out
    final user = await GoogleSignInApi.login();
    if (user != null) {
      print('Name: ${user.displayName}');
      print('Email: ${user.email}');
      print('Profile Picture: ${user.photoUrl}');

      // Save user data to Firestore
      await _firestore.collection('googleuser').doc(user.id).set({
        'name': user.displayName,
        'email': user.email,
        'PhoneNumber' : 'N/A',
        'profilePic': user.photoUrl,
      });

      print('Sign in successfulaskhddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddjsjkdahdjhasjkdhajkshd with userid: ${user.id}');
      Fluttertoast.showToast(
        msg: 'Sign Up Successful',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // Pass user ID to MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userId: user.id, // Pass the user ID here
            updateLocale: widget.updateLocale,
            locationName: 'Mira Park',
          ),
        ),
      );

      print('User information saved to Firestore and Realtime Database');
    } else {
      print('Sign in failed');
    }
  }



  Future<void> _handleSignIn() async {
    try {
      print('enter handle sign in with google');
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('this part is okay');
      if (googleUser != null) {
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        String? idToken = googleAuth.idToken;
        if (idToken != null) {
          final response = await http.post(
            Uri.parse('http://mi-park-backend-iota.vercel.app/api/auth/google'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'idToken': idToken,
            }),
          );

          if (response.statusCode == 200) {
            Fluttertoast.showToast(
              msg: 'Login Successful',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(userId: 'userId', updateLocale: widget.updateLocale, locationName: 'Mira Park'),
              ),
            );
            print('Successfully signed in');
          } else {
            print('Failed to sign in');
          }
        }
      }
    } catch (error) {
      print(error);
    }
  }


  Future<void> signUp() async {
    if (_fullnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      // Display toast message for missing input
      Fluttertoast.showToast(
        msg: 'Please input all fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Exit the function early
    }

    try {
      var registerResponse = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullnameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
        }),
      );

      // Follow redirects until we get a non-308 response
      while (registerResponse.statusCode == 308) {
        var redirectUrl = registerResponse.headers['location'];

        // Make another POST request to the redirect URL
        registerResponse = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': _fullnameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'password': _passwordController.text,
          }),
        );
      }

      // Now check the final response
      if (registerResponse.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'Registration successful!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpVerificationScreen(isFromForgotPassword: false, email: _emailController.text),
          ),
        );
      } else {
        // Registration failed
        Fluttertoast.showToast(
          msg: 'Registration Error: ${registerResponse.body}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (error) {
      // Handle network or other errors
      Fluttertoast.showToast(
        msg: 'Something went wrong. Please try again later.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }




  Future<void> login() async {
    // Check if email and password fields are empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      // Display error message using a Toast
      Fluttertoast.showToast(
        msg: 'Please input all fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Exit the function early
    }

    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Handle nullable redirectUrl using the null coalescing operator
        response = await http.post(
          Uri.parse(redirectUrl ?? ''), // Provide default value if redirectUrl is null
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );
      }

      // Now check the final response
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var userId = responseData['userId'];

        // Store login status
        await _storeLoginStatus(userId);

        setState(() {
          isLoggedIn = true;
        });

        isLoginSuccessful = true;

        // Display success message using a Toast
        Fluttertoast.showToast(
          msg: 'Login successful!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Navigate to the main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userId: userId, updateLocale: widget.updateLocale, locationName: 'Mira Park'),
          ),
        );
      } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        // Login failed, show error message
        Fluttertoast.showToast(
          msg: 'Invalid email or password',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        print('Login failed: ${response.body}');
        setState(() {
          isNotLoginSuccessful = true;
          print('state saved to login not successful');
        });

        isProcessingRequest = false;
        print('is processing false');
      }
    } catch (error) {
      // Handle login error
      print('Error during login: $error');
      // Show generic error message
      Fluttertoast.showToast(
        msg: 'Something went wrong. Please try again later.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> showErrorDialog(String errorMessage) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _storeLoginStatus(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    print('Login status stored successfully');
    await prefs.setBool('isLoggedIn', true);  // Also store a flag indicating the login status
    print('Login status stored successfully');
    // On Login
  }



  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _fullnameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        centerTitle: false,
        leading: null,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.blue.shade700
            : Colors.blue.shade700,
        actions: [
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                var themeMode = value ? ThemeMode.dark : ThemeMode.light;
                BlocProvider.of<ThemeModeCubit>(context).setTheme(themeMode);
              },
              activeThumbImage: AssetImage('assets/moon.png'),
              inactiveThumbImage: AssetImage('assets/sun.png'),
            ),
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              Theme.of(context).brightness == Brightness.light
                  ? 'Light Mode'
                  : 'Dark Mode',
              style: TextStyle(
                fontSize: 16, // Adjust the text size here
                color: Colors.white, // Ensure text color is white
              ),
            ),
          ],
        ),
      ),




      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Center(
                              child: FractionalTranslation(
                                translation: Offset(0, 0),
                                child: Image.asset(
                                  'assets/app_icon.png',
                                  color: Color.fromRGBO(255, 255, 255, 0.7),
                                  colorBlendMode: BlendMode.modulate,
                                  height: 100,
                                  width: 100,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showSignUp = false;
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.login,
                            style: TextStyle(
                              color: !showSignUp
                                  ? Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white
                                  : Colors.grey.withOpacity(0.3),
                              fontSize: 30,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "|",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                            fontSize: 30,
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showSignUp = true;
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.signup,
                            style: TextStyle(
                              color: showSignUp
                                  ? Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white
                                  : Colors.grey.withOpacity(0.5),
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Visibility(
                      visible: !showSignUp,

                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(158, 158, 158, 1.0),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.email,
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.password,
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: _isPasswordVisible ? Colors.blue : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: showSignUp,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(158, 158, 158, 1.0),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.email,
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: TextField(
                                controller: _fullnameController,
                                focusNode: _fullnameFocus,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.fullName,
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.password,
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon:Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: _isPasswordVisible ? Colors.blue : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.phonenumber,
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Visibility(
                      visible: !showSignUp,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ForgotPasswordScreen(showPasswordFields: false, email: _emailController.text,)),
                          ).then((value) {
                            // Handle result if needed
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.forgotPassword,
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        signin();
                      },
                      child: MaterialButton(
                        onPressed: () {
                          if (!isProcessingRequest) {
                            if (showSignUp) {
                              signUp();
                            } else {
                              setState(() {
                                isProcessingRequest = true; // Set flag to indicate processing request
                              });
                              login().then((_) {
                                setState(() {
                                  isProcessingRequest = false; // Reset flag when request is completed
                                });
                                if (isNotLoginSuccessful) {
                                  print( isNotLoginSuccessful);
                                  setState(() {
                                    isProcessingRequest = false;
                                  });
                                }
                              });
                            }
                          }
                        },
                        height: 50,
                        color: isProcessingRequest ? Colors.grey.shade400 : Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            showSignUp ? AppLocalizations.of(context)!.signup : AppLocalizations.of(context)!.login,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),

                    SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextButton(
                        onPressed: () {
                          signup();
                        },
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.resolveWith((states) {
                            // Check if the theme mode is light or dark
                            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                            // Return appropriate color based on theme mode
                            return isDarkMode ? Colors.white : Colors.black;
                          }),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.google,
                              color: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              showSignUp ? AppLocalizations.of(context)!.signUpWithGoogle : AppLocalizations.of(context)!.loginWithGoogle,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            // Add any other widgets below the container
          ],
        ),
      ),
    );
  }

}


class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn();

  static Future<GoogleSignInAccount?> login() => _googleSignIn.signIn();

  static Future<void> logout() => _googleSignIn.signOut();
}
