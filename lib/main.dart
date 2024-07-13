import 'package:flutter/material.dart';
import 'package:kasa/screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: currentThemeMode,
          debugShowCheckedModeBanner: false,
          home: HomeScreen(
            themeMode: _themeMode,
          ),
        );
      },
    );
  }
}
