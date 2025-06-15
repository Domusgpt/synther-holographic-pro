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
    'oscillatorFrequency': { target: 'pulseSpeed', scale: (v) => v * 2.0} // Normalized frequency (0-1 from Flutter) affects pulsing speed of some elements.
};

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