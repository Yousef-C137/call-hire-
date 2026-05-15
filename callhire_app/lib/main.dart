import 'package:flutter/material.dart';
import 'screens/choice_screen.dart';

void main() {
  runApp(const CallHireApp());
}

class CallHireApp extends StatelessWidget {
  const CallHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallHire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          primary: Colors.blue.shade900,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ChoiceScreen(),
    );
  }
}
