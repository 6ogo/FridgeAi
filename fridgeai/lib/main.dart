import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_page.dart';
import 'dart:io';

void main() async {
  try {
    await dotenv.load();  // Just use load() without fileName parameter
    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      print("Error loading .env file: $e");
      print("Current directory: ${Directory.current.path}");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Fridge Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}