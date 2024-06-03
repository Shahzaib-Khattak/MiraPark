import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Make sure you have a MainScreen class available

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().whenComplete(() => checkLoginStatus());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/Splashscreen.png",
            fit: BoxFit.cover,
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeIn(
                    delay: Duration(milliseconds: 300),
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/app_icon.png"),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  FadeIn(
                    delay: Duration(milliseconds: 800),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: child,
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ).createShader(bounds);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            "MiPark",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Default to false if not set

    if (isLoggedIn) {
      String userId = prefs.getString('userId') ?? ''; // Safely handle null values

      Navigator.of(context).pushReplacementNamed('/main_screen', arguments: userId);
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}