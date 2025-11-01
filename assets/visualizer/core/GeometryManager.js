/* core/GeometryManager-expanded.js - v2.0 - Full 8 Geometry Types Support */

/**
 * Base Geometry class
 * All geometry types extend this
 */
class BaseGeometry {
    constructor() {}
    getShaderCode() {
        throw new Error(`getShaderCode() must be implemented.`);
    }
}

// ============================================================================
// TIER 3: GEOMETRY TYPES (8 types)
// These define the topology/form of lines and movements
// They work on top of any polytope base structure
// ============================================================================

/**
 * 1. LATTICE GEOMETRY
 * Straight grid lines - Clean tones, pure intervals
 * This is the base geometric grid structure
 */
class LatticeGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // LATTICE: Straight grid lines
            // Works with any polytope to create clean wireframe structure
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                vec3 p_grid = fract(p * dynamicGridDensity * 0.5 + u_time * 0.01);
                vec3 dist = abs(p_grid - 0.5);
                float box = max(dist.x, max(dist.y, dist.z));
                return smoothstep(0.5, 0.5 - dynamicLineThickness, box);
            }
        `;
    }
}

/**
 * 2. RIBBON GEOMETRY
 * Curved surface strips - Vibrato, modulation
 * Creates flowing, undulating ribbons
 */
class RibbonGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // RIBBON: Curved surface strips
            // Creates flowing, wave-like surfaces
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                // Create wave-modulated ribbons
                float wave1 = sin(p.x * dynamicGridDensity * 0.5 + u_time * 0.5) * 0.2;
                float wave2 = cos(p.z * dynamicGridDensity * 0.4 + u_time * 0.3) * 0.2;

                vec3 p_wavy = p + vec3(wave1, wave2, wave1 * wave2);
                vec3 p_grid = fract(p_wavy * dynamicGridDensity * 0.4);

                // Create ribbon-like structure (emphasize certain axes)
                vec2 ribbon = abs(p_grid.xy - 0.5);
                float ribbonDist = max(ribbon.x, ribbon.y * 0.3); // Thinner in one direction

                return smoothstep(0.5, 0.5 - dynamicLineThickness * 1.5, ribbonDist);
            }
        `;
    }
}

/**
 * 3. PARTICLE GEOMETRY
 * Disconnected points - Granular texture, noise
 * Point cloud swarm behavior
 */
class ParticleGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // PARTICLE: Disconnected point cloud
            // Creates granular, swarm-like appearance
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                vec3 cell = floor(p * dynamicGridDensity * 0.5);
                vec3 cellPos = cell / (dynamicGridDensity * 0.5);

                // Pseudo-random particle placement within each cell
                float hash = fract(sin(dot(cell, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
                float hash2 = fract(sin(dot(cell, vec3(39.346, 11.135, 83.155))) * 23421.631);
                float hash3 = fract(sin(dot(cell, vec3(57.123, 19.456, 67.891))) * 31245.123);

                // Particle position offset
                vec3 particleOffset = vec3(hash, hash2, hash3) - 0.5;
                vec3 particlePos = cellPos + particleOffset * 0.8 / (dynamicGridDensity * 0.5);

                // Animate particles
                particlePos += vec3(
                    sin(u_time * 0.5 + hash * 6.28) * 0.1,
                    cos(u_time * 0.4 + hash2 * 6.28) * 0.1,
                    sin(u_time * 0.6 + hash3 * 6.28) * 0.1
                ) / dynamicGridDensity;

                // Distance to particle
                float dist = length(p - particlePos);
                float particleSize = dynamicLineThickness * 3.0 * (0.5 + hash * 0.5);

                return 1.0 - smoothstep(0.0, particleSize, dist);
            }
        `;
    }
}

/**
 * 4. HELIX GEOMETRY
 * Spiraling paths - Phase modulation, flanging
 * Creates twisted, coiling structures
 */
class HelixGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // HELIX: Spiraling paths
            // Creates twisted, rotating spiral structures
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                // Convert to cylindrical coordinates for helix
                float angle = atan(p.y, p.x);
                float radius = length(p.xy);
                float height = p.z * dynamicGridDensity * 0.3;

                // Create spiral
                float helixAngle = angle * 3.0 + height + u_time * 0.5;
                float helixX = cos(helixAngle) * 0.5;
                float helixY = sin(helixAngle) * 0.5;

                // Multiple intertwined helices
                float helix1 = length(vec2(radius - 0.5, fract(height * 0.2) - 0.5)) - 0.05;
                float helix2 = length(vec2(radius - 0.5 + helixX * 0.2, fract(height * 0.2 + 0.333) - 0.5 + helixY * 0.2)) - 0.05;
                float helix3 = length(vec2(radius - 0.5 - helixX * 0.2, fract(height * 0.2 + 0.666) - 0.5 - helixY * 0.2)) - 0.05;

                float helixDist = min(helix1, min(helix2, helix3));

                return 1.0 - smoothstep(0.0, dynamicLineThickness * 2.0, helixDist);
            }
        `;
    }
}

/**
 * 5. FRACTAL GEOMETRY
 * Self-similar branching - Feedback, resonance
 * Recursive, tree-like structures
 */
class FractalGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // FRACTAL: Self-similar branching
            // Creates recursive, chaotic structures
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                vec3 z = p * dynamicGridDensity * 0.15;
                float scale = 2.0 + u_morphFactor * 0.5;
                vec3 offset = vec3(0.5, 0.5, 0.5);

                // IFS (Iterated Function System) fractal
                float dist = 1e10;
                for (int i = 0; i < 4; i++) {
                    z = abs(z);
                    if (z.x < z.y) z.xy = z.yx;
                    if (z.x < z.z) z.xz = z.zx;
                    if (z.y < z.z) z.yz = z.zy;

                    z = z * scale - offset * (scale - 1.0);
                    z.z -= 0.5 * (scale - 1.0);
                    z.z += sin(u_time * 0.2 + float(i) * 0.5) * 0.1;

                    // Track minimum distance
                    dist = min(dist, length(z) * pow(scale, -float(i + 1)));
                }

                // Convert distance to pattern intensity
                return 1.0 - smoothstep(0.0, dynamicLineThickness * 4.0, dist);
            }
        `;
    }
}

/**
 * 6. INTERFERENCE GEOMETRY
 * Overlapping waves - Chorus, detuning
 * Creates moiré patterns and wave interference
 */
class InterferenceGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // INTERFERENCE: Overlapping waves
            // Creates wave interference patterns (moiré, beating)
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                float freq1 = dynamicGridDensity * 0.5;
                float freq2 = dynamicGridDensity * 0.52; // Slight detuning
                float freq3 = dynamicGridDensity * 0.48;

                // Multiple overlapping wave systems
                float wave1 = sin(p.x * freq1 + u_time * 0.5) * sin(p.y * freq1 - u_time * 0.3) * sin(p.z * freq1 + u_time * 0.4);
                float wave2 = sin(p.x * freq2 - u_time * 0.4) * sin(p.y * freq2 + u_time * 0.5) * sin(p.z * freq2 - u_time * 0.3);
                float wave3 = sin(p.x * freq3 + u_time * 0.3) * sin(p.y * freq3 - u_time * 0.4) * sin(p.z * freq3 + u_time * 0.5);

                // Combine waves to create interference
                float interference = (wave1 + wave2 + wave3) / 3.0;

                // Create visible interference fringes
                float fringes = abs(fract(interference * 2.0 + 0.5) - 0.5);

                return smoothstep(0.5, 0.5 - dynamicLineThickness * 2.0, fringes);
            }
        `;
    }
}

/**
 * 7. MEMBRANE GEOMETRY
 * Tensioned surfaces - Filter sweeps, wah
 * Creates rippling, elastic surface effects
 */
class MembraneGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // MEMBRANE: Tensioned surfaces
            // Creates rippling, wave-propagation effects
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                // Create membrane displacement with wave equation simulation
                float centerDist = length(p.xy);
                float ripple = sin(centerDist * dynamicGridDensity * 0.8 - u_time * 2.0) *
                               exp(-centerDist * 0.5) *
                               (0.5 + u_audioMid * 0.5);

                // Secondary ripple source
                vec2 source2 = vec2(sin(u_time * 0.3) * 0.5, cos(u_time * 0.3) * 0.5);
                float centerDist2 = length(p.xy - source2);
                float ripple2 = sin(centerDist2 * dynamicGridDensity * 0.8 - u_time * 2.0 + 1.57) *
                                exp(-centerDist2 * 0.5) *
                                (0.5 + u_audioHigh * 0.5);

                // Combine ripples
                float displacement = ripple + ripple2;

                // Create membrane surface
                vec3 p_displaced = p + vec3(0.0, 0.0, displacement * 0.3);
                vec3 p_grid = fract(p_displaced * dynamicGridDensity * 0.4);
                vec3 dist = abs(p_grid - 0.5);
                float membranePattern = max(dist.x, max(dist.y, dist.z));

                return smoothstep(0.5, 0.5 - dynamicLineThickness * 1.5, membranePattern);
            }
        `;
    }
}

/**
 * 8. CRYSTALLINE GEOMETRY
 * Sharp, faceted planes - Distortion, bit crushing
 * Creates shattering, prismatic effects
 */
class CrystallineGeometry extends BaseGeometry {
    getShaderCode() {
        return `
            // CRYSTALLINE: Sharp, faceted planes
            // Creates shattering, angular, prismatic structures
            float calculateLatticePattern(vec3 p, float dynamicGridDensity, float dynamicLineThickness) {
                vec3 cell = floor(p * dynamicGridDensity * 0.5);
                vec3 cellPos = cell / (dynamicGridDensity * 0.5);

                // Create angular, faceted structure
                vec3 toCenter = p - cellPos;

                // Generate random facet normals for each cell
                float hash = fract(sin(dot(cell, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
                vec3 normal1 = normalize(vec3(sin(hash * 6.28), cos(hash * 6.28), sin(hash * 3.14)));
                vec3 normal2 = normalize(vec3(cos(hash * 12.56), sin(hash * 9.42), cos(hash * 6.28)));
                vec3 normal3 = normalize(vec3(sin(hash * 15.7), cos(hash * 18.84), sin(hash * 12.56)));

                // Create sharp facets
                float facet1 = abs(dot(toCenter, normal1));
                float facet2 = abs(dot(toCenter, normal2));
                float facet3 = abs(dot(toCenter, normal3));

                // Combine facets
                float facetDist = min(facet1, min(facet2, facet3));

                // Add "shatter" effect with audio reactivity
                float shatter = u_glitchIntensity * sin(u_time * 3.0 + hash * 6.28) * 0.1;
                facetDist += shatter;

                // Sharp edges
                return 1.0 - smoothstep(dynamicLineThickness * 0.5, dynamicLineThickness * 1.0, facetDist);
            }
        `;
    }
}

// ============================================================================
// GEOMETRY MANAGER
// Manages all geometry types and provides shader code generation
// ============================================================================

class GeometryManager {
    constructor(options = {}) {
        this.options = {
            defaultGeometry: 'lattice',
            ...options
        };
        this.geometries = {};
        this._initGeometries();
    }

    _initGeometries() {
        // Register all 8 geometry types
        this.registerGeometry('lattice', new LatticeGeometry());
        this.registerGeometry('ribbon', new RibbonGeometry());
        this.registerGeometry('particle', new ParticleGeometry());
        this.registerGeometry('helix', new HelixGeometry());
        this.registerGeometry('fractal', new FractalGeometry());
        this.registerGeometry('interference', new InterferenceGeometry());
        this.registerGeometry('membrane', new MembraneGeometry());
        this.registerGeometry('crystalline', new CrystallineGeometry());
    }

    registerGeometry(name, instance) {
        const lowerCaseName = name.toLowerCase();
        if (!(instance instanceof BaseGeometry)) {
            console.error(`Invalid geometry object for '${lowerCaseName}'.`);
            return;
        }
        if (this.geometries[lowerCaseName]) {
            console.warn(`Overwriting geometry '${lowerCaseName}'.`);
        }
        this.geometries[lowerCaseName] = instance;
    }

    getGeometry(name) {
        const lowerCaseName = name ? name.toLowerCase() : this.options.defaultGeometry;
        const geometry = this.geometries[lowerCaseName];
        if (!geometry) {
            console.warn(`Geometry '${name}' not found. Using default '${this.options.defaultGeometry}'.`);
            return this.geometries[this.options.defaultGeometry.toLowerCase()];
        }
        return geometry;
    }

    getGeometryTypes() {
        return Object.keys(this.geometries);
    }

    /**
     * Generate complete shader code for a given polytope and geometry combination
     * @param {string} polytopeName - 'hypercube', 'hypersphere', or 'hypertetrahedron'
     * @param {string} geometryName - One of the 8 geometry types
     * @returns {string} Complete shader function code
     */
    generatePolytopeGeometryShader(polytopeName, geometryName) {
        const geometry = this.getGeometry(geometryName);
        const geometryShader = geometry.getShaderCode();

        // Get polytope-specific base structure
        const polytopeStructure = this._getPolytopeStructure(polytopeName);

        // Combine polytope structure with geometry pattern
        return `
            ${geometryShader}

            ${polytopeStructure}

            // Main calculateLattice function combines polytope and geometry
            float calculateLattice(vec3 p) {
                // Dynamic parameters affected by audio
                float dynamicGridDensity = max(0.1, u_gridDensity * (1.0 + u_audioBass * 0.7));
                float dynamicLineThickness = max(0.002, u_lineThickness * (1.0 - u_audioMid * 0.6));

                // Get base pattern from geometry type
                float pattern3D = calculateLatticePattern(p, dynamicGridDensity, dynamicLineThickness);

                // Apply 4D transformation based on polytope
                float finalLattice = apply4DTransformation(p, pattern3D, dynamicGridDensity, dynamicLineThickness);

                // Apply universe modifier
                return pow(finalLattice, 1.0 / max(0.1, u_universeModifier));
            }
        `;
    }

    /**
     * Get polytope-specific 4D transformation code
     */
    _getPolytopeStructure(polytopeName) {
        switch (polytopeName.toLowerCase()) {
            case 'hypercube':
                return `
                    float apply4DTransformation(vec3 p, float pattern3D, float dynamicGridDensity, float dynamicLineThickness) {
                        float dim_factor = smoothstep(3.0, 4.5, u_dimension);

                        if (dim_factor > 0.01) {
                            float w_coord = sin(p.x*1.4 - p.y*0.7 + p.z*1.5 + u_time * 0.25)
                                          * cos(length(p) * 1.1 - u_time * 0.35 + u_audioMid * 2.5)
                                          * dim_factor * (0.4 + u_morphFactor * 0.6 + u_audioHigh * 0.6);

                            vec4 p4d = vec4(p, w_coord);
                            float baseSpeed = u_rotationSpeed * 1.0;
                            float time_rot1 = u_time * 0.33 * baseSpeed + u_audioHigh * 0.25 + u_morphFactor * 0.45;
                            float time_rot2 = u_time * 0.28 * baseSpeed - u_audioMid * 0.28;
                            float time_rot3 = u_time * 0.25 * baseSpeed + u_audioBass * 0.35;
                            p4d = rotXW(time_rot1) * rotYZ(time_rot2 * 1.1) * rotZW(time_rot3 * 0.9) * p4d;
                            p4d = rotYW(u_time * -0.22 * baseSpeed + u_morphFactor * 0.3) * p4d;

                            vec3 projectedP = project4Dto3D(p4d);
                            float pattern4D = calculateLatticePattern(projectedP, dynamicGridDensity, dynamicLineThickness);
                            return mix(pattern3D, pattern4D, smoothstep(0.0, 1.0, u_morphFactor));
                        }
                        return pattern3D;
                    }
                `;

            case 'hypersphere':
                return `
                    float apply4DTransformation(vec3 p, float pattern3D, float dynamicGridDensity, float dynamicLineThickness) {
                        float dim_factor = smoothstep(3.0, 4.5, u_dimension);

                        if (dim_factor > 0.01) {
                            float radius3D = length(p);
                            float w_coord = cos(radius3D * 2.5 - u_time * 0.55)
                                          * sin(p.x*1.0 + p.y*1.3 - p.z*0.7 + u_time*0.2)
                                          * dim_factor * (0.5 + u_morphFactor * 0.5 + u_audioMid * 0.5);

                            vec4 p4d = vec4(p, w_coord);
                            float baseSpeed = u_rotationSpeed * 0.85;
                            float time_rot1 = u_time * 0.38 * baseSpeed + u_audioHigh * 0.2;
                            float time_rot2 = u_time * 0.31 * baseSpeed + u_morphFactor * 0.6;
                            float time_rot3 = u_time * -0.24 * baseSpeed + u_audioBass * 0.25;
                            p4d = rotXW(time_rot1 * 1.05) * rotYZ(time_rot2) * rotYW(time_rot3 * 0.95) * p4d;

                            vec3 projectedP = project4Dto3D(p4d);
                            float pattern4D = calculateLatticePattern(projectedP, dynamicGridDensity, dynamicLineThickness);
                            return mix(pattern3D, pattern4D, smoothstep(0.0, 1.0, u_morphFactor));
                        }
                        return pattern3D;
                    }
                `;

            case 'hypertetrahedron':
                return `
                    float apply4DTransformation(vec3 p, float pattern3D, float dynamicGridDensity, float dynamicLineThickness) {
                        float dim_factor = smoothstep(3.0, 4.5, u_dimension);

                        if (dim_factor > 0.01) {
                            float w_coord = cos(p.x*1.8 - p.y*1.5 + p.z*1.2 + u_time*0.24)
                                          * sin(length(p)*1.4 + u_time*0.18 - u_audioMid*2.0)
                                          * dim_factor * (0.45 + u_morphFactor*0.55 + u_audioHigh*0.4);
                            vec4 p4d = vec4(p, w_coord);
                            float baseSpeed = u_rotationSpeed * 1.15;
                            float time_rot1 = u_time*0.28*baseSpeed + u_audioHigh*0.25;
                            float time_rot2 = u_time*0.36*baseSpeed - u_audioBass*0.2 + u_morphFactor*0.4;
                            float time_rot3 = u_time*0.32*baseSpeed + u_audioMid*0.15;
                            p4d = rotXW(time_rot1*0.95) * rotYW(time_rot2*1.05) * rotZW(time_rot3) * p4d;
                            vec3 projectedP = project4Dto3D(p4d);

                            float pattern4D = calculateLatticePattern(projectedP, dynamicGridDensity, dynamicLineThickness);
                            return mix(pattern3D, pattern4D, smoothstep(0.0, 1.0, u_morphFactor));
                        }
                        return pattern3D;
                    }
                `;

            default:
                console.warn(`Unknown polytope: ${polytopeName}, using hypercube`);
                return this._getPolytopeStructure('hypercube');
        }
    }
}

export { GeometryManager, BaseGeometry };
export default GeometryManager;
