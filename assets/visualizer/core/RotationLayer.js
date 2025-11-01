/* core/RotationLayer.js - v1.0 */

/**
 * RotationLayer - Represents one of the 5 frequency-band-driven rotation layers
 * Each layer has independent rotation state, opacity, and speed controlled by specific frequency bands
 */
class RotationLayer {
    constructor(index, name, bandIndices) {
        this.index = index;              // 0-4
        this.name = name;                // 'foundation', 'bassStruct', etc.
        this.bandIndices = bandIndices;  // Which bands from 7-band analyzer drive this layer

        // Rotation state for all 6 4D rotation planes (accumulated over time)
        this.rotation = {
            XY: 0.0,  // Traditional 3D rotation
            XZ: 0.0,  // Horizontal twist
            YZ: 0.0,  // Vertical twist
            XW: 0.0,  // 4D depth rotation
            YW: 0.0,  // 4D secondary depth
            ZW: 0.0,  // 4D complex rotation
        };

        // Layer-specific parameters
        this.opacity = 0.0;              // Current opacity (0-1), driven by band energy
        this.targetOpacity = 0.0;        // Target opacity for smoothing
        this.speed = 1.0;                // Rotation speed multiplier
        this.gridDensity = 8.0;          // Per-layer grid density
        this.lineThickness = 0.03;       // Per-layer line thickness

        // Smoothing parameters
        this.opacityAttack = 0.1;        // Fast rise
        this.opacityRelease = 0.05;      // Slower fall
    }

    /**
     * Update layer based on band energies from 7-band analyzer
     * @param {Array<number>} bandLevels - 7 band energy levels (0-1)
     * @param {number} deltaTime - Time since last update
     * @param {Object} globalParams - Global parameters (rotationSpeed, morphFactor, etc.)
     */
    update(bandLevels, deltaTime, globalParams = {}) {
        // Calculate this layer's energy from its assigned bands
        let layerEnergy = 0.0;
        for (const bandIdx of this.bandIndices) {
            if (bandIdx >= 0 && bandIdx < bandLevels.length) {
                layerEnergy += bandLevels[bandIdx];
            }
        }
        layerEnergy /= this.bandIndices.length; // Average

        // Update target opacity based on energy
        this.targetOpacity = Math.min(layerEnergy * 1.2, 1.0); // Scale and clamp

        // Smooth opacity with attack/release
        if (this.targetOpacity > this.opacity) {
            // Attack - fast rise
            this.opacity += (this.targetOpacity - this.opacity) * this.opacityAttack;
        } else {
            // Release - slow fall
            this.opacity += (this.targetOpacity - this.opacity) * this.opacityRelease;
        }
        this.opacity = Math.max(0.0, Math.min(1.0, this.opacity));

        // Update rotations based on layer-specific behavior
        const baseSpeed = (globalParams.rotationSpeed || 1.0) * deltaTime * 0.01;
        const morphFactor = globalParams.morphFactor || 0.5;

        // Different layers emphasize different rotation planes
        switch (this.index) {
            case 0: // Foundation (Sub Bass) - XW, YW
                this.rotation.XW += baseSpeed * 0.5 * (1.0 + layerEnergy * 2.0);
                this.rotation.YW += baseSpeed * 0.4 * (1.0 + layerEnergy * 1.5);
                this.speed = 0.5 + layerEnergy * 0.5;
                break;

            case 1: // Bass Structure - XY, YZ
                this.rotation.XY += baseSpeed * 1.0 * (1.0 + layerEnergy * 3.0);
                this.rotation.YZ += baseSpeed * 0.8 * (1.0 + layerEnergy * 2.5);
                this.speed = 0.8 + layerEnergy * 1.2;
                break;

            case 2: // Mid Lattice - ZW, XZ
                this.rotation.ZW += baseSpeed * 1.2 * (1.0 + layerEnergy * 2.0);
                this.rotation.XZ += baseSpeed * 0.9 * (1.0 + layerEnergy * 1.8);
                this.speed = 1.0 + layerEnergy * 1.0;
                break;

            case 3: // High Detail - YW, XW (offset)
                this.rotation.YW += baseSpeed * 1.5 * (1.0 + layerEnergy * 2.5);
                this.rotation.XW += baseSpeed * 1.3 * (1.0 + layerEnergy * 2.0) + morphFactor * 0.01;
                this.speed = 1.2 + layerEnergy * 1.5;
                break;

            case 4: // Brilliance - All planes (micro-movements)
                this.rotation.XY += baseSpeed * 2.0 * layerEnergy;
                this.rotation.XZ += baseSpeed * 1.8 * layerEnergy;
                this.rotation.YZ += baseSpeed * 1.9 * layerEnergy;
                this.rotation.XW += baseSpeed * 2.1 * layerEnergy;
                this.rotation.YW += baseSpeed * 2.0 * layerEnergy;
                this.rotation.ZW += baseSpeed * 1.8 * layerEnergy;
                this.speed = 1.5 + layerEnergy * 2.0;
                break;
        }

        // Wrap rotations to 0-360 range
        for (const plane in this.rotation) {
            this.rotation[plane] = this.rotation[plane] % 360.0;
        }

        // Update per-layer visual parameters based on energy
        this.gridDensity = 6.0 + (this.index + 1) * 1.5 + layerEnergy * 3.0;
        this.lineThickness = 0.01 + (this.index * 0.005) + layerEnergy * 0.02;
    }

    /**
     * Get rotation state as object for shader uniforms
     */
    getRotationState() {
        return {
            ...this.rotation,
            opacity: this.opacity,
            speed: this.speed,
            gridDensity: this.gridDensity,
            lineThickness: this.lineThickness,
        };
    }

    /**
     * Reset layer to initial state
     */
    reset() {
        for (const plane in this.rotation) {
            this.rotation[plane] = 0.0;
        }
        this.opacity = 0.0;
        this.targetOpacity = 0.0;
        this.speed = 1.0;
    }
}

/**
 * LayerManager - Manages all 5 rotation layers
 */
class LayerManager {
    constructor() {
        // Create 5 layers with their frequency band assignments
        this.layers = [
            new RotationLayer(0, 'foundation', [0]),       // Sub Bass (20-60Hz)
            new RotationLayer(1, 'bassStruct', [1]),       // Bass (60-250Hz)
            new RotationLayer(2, 'midLattice', [2, 3]),    // Low Mids + Mids (250-2kHz)
            new RotationLayer(3, 'highDetail', [4, 5]),    // High Mids + Presence (2k-6kHz)
            new RotationLayer(4, 'brilliance', [6]),       // Brilliance (6k-20kHz)
        ];
    }

    /**
     * Update all layers
     */
    updateAll(bandLevels, deltaTime, globalParams) {
        for (const layer of this.layers) {
            layer.update(bandLevels, deltaTime, globalParams);
        }
    }

    /**
     * Get all layer states for shader uniforms
     */
    getAllStates() {
        return this.layers.map(layer => layer.getRotationState());
    }

    /**
     * Get specific layer
     */
    getLayer(index) {
        return this.layers[index];
    }

    /**
     * Reset all layers
     */
    resetAll() {
        for (const layer of this.layers) {
            layer.reset();
        }
    }
}

export { RotationLayer, LayerManager };
export default LayerManager;
