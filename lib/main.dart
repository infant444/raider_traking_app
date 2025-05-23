import 'package:flutter/material.dart';
import 'package:raider_traking_app/Component/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Tracking());
}

class Tracking extends StatelessWidget {
  const Tracking({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Text',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {"/": (context) => Home()},
    );
  }
}
