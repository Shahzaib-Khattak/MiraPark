import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira_parkk/Login_Screen.dart';
import 'ForgotPasswordScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpVerificationScreen extends StatefulWidget {
  final bool isFromForgotPassword;
  final String email;


  const SignUpVerificationScreen({Key? key , required this.email, required this.isFromForgotPassword,}) : super(key: key);
  @override
  _SignUpVerificationScreenState createState() => _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool isDarkMode;
  late int timerSeconds;
  late bool showResendButton;
  late Timer _timer;

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
    try {
      var verificationResponse = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email, // Use the email passed from Login_Screen
        }),
      );

      // Follow redirects until we get a non-308 response
      while (verificationResponse.statusCode == 308) {
        var redirectUrl = verificationResponse.headers['location'];

        // Make another POST request to the redirect URL
        verificationResponse = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email, // Use the email passed from Login_Screen
          }),
        );
      }

      // Now check the final response
      if (verificationResponse.statusCode == 200) {
        print('Verification successful');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordScreen(
              email: widget.email,
              showPasswordFields: true,
            ),
          ),
        );

        // Navigate to the next screen or perform other actions as needed
      } else {
        print('Failed to verify code');
      }
    } catch (error) {
      print('Error verifying code: $error');
    }
  }


  Future<void> resendCode() async {
    try {
      var resendResponse = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email, // Use the email passed from Login_Screen
        }),
      );

      // Follow redirects until we get a non-308 response
      while (resendResponse.statusCode == 308) {
        var redirectUrl = resendResponse.headers['location'];

        // Make another POST request to the redirect URL
        resendResponse = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email, // Use the email passed from Login_Screen
          }),
        );
      }

      // Now check the final response
      if (resendResponse.statusCode == 200) {
        print('Verification code resent');
        // Show notification or handle UI accordingly
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
                child: Theme(
                  data: ThemeData.light(),
                  child: Image.asset(
                    'assets/app_icon.png',
                    color: Theme.of(context).brightness == Brightness.light
                        ? Color.fromRGBO(255, 255, 255, 0.7)
                        : Color.fromRGBO(255, 255, 255, 0.7),
                    colorBlendMode: BlendMode.modulate,
                  ),
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
                      children: [
                        _textFieldOTP(context, first: true, last: false),
                        SizedBox(width: 10),
                        _textFieldOTP(context, first: false, last: false),
                        SizedBox(width: 10),
                        _textFieldOTP(context, first: false, last: false),
                        SizedBox(width: 10),
                        _textFieldOTP(context, first: false, last: false),
                        SizedBox(width: 10),
                        _textFieldOTP(context, first: false, last: false),
                        SizedBox(width: 10),
                        _textFieldOTP(context, first: false, last: true),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              MaterialButton(
                onPressed: () {
                  if (widget.isFromForgotPassword) {
                    // Navigate to ForgotPasswordScreen and pass the showPasswordFields argument as true
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(showPasswordFields: true, email: widget.email,),
                      ),
                    );
                  } else {
                    // Navigate to LoginScreen
                    Navigator.pop(context); // Close the current screen before navigating
                  }
                },
                height: 50,
                color: Colors.blue.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.verify,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18),
              TextButton(
                onPressed: showResendButton
                    ? () {
                  // Close the keyboard
                  FocusScope.of(context).unfocus();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.verificationcodesent,
                        style: TextStyle(
                          color: isDarkMode ? Colors.lightGreen : Colors.lightGreen, // Adjust text color for dark mode
                        ),
                      ),
                      duration: Duration(seconds: 2),
                      backgroundColor:
                      isDarkMode ? Colors.blueGrey : Colors.blueGrey, // Adjust background color for dark mode
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: isDarkMode ? 4.0 : 0.0,
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.dismiss,
                        textColor: Colors.lightGreenAccent,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );

                  setState(() {
                    timerSeconds = 5;
                    showResendButton = false;
                    _startTimer();
                  });
                }
                    : null,
                child: Text(
                  showResendButton
                      ? AppLocalizations.of(context)!.resendCode
                      : "${AppLocalizations.of(context)!.didntReceiveCode} ${timerSeconds}s",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: showResendButton
                        ? isDarkMode
                        ? Colors.white // Change purple to green in dark mode
                        : Colors.black
                        : isDarkMode
                        ? Colors.white70
                        : Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldOTP(BuildContext context, {required bool first, required bool last}) {
    return Container(
      width: 40,
      height: 50,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: TextField(
          autofocus: true,
          onChanged: (value) {
            if (value.length == 1 && !last) {
              FocusScope.of(context).nextFocus();
            }
            if (value.length == 0 && !first) {
              FocusScope.of(context).previousFocus();
            }
          },
          showCursor: false,
          readOnly: false,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          maxLength: 1,
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
        ),
      ),
    );
  }
}
