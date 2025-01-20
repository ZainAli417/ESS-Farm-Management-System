import 'package:ess_fms/Screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Constant/splash_provider.dart';
import 'LoginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late SplashProvider splashProvider;

  @override
  void initState() {
    super.initState();
    splashProvider = SplashProvider();
    splashProvider.initControllers(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload the images before rendering
    precacheImage(const AssetImage('images/bg.jpeg'), context);
    precacheImage(const AssetImage('images/logo.png'), context);
    splashProvider.startAnimations();
  }

  @override
  void dispose() {
    splashProvider.disposeControllers();
    super.dispose();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);


        _showSnackbar_connection(context, 'Welcome, ${userCredential.user?.displayName}');
        Future.delayed(Durations.medium4);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }
  void _showSnackbar_connection(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
        duration: const Duration(seconds: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SplashProvider>(
      create: (_) => splashProvider,
      child: Scaffold(
        backgroundColor: Colors.black, // Temporary background color
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'images/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            Consumer<SplashProvider>(
              builder: (context, provider, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: provider.logoController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, provider.logoAnimation.value),
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'images/logo1.png',
                              width: 360,
                              height: 250,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: provider.buttonFadeAnimation,
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                );
                              },
                              icon: const Icon(
                                Icons.email,
                                color: Colors.white,
                                size: 24,
                              ),
                              label: Text(
                                'Continue with Email',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(132, 114, 58, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _handleGoogleSignIn();
                              },
                              icon: Image.asset(
                                'images/google.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              label: Text(
                                'Use Google Account',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF0A8C52),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.all(15),
                              ),
                            ),
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
