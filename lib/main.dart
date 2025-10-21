import 'package:flutter/material.dart';
import 'package:valid_weather/pages/main_screen.dart';

void main() {
  runApp(const ValidWeatherApp());
}

class ValidWeatherApp extends StatelessWidget {
  const ValidWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: const MainScreen(),
    );
  }
}