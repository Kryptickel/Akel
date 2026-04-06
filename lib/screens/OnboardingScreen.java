import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
const OnboardingScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,
body: SafeArea(
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Image.asset(
'assets/images/EMERGENCY PANIC BUTTON.png',
height: 200,
),
const SizedBox(height: 30),
const Text(
'Welcome to AKEL Panic Button',
style: TextStyle(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 10),
const Text(
'Stay protected with real-time emergency tools\nand AI-powered safety support.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white70,
fontSize: 16,
),
),
const SizedBox(height: 40),
ElevatedButton(
onPressed: () {
// Later: Navigate to main dashboard
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text(
'Get Started',
style: TextStyle(color: Colors.white, fontSize: 18),
),
),
],
),
),
),
);
}
}

