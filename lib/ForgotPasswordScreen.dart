import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mira_parkk/Login_Screen.dart';
import 'SignUpVerificationScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ForgotPasswordScreen extends StatefulWidget {
  final bool showPasswordFields;
  final String email;

  const ForgotPasswordScreen({Key? key, required this.showPasswordFields, required this.email}) : super(key: key);



  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _showPasswordFields = false;


  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _showPasswordFields = widget.showPasswordFields;

    print('Email: ${_emailController.text}');
  }
  Future<void> forgotPassword() async {
    print('Sending forgot password request for email: ${_emailController.text}');
    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/forgot-password'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
        }),
      );

      // Check for redirect status codes
      while (response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) {
        var newUrl = response.headers['location'];
        if (newUrl != null) {
          response = await http.post(
            Uri.parse(newUrl),
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'email': _emailController.text,
            }),
          );
        } else {
          break; // Break the loop if no location header is present
        }
      }

      // Final check of the response
      if (response.statusCode == 200) {
        print('Check your email for the verification code.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _continueButtonPressed(context);
        });

        // Redirect to the verification screen
        Fluttertoast.showToast(
          msg: 'verification code sent to Email ${_emailController.text}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpVerificationScreen(isFromForgotPassword: true, email: _emailController.text,),
          ),
        );
      } else {
        print('Error in sending email after redirects: ${response.body}');
      }
    } catch (error) {
      print('Error in sending email: $error');
    }
  }

  Future<void> resetPassword() async {
    print('Attempting to reset password for email: ${_emailController.text}');
    print('New password: ${newPasswordController.text}');
    Uri url = Uri.parse('http://mi-park-backend-iota.vercel.app/reset-password');
    try {
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text,  // Include the email in the request
          'newPassword': newPasswordController.text,
        }),
      );

      // Check for redirect status codes
      while (response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) {
        var newUrl = response.headers['location'];
        if (newUrl != null) {
          response = await http.post(
            Uri.parse(newUrl),
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': _emailController.text,  // Ensure the email is included during the redirection
              'newPassword': newPasswordController.text,
            }),
          );
        } else {
          break; // Break the loop if no location header is present
        }
      }

      // Final check of the response
      if (response.statusCode == 200) {
        print('Password reset successfully');
        Fluttertoast.showToast(
          msg: 'Password reset successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pushReplacement(context,
          MaterialPageRoute(
            builder: (_) => Login_Screen( email: _emailController.text, updateLocale: (Locale ) {  }, ), ),
        );
        // Handle successful password reset here
      } else {
        print('Failed to reset password: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while trying to reset password: $e');
    }
  }

  void _continueButtonPressed(BuildContext context) {
    if (!_showPasswordFields) {
      // If email is provided, move to verification screen
      if (_emailController.text.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpVerificationScreen(isFromForgotPassword: true, email: _emailController.text,),
          ),
        );
      } else {
        // Show error if email field is empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enterEmailorPhoneNumber ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Password reset process
      _resetPassword(context);
    }
  }

  void _resetPassword(BuildContext context) {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillinfields),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordsdonotmatch),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Perform password reset here, navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Login_Screen(email: _emailController.text,  updateLocale: (Locale ) {  },), // Replace LoginScreen with your actual login screen
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.passwordresetsuccessfully),
        duration: Duration(seconds: 2),
      ),
    );
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    super.didChangeDependencies();
    _showPasswordFields = ModalRoute.of(context)?.settings.arguments as bool? ?? widget.showPasswordFields;

    // Check if the route arguments indicate coming back from verification
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('fromVerification') && args['fromVerification'] == true) {
      setState(() {
        _showPasswordFields = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: getGradientColors(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 10, top: screenHeight * 0.06),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10, top: 50),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!.resetYourPassword,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.03),
                      Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.8) // Adjust the opacity and color as needed
                                    : Color.fromRGBO(158, 158, 158, 1.0),
                                blurRadius: 20,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child : SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width : double.infinity,
                                  padding: EdgeInsets.only(left: 8, right: 8,top: 0, bottom: 0),
                                  decoration: BoxDecoration(

                                  ),
                                  child: Visibility(
                                    visible: !widget.showPasswordFields,
                                    child: TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.enterregisteredEmailphoneNumber,
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),

                                if (_showPasswordFields)
                                  Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(left: 8, right: 8,top: 0, bottom: 0),
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                        ),
                                        child: TextField(
                                          controller: newPasswordController,
                                          obscureText: !_isPasswordVisible,
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                          decoration: InputDecoration(
                                            hintText: AppLocalizations.of(context)!.newPassword,
                                            hintStyle: TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                            suffixIcon: IconButton(
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
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(left: 8, right: 8,top: 0, bottom: 0),
                                        child: TextField(
                                          controller: confirmPasswordController,
                                          obscureText: !_isPasswordVisible,
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                          decoration: InputDecoration(
                                            hintText: AppLocalizations.of(context)!.retypeNewPassword,
                                            hintStyle: TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                              ],
                            ),
                          )
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      MaterialButton(
                        onPressed:  _showPasswordFields ? resetPassword : forgotPassword ,
                        height: screenHeight * 0.07,
                        color: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            _showPasswordFields
                                ? AppLocalizations.of(context)!.continuue
                                : AppLocalizations.of(context)!.continuue,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20), // Space between buttons
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<Color> getGradientColors(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      // Dark mode colors
      return [
        Colors.grey.shade900,
        Colors.grey.shade800,
        Colors.grey.shade400,
      ];
    } else {
      // Light mode colors
      return [
        Colors.blue.shade900,
        Colors.blue.shade800,
        Colors.blue.shade400,
      ];
    }
  }
}
