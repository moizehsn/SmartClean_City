import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'core/theme/app_theme.dart';
import 'features/auth/inscription_screen.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const SmartCleanApp());
}

class SmartCleanApp extends StatelessWidget {
  const SmartCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartClean City',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const InscriptionScreen(),
    );
  }
}