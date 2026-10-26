import 'package:flutter/material.dart';
import 'screens/home.dart';

const navy = Color(0xFF102A43);
const blue = Color(0xFF1976D2);
const pageBg = Color(0xFFF5F7FB);

void main() => runApp(const ControlApp());

class ControlApp extends StatelessWidget {
  const ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الكنترول المدرسي',
      builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
        scaffoldBackgroundColor: pageBg,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
            backgroundColor: pageBg,
            foregroundColor: navy,
            centerTitle: false,
            elevation: 0),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}