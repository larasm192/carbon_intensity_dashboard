import 'package:flutter/material.dart';
import 'themes.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Carbon Intensity Dashboard';
    return MaterialApp(
      title: appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const Dashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
