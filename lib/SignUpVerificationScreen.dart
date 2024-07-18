import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ForgotPasswordScreen.dart'; // Assuming this is where ForgotPasswordScreen is defined
import 'Login_Screen.dart'; // Assuming this is where Login_Screen is defined

class SignUpVerificationScreen extends StatefulWidget {
  final bool isFromForgotPassword;
  final String email;

  const SignUpVerificationScreen({
    Key? key,
    required this.email,
    required this.isFromForgotPassword,
  }) : super(key: key);

  @override
  _SignUpVerificationScreenState createState() => _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool isDarkMode;
  late int timerSeconds;
  late bool showResendButton;
  late Timer _timer;
  bool isLoading = false;
  String verificationStatus = '';

  List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    timerSeconds = 5;
    showResendButton = false;
    _startTimer();
    print('Email: ${widget.email}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 1) {
          timerSeconds--;
        } else {
          timer.cancel();
          showResendButton = true;
        }
      });
    });
  }

  Future<void> verifyCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      String otp = _controllers.map((controller) => controller.text).join('');

      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'verificationCode': otp,
        }),
      );

      // Handle redirections (301, 308)
      while (response.statusCode == 301 || response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Redirect location not provided');
        }

        // Make another POST request to the redirect URL
        response = await http.post(
          Uri.parse(redirectUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'verificationCode': otp,
          }),
        );
      }

      // Now check the final response
      if (response.statusCode == 200) {
       if(!widget.isFromForgotPassword){
         Fluttertoast.showToast(
           msg: 'Verification successful',
           toastLength: Toast.LENGTH_SHORT,
           gravity: ToastGravity.BOTTOM,
           backgroundColor: Colors.green,
           textColor: Colors.white,
           fontSize: 16.0,
         );
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(
             builder: (context) => Login_Screen(
               email: widget.email,
               updateLocale: (Locale locale) {
                 // Handle locale update
               },
             ),
           ),
         );

       }
        setState(() {
          verificationStatus = 'Verification successful';
        });

        // Navigate based on the flag
        if (widget.isFromForgotPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ForgotPasswordScreen(
                email: widget.email,
                showPasswordFields: true,
              ),
            ),
          );

        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Login_Screen(
                email: widget.email,
                updateLocale: (Locale locale) {
                  // Handle locale update
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to verify code');
      }
    } catch (error) {
      print('Error verifying code: $error');
      setState(() {
        verificationStatus = 'Error verifying code';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resendCode() async {
    try {
      var resendResponse = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      // Follow redirects until we get a non-308 response
      while (resendResponse.statusCode == 308) {
        var redirectUrl = resendResponse.headers['location'];

        resendResponse = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
          }),
        );
      }

      if (resendResponse.statusCode == 200) {
        print('Verification code resent');
      } else {
        print('Failed to resend verification code');
      }
    } catch (error) {
      print('Error resending verification code: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                    size: 32,
                    color: isDarkMode ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Container(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/app_icon.png',
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.verification,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.grey : Color.fromRGBO(158, 158, 158, 1.0),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.enterverificationcode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black38,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                            (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: TextField(
                              controller: _controllers[index],
                              autofocus: index == 0,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counter: Offstage(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 2,
                                    color: isDarkMode ? Colors.grey : Colors.lightBlue,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 2,
                                    color: isDarkMode ? Colors.lightBlue : Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length == 1 && index < 5) {
                                  FocusScope.of(context).nextFocus();
                                } else if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).previousFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text(
                    AppLocalizations.of(context)!.verify,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 18),
              showResendButton
                  ? TextButton(
                onPressed: () async {
                  setState(() {
                    showResendButton = false;
                    timerSeconds = 5;
                  });
                  _startTimer();
                  await resendCode();
                },
                child: Text(
                  AppLocalizations.of(context)!.resendCode,
                  style: TextStyle(color: Colors.blue),
                ),
              )
                  : Text(
                '${AppLocalizations.of(context)!.resendCode} $timerSeconds ${AppLocalizations.of(context)!.resendCode}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black38),
              ),
              SizedBox(height: 18),
              Text(
                verificationStatus,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
