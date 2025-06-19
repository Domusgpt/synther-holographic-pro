// Enhanced Flutter Bridge for Synther Holographic Pro
// Optimized for high-performance audio reactivity and seamless integration

console.log('🔗 Loading Enhanced Flutter Bridge for Synther HyperAV...');

// Global state management
window.syntherState = {
    visualParams: {
        // Synth engine parameters
        synthMode: 'wavetable', // wavetable, fm, granular, additive
        filterCutoff: 0.5,
        filterResonance: 0.3,
        masterVolume: 0.75,
        reverbMix: 0.2,
        
        // Visual parameters
        gridDensity: 12.0,
        dimension: 3.5,
        morphFactor: 0.5,
        glitchIntensity: 0.3,
        rotationSpeed: 0.5,
        
        // Performance
        fpsTarget: 60,
        audioReactivity: 1.0
    },
    
    // FFT data from Synther audio engine
    fftData: new Float32Array(256),
    
    // Interaction state
    interaction: {
        isActive: false,
        intensity: 0.0,
        lastUpdate: Date.now()
    },
    
    // Connection state
    isReady: false,
    flutterConnected: false
};

// Enhanced parameter mapping for audio-visual correlation
const PARAMETER_MAP = {
    // Filter parameters
    'filterCutoff': {
        target: 'filterCutoff',
        range: [0.0, 1.0],
        scale: (value) => Math.max(0.0, Math.min(1.0, value)),
        visualEffect: 'rotation_speed' // affects 4D rotation speed
    },
    
    'filterResonance': {
        target: 'filterResonance', 
        range: [0.0, 1.0],
        scale: (value) => Math.max(0.0, Math.min(1.0, value)),
        visualEffect: 'dimension_shift' // affects 4D projection
    },
    
    // Master controls
    'masterVolume': {
        target: 'masterVolume',
        range: [0.0, 1.0], 
        scale: (value) => Math.max(0.0, Math.min(1.0, value)),
        visualEffect: 'overall_intensity' // affects overall brightness
    },
    
    'reverbMix': {
        target: 'reverbMix',
        range: [0.0, 1.0],
        scale: (value) => Math.max(0.0, Math.min(1.0, value)),
        visualEffect: 'grid_density' // affects lattice complexity
    },
    
    // Synthesis-specific parameters
    'wavetablePosition': {
        target: 'morphFactor',
        range: [0.0, 1.0],
        scale: (value) => value * 0.8 + 0.2,
        visualEffect: 'geometry_morph'
    },
    
    'fmRatio': {
        target: 'rotationSpeed',
        range: [0.1, 8.0],
        scale: (value) => (value - 0.1) / 7.9,
        visualEffect: 'rotation_speed'
    },
    
    'grainDensity': {
        target: 'gridDensity',
        range: [0.1, 2.0],
        scale: (value) => 8.0 + (value - 0.1) / 1.9 * 12.0,
        visualEffect: 'particle_density'
    },
    
    'harmonicContent': {
        target: 'dimension',
        range: [0.0, 1.0],
        scale: (value) => 3.0 + value * 1.0,
        visualEffect: 'dimensional_complexity'
    }
};

// Synth mode configurations
const SYNTH_MODE_CONFIGS = {
    wavetable: {
        baseColor: [0.0, 1.0, 1.0], // Cyan
        geometry: 'hypercube',
        audioReactivity: 1.0,
        preferredParams: ['filterCutoff', 'wavetablePosition', 'reverbMix']
    },
    
    fm: {
        baseColor: [1.0, 0.0, 1.0], // Magenta
        geometry: 'fractal',
        audioReactivity: 1.2,
        preferredParams: ['fmRatio', 'filterCutoff', 'filterResonance']
    },
    
    granular: {
        baseColor: [1.0, 1.0, 0.0], // Yellow
        geometry: 'sphere',
        audioReactivity: 0.8,
        preferredParams: ['grainDensity', 'filterCutoff', 'reverbMix']
    },
    
    additive: {
        baseColor: [0.0, 1.0, 0.0], // Green
        geometry: 'crystal',
        audioReactivity: 1.5,
        preferredParams: ['harmonicContent', 'filterCutoff', 'masterVolume']
    }
};

// Message handler for Flutter communication
window.addEventListener('message', function(event) {
    try {
        const data = event.data;
        if (!data || typeof data !== 'object') return;
        
        switch (data.type) {
            case 'parameterUpdate':
                handleParameterUpdate(data.parameter, data.value);
                break;
                
            case 'fftDataUpdate':
                handleFFTDataUpdate(data.fftData);
                break;
                
            case 'synthModeChange':
                handleSynthModeChange(data.mode);
                break;
                
            case 'audioStateUpdate':
                handleAudioStateUpdate(data.state);
                break;
                
            case 'performanceMode':
                handlePerformanceMode(data.enabled);
                break;
                
            case 'toggleControls':
                handleToggleControls(data.show);
                break;
                
            case 'resetVisualizer':
                handleResetVisualizer();
                break;
                
            default:
                console.log('🔗 Unknown message type:', data.type);
        }
    } catch (error) {
        console.error('🚫 Flutter bridge message error:', error);
    }
});

// Parameter update handler with intelligent mapping
function handleParameterUpdate(parameter, value) {
    if (!parameter || value === undefined) return;
    
    const mapping = PARAMETER_MAP[parameter];
    if (mapping) {
        // Apply scaling and range clamping
        const scaledValue = mapping.scale ? mapping.scale(value) : value;
        const clampedValue = Math.max(mapping.range[0], Math.min(mapping.range[1], scaledValue));
        
        // Update visual parameters
        window.syntherState.visualParams[mapping.target] = clampedValue;
        
        // Send to visualizer if ready
        if (window.syntherHyperAV && window.syntherState.isReady) {
            window.syntherHyperAV.updateAudioParameter(mapping.target, clampedValue);
        }
        
        console.log(`🎛️ Parameter updated: ${parameter} = ${value} → ${mapping.target} = ${clampedValue.toFixed(3)}`);
    } else {
        // Direct parameter mapping
        window.syntherState.visualParams[parameter] = value;
        
        if (window.syntherHyperAV && window.syntherState.isReady) {
            window.syntherHyperAV.updateAudioParameter(parameter, value);
        }
    }
    
    // Update interaction state
    window.syntherState.interaction.isActive = true;
    window.syntherState.interaction.lastUpdate = Date.now();
}

// FFT data update with performance optimization
function handleFFTDataUpdate(fftData) {
    if (!fftData || !Array.isArray(fftData)) return;
    
    // Convert to Float32Array for WebGL efficiency
    window.syntherState.fftData = new Float32Array(fftData);
    
    // Send to visualizer
    if (window.syntherHyperAV && window.syntherState.isReady) {
        window.syntherHyperAV.updateFFTData(fftData);
    }
    
    // Update interaction intensity based on audio activity
    const audioLevel = fftData.reduce((sum, val) => sum + val, 0) / fftData.length;
    window.syntherState.interaction.intensity = Math.min(audioLevel * 2.0, 1.0);
}

// Synth mode change with smooth transitions
function handleSynthModeChange(mode) {
    if (!mode || !SYNTH_MODE_CONFIGS[mode]) return;
    
    const oldMode = window.syntherState.visualParams.synthMode;
    window.syntherState.visualParams.synthMode = mode;
    
    // Send to visualizer
    if (window.syntherHyperAV && window.syntherState.isReady) {
        window.syntherHyperAV.setSynthMode(mode);
    }
    
    console.log(`🎹 Synth mode changed: ${oldMode} → ${mode}`);
    
    // Signal mode change complete to Flutter
    signalModeChangeComplete(mode);
}

// Audio state update for comprehensive audio-visual sync
function handleAudioStateUpdate(state) {
    if (!state || typeof state !== 'object') return;
    
    // Update multiple parameters at once for efficiency
    Object.keys(state).forEach(key => {
        if (window.syntherState.visualParams.hasOwnProperty(key)) {
            window.syntherState.visualParams[key] = state[key];
        }
    });
    
    // Send bulk update to visualizer
    if (window.syntherHyperAV && window.syntherState.isReady) {
        Object.keys(state).forEach(key => {
            window.syntherHyperAV.updateAudioParameter(key, state[key]);
        });
    }
}

// Performance mode toggle
function handlePerformanceMode(enabled) {
    window.syntherState.visualParams.fpsTarget = enabled ? 30 : 60;
    window.syntherState.visualParams.audioReactivity = enabled ? 0.5 : 1.0;
    
    console.log(`⚡ Performance mode: ${enabled ? 'enabled' : 'disabled'}`);
}

// UI controls visibility toggle
function handleToggleControls(show) {
    if (window.syntherHyperAV && window.syntherState.isReady) {
        window.syntherHyperAV.toggleControls(show);
    }
}

// Visualizer reset
function handleResetVisualizer() {
    // Reset all parameters to defaults
    window.syntherState.visualParams = {
        synthMode: 'wavetable',
        filterCutoff: 0.5,
        filterResonance: 0.3,
        masterVolume: 0.75,
        reverbMix: 0.2,
        gridDensity: 12.0,
        dimension: 3.5,
        morphFactor: 0.5,
        glitchIntensity: 0.3,
        rotationSpeed: 0.5,
        fpsTarget: 60,
        audioReactivity: 1.0
    };
    
    window.syntherState.fftData = new Float32Array(256);
    
    if (window.syntherHyperAV && window.syntherState.isReady) {
        window.syntherHyperAV.setSynthMode('wavetable');
    }
    
    console.log('🔄 Visualizer reset to defaults');
}

// Signal readiness to Flutter
function signalVisualizerReady() {
    window.syntherState.isReady = true;
    
    // Send ready signal to Flutter
    if (window.parent && window.parent.postMessage) {
        window.parent.postMessage({
            type: 'visualizerReady',
            timestamp: Date.now(),
            capabilities: {
                synthModes: Object.keys(SYNTH_MODE_CONFIGS),
                supportedParameters: Object.keys(PARAMETER_MAP),
                maxFFTSize: 256,
                targetFPS: 60
            }
        }, '*');
    }
    
    console.log('📡 Visualizer ready signal sent to Flutter');
}

// Signal mode change completion
function signalModeChangeComplete(mode) {
    if (window.parent && window.parent.postMessage) {
        window.parent.postMessage({
            type: 'modeChangeComplete',
            mode: mode,
            timestamp: Date.now()
        }, '*');
    }
}

// Signal performance metrics
function signalPerformanceUpdate(fps, audioLatency) {
    if (window.parent && window.parent.postMessage) {
        window.parent.postMessage({
            type: 'performanceUpdate',
            fps: fps,
            audioLatency: audioLatency,
            timestamp: Date.now()
        }, '*');
    }
}

// Initialize bridge when visualizer core is ready
window.signalVisualizerCoreReady = function() {
    console.log('✅ Enhanced Flutter Bridge initialized');
    signalVisualizerReady();
};

// Connection monitoring
setInterval(() => {
    const now = Date.now();
    const timeSinceLastUpdate = now - window.syntherState.interaction.lastUpdate;
    
    // Auto-reduce interaction intensity over time
    if (timeSinceLastUpdate > 1000) { // 1 second
        window.syntherState.interaction.intensity *= 0.95;
        window.syntherState.interaction.isActive = window.syntherState.interaction.intensity > 0.01;
    }
    
    // Signal health check to Flutter
    if (window.syntherState.isReady && timeSinceLastUpdate > 5000) { // 5 seconds
        if (window.parent && window.parent.postMessage) {
            window.parent.postMessage({
                type: 'visualizerHealthCheck',
                status: 'active',
                timestamp: now
            }, '*');
        }
    }
}, 1000);

console.log('🔗 Enhanced Flutter Bridge loaded successfully');
console.log('📋 Supported synth modes:', Object.keys(SYNTH_MODE_CONFIGS));
console.log('🎛️ Supported parameters:', Object.keys(PARAMETER_MAP));