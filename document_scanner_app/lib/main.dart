import 'package:document_scanner_app/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:document_scanner_app/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    final materialTheme = MaterialTheme(textTheme);

    return MaterialApp(
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      highContrastTheme: materialTheme.lightHighContrast(),
      highContrastDarkTheme: materialTheme.darkHighContrast(),

      themeMode: ThemeMode.system,

      home: const HomePage(),
    );
  }
}
