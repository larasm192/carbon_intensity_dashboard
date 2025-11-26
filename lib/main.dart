import 'package:flutter/material.dart';
import 'themes.dart';
import 'dashboard.dart';
import 'carbon_api.dart';

void main() async {
  final list = await fetchTodayIntensities();
  print('Loaded ${list.length} intervals');
  print(
    'First one: ${list.first.to} | ${list.first.actualIntensity} gCO₂/kWh | ${list.first.forecastIntensity}',
  );
  final current = await fetchCurrentIntensity();
  print(current.index);
  print(current.from.toString().substring(11, 16));
  print(current.intensity);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Flutter layout demo';
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
