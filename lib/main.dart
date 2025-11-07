
import 'package:flutter/material.dart';
import 'welcome_page.dart';
import 'camera_page.dart';
import 'bg_processing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Photo Magic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomePage(),
      routes: {
        '/camera': (context) => const CameraToBgFlowPage(),

      },
    );
  }
}