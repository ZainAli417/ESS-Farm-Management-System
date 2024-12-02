import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../Screens/Splash.dart';
import 'Constant/ISSAASProvider.dart';
import 'Constant/forget_password_provider.dart';
import 'Constant/login_provider.dart';
import 'Constant/splash_provider.dart'; // Replace with your actual provider file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
        ),ChangeNotifierProvider<ISSAASProvider>(
          create: (_) => ISSAASProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Project Drone',
        home: SplashScreen(), // Only the SplashScreen is launched initially
      ),
    );
  }
}
