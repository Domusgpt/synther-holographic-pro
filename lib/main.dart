// SYNTHER UNIFIED - PROFESSIONAL IMPLEMENTATION
// Combines all best implementations into one cohesive app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Professional Audio Engine
import 'core/audio_engine_factory.dart';
import 'core/audio_engine.dart';
import 'core/synth_parameters.dart';

// Firebase Services
import 'services/firebase_service.dart';

// Professional Synthesizer Interface (Complete)
import 'ui/professional_synthesizer_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with proper error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");

    // Initialize Firebase services after core app initialization
    await FirebaseService.instance.initialize();
    print("FirebaseService initialized.");

  } catch (e) {
    print('🔥🔥🔥 Firebase core initialization failed: $e');
    // Depending on the app's requirements, you might want to:
    // 1. Show a specific error UI to the user.
    // 2. Allow the app to continue with Firebase features disabled.
    // For now, we print the error and let the app continue,
    // FirebaseService.instance.initialize() also has fallbacks.
  }
  
  // Set system UI for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Request audio permissions (optional for web)
  try {
    await _requestAudioPermissions();
  } catch (e) {
    print('⚠️ Audio permission request failed (continuing anyway): $e');
  }
  
  // Create audio engine and synth parameters with error handling
  AudioEngine? audioEngine;
  SynthParametersModel? synthParameters;
  
  try {
    audioEngine = createAudioEngine();
    await audioEngine.init();
    synthParameters = SynthParametersModel();
    print("Audio engine initialized successfully");
  } catch (e) {
    print('⚠️ Audio engine initialization failed: $e');
    // Create fallback instances
    audioEngine = createAudioEngine();
    synthParameters = SynthParametersModel();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioEngine>.value(value: audioEngine),
        ChangeNotifierProvider<SynthParametersModel>.value(value: synthParameters),
        Provider<FirebaseService>.value(value: FirebaseService.instance),
      ],
      child: const SyntherApp(),
    ),
  );
}

Future<void> _requestAudioPermissions() async {
  debugPrint('🎤 Requesting audio permissions...');
  
  try {
    // Check if we're on web first
    if (kIsWeb) {
      debugPrint('🌐 Web platform detected - skipping mic permission request');
      return;
    }
    
    final micStatus = await Permission.microphone.request();
    debugPrint('Microphone permission: $micStatus');
    
    if (micStatus.isGranted) {
      debugPrint('✅ Audio permissions granted!');
    } else {
      debugPrint('❌ Audio permissions denied');
    }
  } catch (e) {
    debugPrint('⚠ Permission request error: $e');
  }
}

class SyntherApp extends StatelessWidget {
  const SyntherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Professional Holographic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProfessionalSynthesizerInterface(),
    );
  }
}