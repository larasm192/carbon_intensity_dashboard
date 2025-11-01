import 'package:flutter/material.dart';
import 'carbon_api.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  // Define additional light theme properties here
);
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    color: const Color.fromRGBO(27, 154, 139, 100),
    // Define additional dark theme properties here
  ),
);
