import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and other services
  await initializeApp();
  
  runApp(
    const ProviderScope(
      child: AkelApp(),
    ),
  );
}

Future<void> initializeApp() async {
  // Initialize Firebase
  // await Firebase.initializeApp();
  
  // Initialize local storage
  // await Hive.initFlutter();
  
  // Initialize background services
  // await WorkManager().initialize();
  
  // Request necessary permissions
  // await requestPermissions();
}

Future<void> requestPermissions() async {
  // Request location permissions
  // Request camera permissions
  // Request microphone permissions
  // Request storage permissions
  // Request phone permissions
}