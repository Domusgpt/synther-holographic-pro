import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// Professional Holographic Theme System
/// 
/// Provides comprehensive glassmorphism and holographic UI theming:
/// - Translucent backgrounds with blur effects
/// - Chromatic aberration text and icons
/// - Depth-based lighting and shadows
/// - Audio-reactive color schemes
/// - Professional glassmorphism components
/// - Performance-optimized blur and transparency

/// Holographic color schemes for different moods/synthesis types
enum HolographicColorScheme {
  deepSpace,     // Deep blues and purples
  crystalline,   // Clear blues and whites  
  neonCyber,     // Bright cyans and magentas
  warmAnalog,    // Warm oranges and yellows
  spectral,      // Rainbow spectrum
  minimal,       // Monochrome with subtle colors
}

/// Glass morphism effect configuration
class GlassmorphismConfig {
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderWidth;
  final Color tintColor;
  final Color borderColor;
  final double saturation;
  final double brightness;
  final bool enableNoise;
  final double noiseIntensity;
  
  const GlassmorphismConfig({
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderOpacity = 0.2,
    this.borderWidth = 1.0,
    this.tintColor = const Color(0xFF00FFFF),
    this.borderColor = const Color(0xFF00FFFF),
    this.saturation = 1.2,
    this.brightness = 1.1,
    this.enableNoise = true,
    this.noiseIntensity = 0.02,
  });
  
  GlassmorphismConfig copyWith({
    double? blur,
    double? opacity,
    double? borderOpacity,
    double? borderWidth,
    Color? tintColor,
    Color? borderColor,
    double? saturation,
    double? brightness,
    bool? enableNoise,
    double? noiseIntensity,
  }) {
    return GlassmorphismConfig(
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderWidth: borderWidth ?? this.borderWidth,
      tintColor: tintColor ?? this.tintColor,
      borderColor: borderColor ?? this.borderColor,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      enableNoise: enableNoise ?? this.enableNoise,
      noiseIntensity: noiseIntensity ?? this.noiseIntensity,
    );
  }
}

/// Chromatic aberration effect configuration
class ChromaticAberrationConfig {
  final double intensity;
  final double redOffset;
  final double greenOffset;
  final double blueOffset;
  final bool enableDistortion;
  final double distortionAmount;
  
  const ChromaticAberrationConfig({
    this.intensity = 0.5,
    this.redOffset = 1.0,
    this.greenOffset = 0.0,
    this.blueOffset = -1.0,
    this.enableDistortion = false,
    this.distortionAmount = 0.1,
  });
}

/// Professional holographic theme data
class HolographicThemeData {
  final HolographicColorScheme colorScheme;
  final GlassmorphismConfig glassmorphism;
  final ChromaticAberrationConfig chromaticAberration;
  
  // Color palette
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color glowColor;
  final Color shadowColor;
  
  // Typography
  final TextStyle headlineStyle;
  final TextStyle bodyStyle;
  final TextStyle captionStyle;
  final TextStyle buttonStyle;
  
  // Spacing and sizing
  final double baseUnit;
  final double borderRadius;
  final EdgeInsets defaultPadding;
  final double elevation;
  
  // Animation durations
  final Duration shortAnimation;
  final Duration mediumAnimation;
  final Duration longAnimation;
  
  // Audio reactivity
  final bool enableAudioReactivity;
  final double audioSensitivity;
  
  const HolographicThemeData({
    this.colorScheme = HolographicColorScheme.deepSpace,
    this.glassmorphism = const GlassmorphismConfig(),
    this.chromaticAberration = const ChromaticAberrationConfig(),
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.glowColor,
    required this.shadowColor,
    required this.headlineStyle,
    required this.bodyStyle,
    required this.captionStyle,
    required this.buttonStyle,
    this.baseUnit = 8.0,
    this.borderRadius = 12.0,
    this.defaultPadding = const EdgeInsets.all(16.0),
    this.elevation = 8.0,
    this.shortAnimation = const Duration(milliseconds: 150),
    this.mediumAnimation = const Duration(milliseconds: 300),
    this.longAnimation = const Duration(milliseconds: 600),
    this.enableAudioReactivity = true,
    this.audioSensitivity = 0.7,
  });
  
  /// Create theme from color scheme
  factory HolographicThemeData.fromColorScheme(HolographicColorScheme scheme) {
    switch (scheme) {
      case HolographicColorScheme.deepSpace:
        return _createDeepSpaceTheme();
      case HolographicColorScheme.crystalline:
        return _createCrystallineTheme();
      case HolographicColorScheme.neonCyber:
        return _createNeonCyberTheme();
      case HolographicColorScheme.warmAnalog:
        return _createWarmAnalogTheme();
      case HolographicColorScheme.spectral:
        return _createSpectralTheme();
      case HolographicColorScheme.minimal:
        return _createMinimalTheme();
    }
  }
  
  static HolographicThemeData _createDeepSpaceTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.deepSpace,
      primaryColor: const Color(0xFF00FFFF),      // Cyan
      secondaryColor: const Color(0xFF8000FF),    // Purple
      accentColor: const Color(0xFF00FF80),       // Green-cyan
      backgroundColor: const Color(0xFF000011),   // Deep space black
      surfaceColor: const Color(0xFF0A0A2A),      // Dark purple-blue
      onSurfaceColor: const Color(0xFFE0E0FF),    // Light blue-white
      glowColor: const Color(0xFF00FFFF),         // Cyan glow
      shadowColor: const Color(0xFF000080),      // Deep blue shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 15.0,
        opacity: 0.1,
        tintColor: Color(0xFF002040),
        borderColor: Color(0xFF00FFFF),
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        color: Color(0xFFFFFFFF),
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: Color(0xFF00FFFF), blurRadius: 8.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0E0FF),
        letterSpacing: 0.5,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Color(0xFFB0B0FF),
        letterSpacing: 0.3,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFFFFFFF),
        letterSpacing: 1.0,
      ),
    );
  }
  
  static HolographicThemeData _createCrystallineTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.crystalline,
      primaryColor: const Color(0xFFFFFFFF),      // Pure white
      secondaryColor: const Color(0xFF80C0FF),    // Light blue
      accentColor: const Color(0xFF00E0FF),       // Bright cyan
      backgroundColor: const Color(0xFF0A0A0A),   // Nearly black
      surfaceColor: const Color(0xFF1A1A2A),      // Dark blue-gray
      onSurfaceColor: const Color(0xFFFFFFFF),    // Pure white
      glowColor: const Color(0xFFFFFFFF),         // White glow
      shadowColor: const Color(0xFF000040),      // Dark blue shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 20.0,
        opacity: 0.05,
        tintColor: Color(0xFF404080),
        borderColor: Color(0xFFFFFFFF),
        borderOpacity: 0.3,
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w200,
        color: Color(0xFFFFFFFF),
        letterSpacing: 2.0,
        shadows: [
          Shadow(color: Color(0xFFFFFFFF), blurRadius: 12.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: Color(0xFFF0F0FF),
        letterSpacing: 0.8,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w200,
        color: Color(0xFFD0D0FF),
        letterSpacing: 0.5,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFFFFFF),
        letterSpacing: 1.2,
      ),
    );
  }
  
  static HolographicThemeData _createNeonCyberTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.neonCyber,
      primaryColor: const Color(0xFFFF0080),      // Hot pink
      secondaryColor: const Color(0xFF00FFFF),    // Cyan
      accentColor: const Color(0xFF80FF00),       // Bright green
      backgroundColor: const Color(0xFF000000),   // Pure black
      surfaceColor: const Color(0xFF200020),      // Dark magenta
      onSurfaceColor: const Color(0xFFFFFFFF),    // White
      glowColor: const Color(0xFFFF0080),         // Pink glow
      shadowColor: const Color(0xFF800040),      // Dark pink shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 12.0,
        opacity: 0.15,
        tintColor: Color(0xFF400040),
        borderColor: Color(0xFFFF0080),
        saturation: 1.5,
        brightness: 1.2,
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFF0080),
        letterSpacing: 1.8,
        shadows: [
          Shadow(color: Color(0xFFFF0080), blurRadius: 10.0),
          Shadow(color: Color(0xFF00FFFF), blurRadius: 15.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFFFFFF),
        letterSpacing: 0.6,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Color(0xFFFF80C0),
        letterSpacing: 0.4,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFFFFFF),
        letterSpacing: 1.1,
      ),
    );
  }
  
  static HolographicThemeData _createWarmAnalogTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.warmAnalog,
      primaryColor: const Color(0xFFFF8000),      // Orange
      secondaryColor: const Color(0xFFFFFF00),    // Yellow
      accentColor: const Color(0xFFFF4000),       // Red-orange
      backgroundColor: const Color(0xFF0A0500),   // Very dark brown
      surfaceColor: const Color(0xFF2A1A0A),      // Dark brown
      onSurfaceColor: const Color(0xFFFFE0C0),    // Warm white
      glowColor: const Color(0xFFFF8000),         // Orange glow
      shadowColor: const Color(0xFF402000),      // Dark brown shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 8.0,
        opacity: 0.12,
        tintColor: Color(0xFF402010),
        borderColor: Color(0xFFFF8000),
        saturation: 1.3,
        brightness: 1.1,
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFFE0C0),
        letterSpacing: 1.2,
        shadows: [
          Shadow(color: Color(0xFFFF8000), blurRadius: 6.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFFD0A0),
        letterSpacing: 0.4,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Color(0xFFFFB080),
        letterSpacing: 0.2,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFFFFFFF),
        letterSpacing: 0.8,
      ),
    );
  }
  
  static HolographicThemeData _createSpectralTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.spectral,
      primaryColor: const Color(0xFFFF0080),      // Magenta
      secondaryColor: const Color(0xFF00FF80),    // Spring green
      accentColor: const Color(0xFF8000FF),       // Purple
      backgroundColor: const Color(0xFF000000),   // Black
      surfaceColor: const Color(0xFF0A0A0A),      // Very dark gray
      onSurfaceColor: const Color(0xFFFFFFFF),    // White
      glowColor: const Color(0xFFFFFFFF),         // White glow
      shadowColor: const Color(0xFF404040),      // Dark gray shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 16.0,
        opacity: 0.08,
        tintColor: Color(0xFF202020),
        borderColor: Color(0xFFFFFFFF),
        saturation: 2.0,
        brightness: 1.3,
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        color: Color(0xFFFFFFFF),
        letterSpacing: 2.5,
        shadows: [
          Shadow(color: Color(0xFFFF0080), blurRadius: 8.0),
          Shadow(color: Color(0xFF00FF80), blurRadius: 12.0),
          Shadow(color: Color(0xFF8000FF), blurRadius: 16.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: Color(0xFFF0F0F0),
        letterSpacing: 0.7,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w200,
        color: Color(0xFFE0E0E0),
        letterSpacing: 0.5,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFFFFFF),
        letterSpacing: 1.5,
      ),
    );
  }
  
  static HolographicThemeData _createMinimalTheme() {
    return HolographicThemeData(
      colorScheme: HolographicColorScheme.minimal,
      primaryColor: const Color(0xFFFFFFFF),      // White
      secondaryColor: const Color(0xFFA0A0A0),    // Light gray
      accentColor: const Color(0xFF606060),       // Medium gray
      backgroundColor: const Color(0xFF000000),   // Black
      surfaceColor: const Color(0xFF101010),      // Very dark gray
      onSurfaceColor: const Color(0xFFFFFFFF),    // White
      glowColor: const Color(0xFFFFFFFF),         // White glow
      shadowColor: const Color(0xFF202020),      // Dark gray shadow
      glassmorphism: const GlassmorphismConfig(
        blur: 6.0,
        opacity: 0.05,
        tintColor: Color(0xFF404040),
        borderColor: Color(0xFFFFFFFF),
        borderOpacity: 0.1,
        saturation: 0.8,
        brightness: 1.0,
      ),
      headlineStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w200,
        color: Color(0xFFFFFFFF),
        letterSpacing: 3.0,
        shadows: [
          Shadow(color: Color(0xFFFFFFFF), blurRadius: 4.0),
        ],
      ),
      bodyStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: Color(0xFFE0E0E0),
        letterSpacing: 1.0,
      ),
      captionStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w200,
        color: Color(0xFFA0A0A0),
        letterSpacing: 0.8,
      ),
      buttonStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: Color(0xFFFFFFFF),
        letterSpacing: 2.0,
      ),
    );
  }
}

/// Inherited widget for holographic theme
class HolographicTheme extends InheritedWidget {
  final HolographicThemeData data;
  
  const HolographicTheme({
    super.key,
    required this.data,
    required super.child,
  });
  
  static HolographicThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<HolographicTheme>();
    return theme?.data ?? HolographicThemeData.fromColorScheme(HolographicColorScheme.deepSpace);
  }
  
  @override
  bool updateShouldNotify(HolographicTheme oldWidget) {
    return data != oldWidget.data;
  }
}

/// Audio-reactive theme controller
class AudioReactiveThemeController extends ChangeNotifier {
  HolographicThemeData _baseTheme;
  HolographicThemeData _currentTheme;
  
  // Audio parameters
  double _amplitude = 0.0;
  double _frequency = 440.0;
  double _spectralCentroid = 0.5;
  double _harmonicContent = 0.5;
  
  AudioReactiveThemeController(this._baseTheme) : _currentTheme = _baseTheme;
  
  HolographicThemeData get currentTheme => _currentTheme;
  
  /// Update theme based on audio parameters
  void updateFromAudio({
    required double amplitude,
    required double frequency,
    required double spectralCentroid,
    required double harmonicContent,
  }) {
    if (!_baseTheme.enableAudioReactivity) return;
    
    _amplitude = amplitude;
    _frequency = frequency;
    _spectralCentroid = spectralCentroid;
    _harmonicContent = harmonicContent;
    
    // Calculate audio-reactive modifications
    final sensitivity = _baseTheme.audioSensitivity;
    
    // Modify glassmorphism based on amplitude
    final glassConfig = _baseTheme.glassmorphism.copyWith(
      blur: _baseTheme.glassmorphism.blur * (1.0 + amplitude * sensitivity * 0.5),
      opacity: _baseTheme.glassmorphism.opacity * (1.0 + amplitude * sensitivity * 0.3),
      saturation: _baseTheme.glassmorphism.saturation * (1.0 + spectralCentroid * sensitivity * 0.2),
      brightness: _baseTheme.glassmorphism.brightness * (1.0 + harmonicContent * sensitivity * 0.1),
    );
    
    // Modify colors based on frequency
    final frequencyNorm = math.log(frequency / 440.0) / math.log(2.0); // Octaves from A4
    final hueShift = frequencyNorm * sensitivity * 30.0; // Degrees
    
    final primaryHSV = HSVColor.fromColor(_baseTheme.primaryColor);
    final modifiedPrimary = primaryHSV.withHue((primaryHSV.hue + hueShift) % 360.0).toColor();
    
    final glowHSV = HSVColor.fromColor(_baseTheme.glowColor);
    final modifiedGlow = glowHSV.withHue((glowHSV.hue + hueShift) % 360.0).toColor();
    
    // Create updated theme
    _currentTheme = HolographicThemeData(
      colorScheme: _baseTheme.colorScheme,
      glassmorphism: glassConfig,
      chromaticAberration: _baseTheme.chromaticAberration,
      primaryColor: modifiedPrimary,
      secondaryColor: _baseTheme.secondaryColor,
      accentColor: _baseTheme.accentColor,
      backgroundColor: _baseTheme.backgroundColor,
      surfaceColor: _baseTheme.surfaceColor,
      onSurfaceColor: _baseTheme.onSurfaceColor,
      glowColor: modifiedGlow,
      shadowColor: _baseTheme.shadowColor,
      headlineStyle: _baseTheme.headlineStyle.copyWith(
        shadows: [
          Shadow(
            color: modifiedGlow,
            blurRadius: 8.0 * (1.0 + amplitude * sensitivity),
          ),
        ],
      ),
      bodyStyle: _baseTheme.bodyStyle,
      captionStyle: _baseTheme.captionStyle,
      buttonStyle: _baseTheme.buttonStyle,
      baseUnit: _baseTheme.baseUnit,
      borderRadius: _baseTheme.borderRadius,
      defaultPadding: _baseTheme.defaultPadding,
      elevation: _baseTheme.elevation,
      shortAnimation: _baseTheme.shortAnimation,
      mediumAnimation: _baseTheme.mediumAnimation,
      longAnimation: _baseTheme.longAnimation,
      enableAudioReactivity: _baseTheme.enableAudioReactivity,
      audioSensitivity: _baseTheme.audioSensitivity,
    );
    
    notifyListeners();
  }
  
  /// Set base theme
  void setBaseTheme(HolographicThemeData theme) {
    _baseTheme = theme;
    _currentTheme = theme;
    notifyListeners();
  }
}

/// Utility functions for color manipulation
class HolographicColorUtils {
  /// Apply chromatic aberration effect to text
  static List<Shadow> createChromaticAberrationShadows(
    Color baseColor, 
    ChromaticAberrationConfig config,
  ) {
    if (config.intensity <= 0) return [];
    
    final shadows = <Shadow>[];
    
    // Red channel offset
    shadows.add(Shadow(
      color: Color.fromARGB(
        (baseColor.alpha * config.intensity).round(),
        baseColor.red,
        0,
        0,
      ),
      offset: Offset(config.redOffset * config.intensity, 0),
      blurRadius: 1.0,
    ));
    
    // Green channel (usually no offset)
    shadows.add(Shadow(
      color: Color.fromARGB(
        (baseColor.alpha * config.intensity).round(),
        0,
        baseColor.green,
        0,
      ),
      offset: Offset(config.greenOffset * config.intensity, 0),
      blurRadius: 1.0,
    ));
    
    // Blue channel offset
    shadows.add(Shadow(
      color: Color.fromARGB(
        (baseColor.alpha * config.intensity).round(),
        0,
        0,
        baseColor.blue,
      ),
      offset: Offset(config.blueOffset * config.intensity, 0),
      blurRadius: 1.0,
    ));
    
    return shadows;
  }
  
  /// Create gradient with holographic effect
  static LinearGradient createHolographicGradient(
    List<Color> colors, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double saturationBoost = 1.2,
  }) {
    final boostedColors = colors.map((color) {
      final hsv = HSVColor.fromColor(color);
      return hsv.withSaturation(
        (hsv.saturation * saturationBoost).clamp(0.0, 1.0)
      ).toColor();
    }).toList();
    
    return LinearGradient(
      begin: begin,
      end: end,
      colors: boostedColors,
    );
  }
  
  /// Interpolate between colors with spectral mixing
  static Color spectralLerp(Color a, Color b, double t) {
    // Convert to HSV for better color interpolation
    final hsvA = HSVColor.fromColor(a);
    final hsvB = HSVColor.fromColor(b);
    
    // Handle hue interpolation (shortest path)
    double hue;
    final hueDiff = (hsvB.hue - hsvA.hue).abs();
    if (hueDiff > 180) {
      // Go the shorter way around the color wheel
      if (hsvA.hue > hsvB.hue) {
        hue = ui.lerpDouble(hsvA.hue, hsvB.hue + 360, t)! % 360;
      } else {
        hue = ui.lerpDouble(hsvA.hue + 360, hsvB.hue, t)! % 360;
      }
    } else {
      hue = ui.lerpDouble(hsvA.hue, hsvB.hue, t)!;
    }
    
    return HSVColor.fromAHSV(
      ui.lerpDouble(hsvA.alpha, hsvB.alpha, t)!,
      hue,
      ui.lerpDouble(hsvA.saturation, hsvB.saturation, t)!,
      ui.lerpDouble(hsvA.value, hsvB.value, t)!,
    ).toColor();
  }
}