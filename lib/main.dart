// SYNTHER UNIFIED - PROFESSIONAL IMPLEMENTATION
// Combines all best implementations into one cohesive app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';

// Professional Audio Engine
import 'core/audio_engine_factory.dart';
import 'core/audio_engine.dart';
import 'core/synth_parameters.dart';

// Firebase Services
import 'services/firebase_service.dart';

// Professional Interface
import 'interactive_draggable_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase services
  await FirebaseService.instance.initialize();
  
  // Set system UI for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Request audio permissions immediately
  await _requestAudioPermissions();
  
  // Create audio engine and synth parameters
  final audioEngine = createAudioEngine();
  await audioEngine.init();
  
  final synthParameters = SynthParametersModel();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioEngine>.value(value: audioEngine),
        ChangeNotifierProvider<SynthParametersModel>.value(value: synthParameters),
        Provider<FirebaseService>.value(value: FirebaseService.instance),
      ],
      child: const InteractiveDraggableSynth(),
    ),
  );
}

Future<void> _requestAudioPermissions() async {
  debugPrint('🎤 Requesting audio permissions...');
  
  try {
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