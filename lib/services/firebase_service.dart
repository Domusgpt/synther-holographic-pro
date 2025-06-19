import 'dart:convert';
import 'dart:io'; // Added for File operations
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../core/synth_parameters.dart';

/// Firebase service for Synther Professional
/// Handles authentication, presets, AI generation, and social features
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._internal(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      FirebaseFunctions.instance,
      FirebaseStorage.instance,
    );
    return _instance!;
  }

  // Add a constructor for testing
  @visibleForTesting
  FirebaseService.testable(this._auth, this._firestore, this._functions, this._storage);

  FirebaseService._internal(this._auth, this._firestore, this._functions, this._storage);
  
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  
  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  // Service availability flags
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Check if Firebase is properly configured
      if (_auth.app.options.apiKey.isEmpty || _auth.app.options.projectId.isEmpty) {
        print('🔥 Firebase not configured - running in offline mode');
        print('   See FIREBASE_SETUP_GUIDE.md for configuration instructions');
        _isAvailable = false;
        return;
      }
      
      // Skip functions emulator in production web deployment
      if (!kIsWeb) {
        try {
          _functions.useFunctionsEmulator('localhost', 5001);
        } catch (e) {
          print('Functions emulator not available: $e');
        }
      }
      
      // Test connection
      await _firestore.doc('test/connection').get();
      _isAvailable = true;
      print('✅ Firebase services initialized successfully');
      
      // Enable offline persistence for Firestore (web only, with additional safety)
      if (kIsWeb) {
        try {
          await _firestore.enablePersistence(
            const PersistenceSettings(synchronizeTabs: true),
          );
        } catch (e) {
          print('Firestore persistence error (expected in some cases): $e');
          // Persistence might already be enabled or not supported - this is okay
        }
      }
      
      // Anonymous sign-in for immediate use with additional null checks
      if (_isAvailable) {
        try {
          if (_auth.currentUser == null) {
            await signInAnonymously();
          }
        } catch (e) {
          print('Anonymous sign-in error: $e');
          // Continue without authentication - app should still work
        }
      }
      
    } catch (e) {
      print('🔥 Firebase initialization failed: $e');
      print('   The app will continue to work without cloud features');
      _isAvailable = false;
    }
  }
  
  // AUTHENTICATION METHODS
  
  /// Sign in anonymously for immediate app use
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during anonymous sign in: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Generic error during anonymous sign in: $e');
      return null;
    }
  }
  
  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during email sign in: ${e.code} - ${e.message}');
      // Example: Handle specific codes if needed by UI
      // if (e.code == 'user-not-found') { ... }
      // if (e.code == 'wrong-password') { ... }
      return null;
    } catch (e) {
      print('Generic error during email sign in: $e');
      return null;
    }
  }
  
  /// Create account with email and password
  Future<User?> createAccount(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Firestore
      await _createUserProfile(result.user!);
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during account creation: ${e.code} - ${e.message}');
      // Example: Handle specific codes
      // if (e.code == 'email-already-in-use') { ... }
      // if (e.code == 'weak-password') { ... }
      return null;
    } catch (e) {
      print('Generic error during account creation: $e');
      return null;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign out: ${e.code} - ${e.message}');
    } catch (e) {
      print('Generic error during sign out: $e');
    }
  }
  
  // USER PROFILE METHODS
  
  /// Create user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? 'Anonymous User',
      'createdAt': FieldValue.serverTimestamp(),
      'preferences': {
        'theme': 'holographic',
        'defaultOctave': 4,
        'visualizerIntensity': 0.8,
      },
      'statistics': {
        'presetsCreated': 0,
        'sessionsPlayed': 0,
        'totalPlayTime': 0,
      },
    });
  }
  
  /// Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'preferences': preferences});
    }
  }
  
  // PRESET MANAGEMENT METHODS
  
  /// Generate AI preset using Cloud Functions
  Future<SynthParameters?> generateAIPreset(String description) async {
    try {
      final callable = _functions.httpsCallable('generatePreset');
      final result = await callable.call({
        'description': description,
        'userId': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (result.data != null) {
        return SynthParameters.fromJson(result.data['preset']);
      }
      return null;
    } catch (e) {
      print('AI preset generation error: $e');
      return null;
    }
  }
  
  /// Save preset to Firestore
  Future<String?> savePreset({
    required String name,
    required String description,
    required SynthParameters parameters,
    bool isPublic = false,
    List<String> tags = const [],
  }) async {
    try {
      if (_auth.currentUser == null) return null;
      
      final presetData = {
        'name': name,
        'description': description,
        'parameters': parameters.toJson(),
        'userId': _auth.currentUser!.uid,
        'isPublic': isPublic,
        'tags': tags,
        'likes': 0,
        'downloads': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('presets').add(presetData);
      
      // Update user statistics
      await _incrementUserStat('presetsCreated');
      
      return docRef.id;
    } catch (e) {
      print('Save preset error: $e');
      return null;
    }
  }
  
  /// Get user's presets
  Stream<List<Preset>> getUserPresets() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('presets')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Preset.fromFirestore(doc))
            .toList());
  }
  
  /// Get public presets for discovery
  Stream<List<Preset>> getPublicPresets({int limit = 50}) {
    return _firestore
        .collection('presets')
        .where('isPublic', isEqualTo: true)
        .orderBy('likes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Preset.fromFirestore(doc))
            .toList());
  }
  
  /// Search presets by tags or description
  Future<List<Preset>> searchPresets(String query) async {
    try {
      // Simple text search (for advanced search, use Algolia or similar)
      final results = await _firestore
          .collection('presets')
          .where('isPublic', isEqualTo: true)
          .where('tags', arrayContains: query.toLowerCase())
          .limit(20)
          .get();
      
      return results.docs.map((doc) => Preset.fromFirestore(doc)).toList();
    } catch (e) {
      print('Search presets error: $e');
      return [];
    }
  }
  
  /// Like a preset
  Future<void> likePreset(String presetId) async {
    try {
      await _firestore.collection('presets').doc(presetId).update({
        'likes': FieldValue.increment(1),
      });
      
      // Track user likes (optional)
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('liked_presets')
            .doc(presetId)
            .set({'likedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print('Like preset error: $e');
    }
  }
  
  // SESSION TRACKING METHODS
  
  /// Start a new session
  Future<String?> startSession() async {
    try {
      if (_auth.currentUser == null) return null;
      
      final sessionData = {
        'userId': _auth.currentUser!.uid,
        'startTime': FieldValue.serverTimestamp(),
        'presetsUsed': <String>[],
        'parameterChanges': 0,
        'notesPlayed': 0,
      };
      
      final docRef = await _firestore.collection('sessions').add(sessionData);
      return docRef.id;
    } catch (e) {
      print('Start session error: $e');
      return null;
    }
  }
  
  /// End session and save analytics
  Future<void> endSession(String sessionId, Map<String, dynamic> analytics) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'endTime': FieldValue.serverTimestamp(),
        'duration': analytics['duration'] ?? 0,
        'presetsUsed': analytics['presetsUsed'] ?? [],
        'parameterChanges': analytics['parameterChanges'] ?? 0,
        'notesPlayed': analytics['notesPlayed'] ?? 0,
      });
      
      // Update user statistics
      await _incrementUserStat('sessionsPlayed');
      await _incrementUserStat('totalPlayTime', analytics['duration'] ?? 0);
    } catch (e) {
      print('End session error: $e');
    }
  }
  
  // STORAGE METHODS
  
  /// Upload audio recording
  Future<String?> uploadRecording(String filePath, String fileName) async {
    // Add this check for kIsWeb
    if (kIsWeb) {
      print('Warning: File uploading is not supported on the web in this version.');
      return null;
    }
    try {
      if (_auth.currentUser == null) return null;
      
      final ref = _storage
          .ref()
          .child('recordings')
          .child(_auth.currentUser!.uid)
          .child(fileName);
      
      final uploadTask = ref.putData(
        Uint8List.fromList(await _readFileAsBytes(filePath)),
        SettableMetadata(contentType: 'audio/wav'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Upload recording error: $e');
      return null;
    }
  }
  
  // ANALYTICS METHODS
  
  /// Track custom event
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      // Use Firebase Analytics here if needed
      await _firestore.collection('analytics').add({
        'event': eventName,
        'parameters': parameters,
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Track event error: $e');
    }
  }
  
  // HELPER METHODS
  
  /// Increment user statistic
  Future<void> _incrementUserStat(String stat, [int amount = 1]) async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'statistics.$stat': FieldValue.increment(amount)});
    }
  }
  
  /// Read file as bytes
  Future<List<int>> _readFileAsBytes(String filePath) async {
    if (kIsWeb) {
      // Direct file system access by path is not standard/secure for web clients.
      // File data should typically be obtained via input elements (e.g., FileUploadInputElement)
      // or drag-and-drop, which provide byte data directly.
      print('Warning: _readFileAsBytes called on web. This requires a different approach for file handling.');
      throw UnsupportedError(
          'Direct file path reading is not supported on web. Use FilePicker or similar to get bytes.');
    } else {
      // For mobile/desktop, use dart:io
      try {
        final file = File(filePath); // Requires dart:io import
        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          throw Exception('File not found at path: $filePath');
        }
      } catch (e) {
        print('Error reading file: $e');
        rethrow; // Or handle more gracefully
      }
    }
  }
}

/// Preset model for Firestore integration
class Preset {
  final String id;
  final String name;
  final String description;
  final SynthParameters parameters;
  final String userId;
  final bool isPublic;
  final List<String> tags;
  final int likes;
  final int downloads;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Preset({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
    required this.userId,
    required this.isPublic,
    required this.tags,
    required this.likes,
    required this.downloads,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Preset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Preset(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parameters: SynthParameters.fromJson(data['parameters'] ?? {}),
      userId: data['userId'] ?? '',
      isPublic: data['isPublic'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      likes: data['likes'] ?? 0,
      downloads: data['downloads'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parameters': parameters.toJson(),
      'userId': userId,
      'isPublic': isPublic,
      'tags': tags,
      'likes': likes,
      'downloads': downloads,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}