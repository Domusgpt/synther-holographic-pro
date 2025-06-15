// Embedded HyperAV Visualizer - Platform-agnostic interface with conditional imports
// 
// This file provides a unified interface to the embedded 4D visualizer widget
// that works across all platforms by using conditional imports.
//
// On web: Creates iframe and communicates with JavaScript visualizer
// On mobile: Shows informational message since visualizer is web-only

// Conditional imports - the correct way to handle platform-specific widgets
import 'embedded_hyperav_visualizer_interface.dart'
    if (dart.library.html) 'embedded_hyperav_visualizer_web.dart'
    if (dart.library.io) 'embedded_hyperav_visualizer_mobile.dart';

// Export the actual widget
export 'embedded_hyperav_visualizer_interface.dart'
    if (dart.library.html) 'embedded_hyperav_visualizer_web.dart'
    if (dart.library.io) 'embedded_hyperav_visualizer_mobile.dart';