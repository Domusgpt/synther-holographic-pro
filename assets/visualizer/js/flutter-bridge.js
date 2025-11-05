/**
 * Flutter Bridge Integration for HyperAV Visualizer
 * This file provides the communication bridge between Flutter and the visualizer
 */

// Define parameter map globally for access by multiple functions
const _parameterMap = {
    // Audio synthesis parameters
    'filterCutoff': { target: 'dimension', scale: (v) => 3 + v * 2 }, // Flutter's 0-1 filter cutoff maps to visual 'dimension' (e.g., 3D to 5D effect strength).
    'filterResonance': { target: 'rotationSpeed', scale: (v) => v * 2 }, // Filter resonance (0-1) controls visual rotation speed (0-2 arbitrary units).
    'reverbMix': { target: 'glitchIntensity', scale: (v) => v * 0.1 }, // Reverb mix (0-1) translates to a subtle glitch intensity (0-0.1).
    'masterVolume': { target: 'patternIntensity', scale: (v) => 0.5 + v * 1.5 }, // Master volume (0-1) scales overall visual pattern intensity (0.5-2.0).

    // XY Pad direct control (assumed to be 0-1 from Flutter)
    'rotationX': { target: 'rotationX', scale: (v) => v * 360 }, // Direct mapping to degrees.
    'rotationY': { target: 'rotationY', scale: (v) => v * 360 }, // Direct mapping to degrees.

    // Envelope parameters
    'attackTime': { target: 'morphFactor', scale: (v) => v * 1.5 }, // Synth attack time (0-1, short to long) influences the morphing factor of visuals (0-1.5).
    'releaseTime': { target: 'lineThickness', scale: (v) => 0.01 + v * 0.09 }, // Synth release time (0-1) affects visual line thickness (0.01-0.1).

    // Oscillator parameters
    'waveformType': { target: 'colorShift', scale: (v) => v / 5 }, // Oscillator waveform type (e.g., enum index 0-5 from Flutter) shifts base colors (0-1 range for shader).
    'oscillatorVolume': { target: 'universeModifier', scale: (v) => 0.5 + v * 1.5 }, // Oscillator volume (0-1) modifies a 'universe' visual parameter (0.5-2.0).
    'oscillatorFrequency': { target: 'pulseSpeed', scale: (v) => v * 2.0}, // Normalized frequency (0-1 from Flutter) affects pulsing speed of some elements.

    // NEW: 7-band levels for LayerManager (Phase 2)
    'band0': { target: '_band0', scale: (v) => v }, //Sub Bass
    'band1': { target: '_band1', scale: (v) => v }, // Bass
    'band2': { target: '_band2', scale: (v) => v }, // Low Mids
    'band3': { target: '_band3', scale: (v) => v }, // Mids
    'band4': { target: '_band4', scale: (v) => v }, // High Mids
    'band5': { target: '_band5', scale: (v) => v }, // Presence
    'band6': { target: '_band6', scale: (v) => v }, // Brilliance

    // NEW Phase 4: Envelope parameter mappings
    'contractionSpeed': { target: 'contractionSpeed', scale: (v) => v }, // Geometry contraction rate (0.1-3.0)
    'stabilityFactor': { target: 'stabilityFactor', scale: (v) => v }, // Jitter/chaos amount (0-1)
    'dissolveFactor': { target: 'dissolveFactor', scale: (v) => v }, // Fade-out opacity (0-1)

    // NEW Phase 6: Effect-specific visual parameters
    'interferenceAmount': { target: 'interferenceAmount', scale: (v) => v }, // Chorus wave intensity (0-1)
    'helixRotationSpeed': { target: 'helixRotationSpeed', scale: (v) => v }, // Phaser spiral rate (0-4)
    'facetSharpness': { target: 'facetSharpness', scale: (v) => v }, // Distortion edge definition (0-1)
    'breathingDepth': { target: 'breathingDepth', scale: (v) => v }, // Compressor scale pulsation (0-1)

    // Direct visual parameter control (for manual/LFO modulation)
    'rotationSpeed': { target: 'rotationSpeed', scale: (v) => v }, // Overall rotation speed
    'morphFactor': { target: 'morphFactor', scale: (v) => v }, // Geometry deformation
    'colorShift': { target: 'colorShift', scale: (v) => v }, // Hue cycling
    'gridDensity': { target: 'gridDensity', scale: (v) => v }, // Point/line density
    'glitchIntensity': { target: 'glitchIntensity', scale: (v) => v }, // Artifact intensity
    'patternIntensity': { target: 'patternIntensity', scale: (v) => v }, // Overall brightness
    'universeModifier': { target: 'universeModifier', scale: (v) => v }, // Scale/echo effect
    'dimension': { target: 'dimension', scale: (v) => v }, // Dimensional shift
    'lineThickness': { target: 'lineThickness', scale: (v) => v }, // Line width
};

// NEW: Store 7-band levels for LayerManager
window._current7BandLevels = [0, 0, 0, 0, 0, 0, 0];

window.visualizerCoreIsReady = false;

// Function to be called by the main visualizer script when its core is ready
window.signalVisualizerCoreReady = function() {
    console.log('Visualizer core signaling ready.');
    window.visualizerCoreIsReady = true;
    initializeFlutterBridge(); // Attempt to initialize bridge now that core is ready
};

// Initialize or re-initialize the Flutter bridge
function initializeFlutterBridge() {
    console.log('Attempting to initialize Flutter bridge...');
    if (!window.visualizerCoreIsReady) {
        console.log('Visualizer core not ready yet. Bridge initialization deferred.');
        return;
    }

    // This function might be kept if Flutter directly calls it via webview's evaluateJavascript.
    // However, for postMessage, direct handling is now in the event listener.
    window.updateVisualizerParameter = function(name, value) {
        if (!window.mainVisualizerCore) {
            console.warn('updateVisualizerParameter: mainVisualizerCore not found!');
            return;
        }
        if (!window.visualParams) {
            console.warn('updateVisualizerParameter: visualParams not found!');
            // return; // Might still want to update core if params object is missing for some reason
        }

        const mapping = _parameterMap[name];
        if (mapping) {
            const scaledValue = mapping.scale(value);

            // NEW: Handle band levels for 5-layer system
            if (name.startsWith('band')) {
                const bandIndex = parseInt(name.substring(4)); // Extract number from 'band0', 'band1', etc.
                if (bandIndex >= 0 && bandIndex < 7) {
                    window._current7BandLevels[bandIndex] = scaledValue;

                    // Update the visualizer core with complete band array
                    if (window.mainVisualizerCore.updateBandLevels) {
                        window.mainVisualizerCore.updateBandLevels(window._current7BandLevels);
                    }
                }
                return; // Band parameters don't go through normal parameter system
            }

            if (window.visualParams) {
                window.visualParams[mapping.target] = scaledValue;
            } else {
                 // If visualParams is missing, at least try to update the core directly
                 console.warn('visualParams object not found, attempting direct core update for:', mapping.target);
            }

            window.mainVisualizerCore.updateParameters({
                [mapping.target]: scaledValue
            });

            if (window.updateSlider) { // For local UI sliders in visualizer page
                window.updateSlider(mapping.target, scaledValue);
            }
        } else {
            console.warn(`updateVisualizerParameter: Parameter name "${name}" not found in parameterMap.`);
        }
    };
    
    // Effect toggle functions for Flutter
    window.toggleVisualizerEffect = function(effect) {
        if (!window.mainVisualizerCore || !window.visualParams) return;
        
        switch(effect) {
            case 'blur':
                window.visualParams.glitchIntensity = window.visualParams.glitchIntensity > 0 ? 0 : 0.05;
                break;
            case 'grid':
                window.visualParams.gridDensity = window.visualParams.gridDensity > 4 ? 2 : 12;
                break;
            case 'trails':
                // Toggle between different pattern intensities for trail effect
                window.visualParams.patternIntensity = window.visualParams.patternIntensity > 1 ? 0.5 : 2;
                break;
        }
        
        window.mainVisualizerCore.updateParameters(window.visualParams);
    };
    
    window.resetVisualizer = function() {
        if (!window.mainVisualizerCore) return;

        // Reset to default values
        window.visualParams = {
            morphFactor: 0.7, dimension: 4.0, rotationSpeed: 0.5, gridDensity: 8.0,
            lineThickness: 0.03, patternIntensity: 1.3, universeModifier: 1.0,
            colorShift: 0.0, glitchIntensity: 0.02,
            shellWidth: 0.025, tetraThickness: 0.035,
            hue: 0.5, saturation: 0.8, brightness: 0.9
        };

        window.mainVisualizerCore.updateParameters(window.visualParams);

        // Update all sliders if function is available
        if (window.updateSlider) {
            for (const key in window.visualParams) {
                window.updateSlider(key, window.visualParams[key]);
            }
        }
    };

    // NEW: Update visualizer configuration (Tiers 1-3: Family, Polytope, Geometry)
    window.updateVisualizerConfiguration = function(configData) {
        if (!window.mainVisualizerCore) {
            console.warn('updateVisualizerConfiguration: mainVisualizerCore not found!');
            return;
        }

        console.log('Updating visualizer configuration:', configData);

        // Update polytope (Tier 2)
        if (configData.polytope) {
            window.mainVisualizerCore.updateParameters({ polytope: configData.polytope });
        }

        // Update geometry type (Tier 3)
        if (configData.geometryType) {
            window.mainVisualizerCore.updateParameters({ geometryType: configData.geometryType });
        }

        // Visualizer family (Tier 1) - Phase 3 implementation
        if (configData.family) {
            console.log(`Visualizer family set to: ${configData.family}`);
            window.mainVisualizerCore.updateParameters({ visualizerFamily: configData.family });
        }
    };
    
    // Set up message listener for iframe communication
    window.addEventListener('message', function(event) {
        // It's good practice to check event.origin for security if the source is known
        // if (event.origin !== 'expected_flutter_app_origin') return;

        if (event.data && typeof event.data === 'object') {
            const { type, parameter, value, effect } = event.data;

            if (type === 'parameterUpdate') {
                if (!window.mainVisualizerCore) {
                    console.warn('EventListener: mainVisualizerCore not found for parameterUpdate!');
                    return;
                }
                if (!window.visualParams) {
                    console.warn('EventListener: visualParams not found for parameterUpdate!');
                    // return; // Decide if critical
                }

                const mapping = _parameterMap[parameter];
                if (mapping) {
                    const scaledValue = mapping.scale(value);
                    if (window.visualParams) {
                        window.visualParams[mapping.target] = scaledValue;
                    }
                     window.mainVisualizerCore.updateParameters({ [mapping.target]: scaledValue });
                    if (window.updateSlider) window.updateSlider(mapping.target, scaledValue);
                } else {
                    console.warn(`EventListener: Parameter name "${parameter}" not found in _parameterMap.`);
                }
            } else if (type === 'toggleEffect') {
                window.toggleVisualizerEffect(effect);
            } else if (type === 'resetVisualizer') {
                window.resetVisualizer();
            } else if (type === 'fftDataUpdate') {
                if (event.data.magnitudes && Array.isArray(event.data.magnitudes)) {
                    window.syntherFftData = event.data.magnitudes;
                    // console.log('flutter-bridge.js: Received fftDataUpdate with ' + event.data.magnitudes.length + ' bins.');
                } else {
                    console.warn('flutter-bridge.js: Received fftDataUpdate without valid magnitudes array.');
                }
            } else if (type === 'showControls') { // Sent by current visualizer_bridge_widget_web.dart
                if (window.setVisualizerControlsVisibility) {
                    window.setVisualizerControlsVisibility(true);
                } else {
                    console.warn('EventListener: window.setVisualizerControlsVisibility not defined in visualizer-main.js');
                }
            } else if (type === 'hideControls') { // Sent by current visualizer_bridge_widget_web.dart
                 if (window.setVisualizerControlsVisibility) {
                    window.setVisualizerControlsVisibility(false);
                } else {
                    console.warn('EventListener: window.setVisualizerControlsVisibility not defined in visualizer-main.js');
                }
            } else if (type === 'configurationUpdate') { // NEW: Handle configuration updates
                window.updateVisualizerConfiguration(event.data);
            }
            // Consider adding a 'setControlsVisibility' with a boolean payload as a more generic alternative in future.
        }
    });
    
    // Notify Flutter that bridge is ready, only if visualizer core is also ready
    if (window.visualizerCoreIsReady) {
        if (window.flutter_inappwebview) {
            console.log('Bridge ready, notifying Flutter via flutter_inappwebview.');
            window.flutter_inappwebview.callHandler('bridgeReady');
        } else if (window.parent !== window) {
            console.log('Bridge ready, notifying parent window via postMessage.');
            window.parent.postMessage({ type: 'bridgeReady', status: 'Visualizer and Bridge are ready.' }, '*');
        }
        console.log('Flutter bridge initialized and ready signal sent.');
    } else {
        console.log('Flutter bridge initialized, but visualizer core not yet ready. Awaiting signalVisualizerCoreReady().');
    }
}

// The main visualizer script (e.g., visualizer-main.js) should call
// window.signalVisualizerCoreReady() when it has fully initialized mainVisualizerCore.
// For example, at the end of its own setup function:
//
// function initMyVisualizer() {
//    ...
//    window.mainVisualizerCore = new MyVisualizerCore();
//    window.visualParams = { ... };
//    ...
//    if (window.signalVisualizerCoreReady) {
//        window.signalVisualizerCoreReady();
//    }
// }
// initMyVisualizer();
//
// Old auto-init logic removed, relies on signalVisualizerCoreReady now.
console.log("flutter-bridge.js loaded. Waiting for signalVisualizerCoreReady().");