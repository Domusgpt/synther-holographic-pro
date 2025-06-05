# Synther Professional Holographic - API Reference

## 🔌 Core APIs

### Audio Engine API

#### AudioEngine Class
Main interface for audio synthesis and control.

```dart
class AudioEngine extends ChangeNotifier {
  Future<void> init() async
  void noteOn(int midiNote, int velocity)
  void noteOff(int midiNote)
  void setParameter(String parameter, double value)
  void dispose()
}
```

**Methods:**

##### `init()`
Initializes the Web Audio API context and creates the synthesis chain.
- **Returns**: `Future<void>`
- **Throws**: `AudioEngineException` if initialization fails

##### `noteOn(int midiNote, int velocity)`
Triggers a note with specified MIDI note number and velocity.
- **Parameters**:
  - `midiNote` (int): MIDI note number (0-127)
  - `velocity` (int): Note velocity (0-127)
- **Example**: `audioEngine.noteOn(60, 100)` // Middle C at forte

##### `noteOff(int midiNote)`
Releases a note with specified MIDI note number.
- **Parameters**:
  - `midiNote` (int): MIDI note number to release
- **Example**: `audioEngine.noteOff(60)` // Release Middle C

##### `setParameter(String parameter, double value)`
Updates a synthesis parameter in real-time.
- **Parameters**:
  - `parameter` (String): Parameter name (see Parameter Reference)
  - `value` (double): Normalized value (0.0 - 1.0)
- **Example**: `audioEngine.setParameter('filterCutoff', 0.7)`

### Synthesis Parameters API

#### SynthParametersModel Class
State management for all synthesis parameters with real-time updates.

```dart
class SynthParametersModel extends ChangeNotifier {
  // Filter Parameters
  double get filterCutoff
  double get filterResonance
  void setFilterCutoff(double value)
  void setFilterResonance(double value)
  
  // Envelope Parameters
  double get attackTime
  double get releaseTime
  void setAttackTime(double value)
  void setReleaseTime(double value)
  
  // Effects Parameters
  double get reverbMix
  double get masterVolume
  void setReverbMix(double value)
  void setMasterVolume(double value)
  
  // XY Pad Parameters
  void setXYPad(double x, double y)
  
  // Preset Management
  void loadParameters(SynthParameters parameters)
  SynthParameters getCurrentParameters()
}
```

**Parameter Ranges:**

| Parameter | Range | Unit | Description |
|-----------|-------|------|-------------|
| `filterCutoff` | 0.0 - 1.0 | Normalized | Maps to 20Hz - 20kHz |
| `filterResonance` | 0.0 - 1.0 | Normalized | Filter resonance/Q |
| `attackTime` | 0.0 - 1.0 | Normalized | Maps to 0ms - 5000ms |
| `releaseTime` | 0.0 - 1.0 | Normalized | Maps to 0ms - 5000ms |
| `reverbMix` | 0.0 - 1.0 | Normalized | Dry/wet mix |
| `masterVolume` | 0.0 - 1.0 | Normalized | Output level |

### Firebase Service API

#### FirebaseService Class
Handles all Firebase integrations including AI preset generation.

```dart
class FirebaseService {
  static FirebaseService get instance
  
  Future<void> initialize()
  Future<SynthParameters?> generateAIPreset(String description)
  Future<String?> savePreset({
    required String name,
    required String description,
    required SynthParameters parameters,
    bool isPublic = false,
    List<String> tags = const [],
  })
  Future<List<PresetModel>> loadUserPresets()
  Future<List<PresetModel>> loadPublicPresets()
  Future<void> deletePreset(String presetId)
}
```

**Methods:**

##### `generateAIPreset(String description)`
Generates synthesis parameters using AI based on text description.
- **Parameters**:
  - `description` (String): Natural language description of desired sound
- **Returns**: `Future<SynthParameters?>` - Generated parameters or null if failed
- **Example**:
```dart
final params = await firebaseService.generateAIPreset("warm analog bass with slow attack");
if (params != null) {
  synthModel.loadParameters(params);
}
```

##### `savePreset(...)`
Saves a preset to Firestore with metadata.
- **Returns**: `Future<String?>` - Preset ID if successful
- **Example**:
```dart
final presetId = await firebaseService.savePreset(
  name: "My Bass Sound",
  description: "Deep bass with filter sweep",
  parameters: synthModel.getCurrentParameters(),
  isPublic: false,
  tags: ["bass", "filter"],
);
```

## 🎨 UI Component APIs

### Holographic Theme API

#### HolographicTheme Class
Provides consistent styling and effects for the holographic interface.

```dart
class HolographicTheme {
  static const Color primaryEnergy = Color(0xFF00FFFF);
  static const Color secondaryEnergy = Color(0xFFFF00FF);
  static const Color tertiaryEnergy = Color(0xFFFFFF00);
  
  static List<BoxShadow> createEnergyGlow({
    required Color color,
    double intensity = 1.0,
  })
  
  static BoxDecoration createEnergyBorder({
    required Color color,
    double borderWidth = 2.0,
    double glowIntensity = 0.6,
  })
}
```

**Theme Colors:**
- `primaryEnergy`: Cyan (#00FFFF) - Main accent color
- `secondaryEnergy`: Magenta (#FF00FF) - Secondary accent
- `tertiaryEnergy`: Yellow (#FFFF00) - Tertiary accent

### Interactive Components API

#### Draggable Panel System
All UI panels support dragging, resizing, and collapsing.

```dart
Widget buildDraggablePanel({
  required Offset position,
  required Size size,
  required bool isCollapsed,
  required String title,
  required Function(Offset) onPositionChanged,
  required Function(Size) onSizeChanged,
  required Function(bool) onCollapsedChanged,
  required Widget child,
})
```

**Panel State Management:**
- Position: `Offset` coordinates for panel placement
- Size: `Size` dimensions (width, height)
- Collapsed: `bool` for minimize/maximize state

#### XY Control Pad
Touch-responsive 2D control surface.

```dart
class InteractiveXYPainter extends CustomPainter {
  InteractiveXYPainter(this.x, this.y);
  
  @override
  void paint(Canvas canvas, Size size)
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate)
}
```

**Gesture Handling:**
- `onPanUpdate`: Continuous touch movement
- `onTapDown`: Initial touch contact
- Coordinate mapping: Screen space → Normalized (0.0-1.0)

#### Interactive Knobs
Rotary controls with visual feedback.

```dart
class InteractiveKnobPainter extends CustomPainter {
  InteractiveKnobPainter(this.value, this.color);
  
  // Visual elements:
  // - Background arc (low opacity)
  // - Value arc (full opacity, 270° sweep)
  // - Indicator dot (position based on value)
}
```

## 🌐 Cloud Functions API

### generatePreset Function
Firebase Cloud Function for AI-powered preset generation.

**Endpoint**: `https://region-project.cloudfunctions.net/generatePreset`

**Request Format:**
```typescript
{
  description: string;
  userId?: string;
  options?: {
    style?: 'electronic' | 'organic' | 'aggressive' | 'ambient';
    complexity?: 'simple' | 'moderate' | 'complex';
    tempo?: number; // BPM hint for time-based effects
  }
}
```

**Response Format:**
```typescript
{
  success: boolean;
  parameters?: SynthParameters;
  error?: string;
  metadata?: {
    generationTime: number;
    tokensUsed: number;
    confidence: number;
  }
}
```

**SynthParameters Schema:**
```typescript
interface SynthParameters {
  filterCutoff: number;      // 0.0 - 1.0
  filterResonance: number;   // 0.0 - 1.0
  attackTime: number;        // 0.0 - 1.0
  releaseTime: number;       // 0.0 - 1.0
  reverbMix: number;         // 0.0 - 1.0
  masterVolume: number;      // 0.0 - 1.0
  xyPadX?: number;          // 0.0 - 1.0 (optional)
  xyPadY?: number;          // 0.0 - 1.0 (optional)
}
```

## 🎬 Visualizer Bridge API

### VisualizerBridgeWidget
Connects Flutter UI parameters to HyperAV visualizer.

```dart
class VisualizerBridgeWidget extends StatefulWidget {
  const VisualizerBridgeWidget({
    Key? key,
    this.opacity = 1.0,
    this.showControls = false,
  }) : super(key: key);
  
  final double opacity;
  final bool showControls;
}
```

**JavaScript Bridge Methods:**
```javascript
// Called from Flutter to update visualizer
window.updateVisualizerParams = function(params) {
  // params: { filterCutoff, filterResonance, xyX, xyY, ... }
  hypercube.setParameters(params);
}

// Called from visualizer to notify Flutter
window.notifyFlutter = function(event, data) {
  // event: 'parameterChanged', 'visualizerReady', etc.
  flutterChannel.postMessage({ event, data });
}
```

### HyperAV Engine Parameters
Parameters that affect 4D visualizations:

| Flutter Parameter | Visualizer Effect | Range |
|------------------|------------------|-------|
| `filterCutoff` | Hypercube rotation speed | 0.0 - 1.0 |
| `filterResonance` | Geometry complexity | 0.0 - 1.0 |
| `xyPadX` | X-axis rotation | 0.0 - 1.0 |
| `xyPadY` | Y-axis rotation | 0.0 - 1.0 |
| `reverbMix` | Particle density | 0.0 - 1.0 |
| `masterVolume` | Overall scale | 0.0 - 1.0 |

## 📱 Platform-Specific APIs

### Web Platform
```dart
// Web Audio API integration
import 'dart:html' as html;
import 'dart:js' as js;

// Initialize audio context
final audioContext = html.AudioContext();

// Create synthesis nodes
final oscillator = audioContext.createOscillator();
final gainNode = audioContext.createGain();
final filterNode = audioContext.createBiquadFilter();
```

### Android Platform
```kotlin
// MainActivity.kt - Platform channel setup
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "audio_engine")
            .setMethodCallHandler { call, result ->
                // Handle native audio calls
            }
    }
}
```

### iOS Platform
```swift
// AppDelegate.swift - Audio session configuration
import AVFoundation

func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playback, mode: .default)
    try? audioSession.setActive(true)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

## 🔧 Development APIs

### Debug & Testing
```dart
// Enable debug logging
void enableDebugLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

// Performance monitoring
class PerformanceMonitor {
  static void startTimer(String operation)
  static void endTimer(String operation)
  static void logFrameRate()
  static void logMemoryUsage()
}
```

### Error Handling
```dart
// Custom exceptions
class AudioEngineException implements Exception {
  final String message;
  AudioEngineException(this.message);
}

class FirebaseServiceException implements Exception {
  final String message;
  final String? code;
  FirebaseServiceException(this.message, [this.code]);
}

// Global error handler
void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
}
```

## 📊 Usage Examples

### Basic Synthesis Setup
```dart
void main() async {
  // Initialize services
  await Firebase.initializeApp();
  await FirebaseService.instance.initialize();
  
  // Create audio engine
  final audioEngine = createAudioEngine();
  await audioEngine.init();
  
  // Setup parameter model
  final synthParameters = SynthParametersModel();
  
  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: audioEngine),
        ChangeNotifierProvider.value(value: synthParameters),
        Provider.value(value: FirebaseService.instance),
      ],
      child: SyntherApp(),
    ),
  );
}
```

### AI Preset Generation
```dart
Future<void> generateAndApplyPreset() async {
  final firebaseService = FirebaseService.instance;
  final synthModel = Provider.of<SynthParametersModel>(context, listen: false);
  
  try {
    final params = await firebaseService.generateAIPreset(
      "warm analog bass with slow attack and filter sweep"
    );
    
    if (params != null) {
      synthModel.loadParameters(params);
      
      // Optionally save the preset
      await firebaseService.savePreset(
        name: "AI Generated Bass",
        description: "Generated from user description",
        parameters: params,
        tags: ["ai-generated", "bass"],
      );
    }
  } catch (e) {
    print('Failed to generate preset: $e');
  }
}
```

### Custom UI Component
```dart
class CustomHolographicButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HolographicTheme.createEnergyBorder(
        color: HolographicTheme.primaryEnergy,
        borderWidth: 2.0,
        glowIntensity: 0.8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                shadows: [
                  Shadow(
                    color: HolographicTheme.primaryEnergy,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

This API reference provides comprehensive documentation for all major components and systems in the Synther Professional Holographic application.