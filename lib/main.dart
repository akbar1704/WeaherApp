import 'package:flutter/material.dart';
import 'package:weather_app/pages/home_page.dart';
import 'package:weather_app/pages/forecast_page.dart';
import 'package:weather_app/pages/login_page.dart';
import 'package:weather_app/pages/register_page.dart';
import 'package:weather_app/pages/splash_screen.dart'; // Import the splash screen
import 'package:weather_app/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // Set SplashScreen as the initial route
      routes: {
        '/home': (context) => HomePage(
            userDetails: ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>?),
        '/forecast': (context) => const ForecastPage(city: ''),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/profile': (context) => ProfilePage(
            userDetails: ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>),
      },
    );
  }
}
