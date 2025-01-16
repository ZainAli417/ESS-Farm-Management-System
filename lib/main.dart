import 'package:ess_fms/Screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Screens/Splash.dart';
import 'Constant/forget_password_provider.dart';
import 'Constant/login_provider.dart';
import 'Constant/splash_provider.dart';
import 'Screens/ForgetPasswordScreen.dart';
import 'Screens/drawer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginProvider>(
          create: (_) => LoginProvider(),
        ),
        ChangeNotifierProvider<ForgotPasswordProvider>(
          create: (_) => ForgotPasswordProvider(),
        ),
        ChangeNotifierProvider<SplashProvider>(
          create: (_) => SplashProvider(),
        ),
      ],
      child: const MaterialApp(
        title: 'ESS-Farm Management System',
        home: AuthCheck(), // Use AuthCheck to determine whether to show Drawer or Login
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the user is signed in with FirebaseAuth
    final User? user = FirebaseAuth.instance.currentUser;

    // If the user is signed in, navigate to the Drawer screen; otherwise, show LoginScreen
    if (user != null) {
      return const DrawerNavbar(); // Show the screen with Drawer
    } else {
      return const LoginScreen(); // Show the login screen
    }
  }
}
