/* core/HypercubeCore.js - v1.4 */
import ShaderManager from './ShaderManager.js';

const DEFAULT_STATE = {
    startTime: 0, lastUpdateTime: 0, deltaTime: 0, time: 0.0, resolution: [0, 0],
    geometryType: 'hypercube', projectionMethod: 'perspective', dimensions: 4.0,
    morphFactor: 0.5, rotationSpeed: 0.2, universeModifier: 1.0, patternIntensity: 1.0,
    gridDensity: 8.0, lineThickness: 0.03, shellWidth: 0.025, tetraThickness: 0.035,
    glitchIntensity: 0.0, colorShift: 0.0,
    audioLevels: { bass: 0, mid: 0, high: 0 },
    colorScheme: { primary: [1.0, 0.2, 0.8], secondary: [0.2, 1.0, 1.0], background: [0.05, 0.0, 0.2] },
    needsShaderUpdate: false, _dirtyUniforms: new Set(), isRendering: false, animationFrameId: null,
    shaderProgramName: 'maleficarumViz',
    callbacks: { onRender: null, onError: null }
};

class HypercubeCore {
    constructor(canvas, shaderManager, options = {}) {
        if (!canvas || !(canvas instanceof HTMLCanvasElement)) throw new Error("Valid HTMLCanvasElement needed."); if (!shaderManager || !(shaderManager instanceof ShaderManager)) throw new Error("Valid ShaderManager needed."); this.canvas = canvas; this.gl = shaderManager.gl; this.shaderManager = shaderManager; this.quadBuffer = null; this.aPositionLoc = -1; this.state = { ...DEFAULT_STATE, ...options, colorScheme: { ...DEFAULT_STATE.colorScheme, ...(options.colorScheme || {}) }, audioLevels: { ...DEFAULT_STATE.audioLevels, ...(options.audioLevels || {}) }, callbacks: { ...DEFAULT_STATE.callbacks, ...(options.callbacks || {}) }, _dirtyUniforms: new Set() }; this.state.lineThickness = options.lineThickness ?? DEFAULT_STATE.lineThickness; this.state.shellWidth = options.shellWidth ?? DEFAULT_STATE.shellWidth; this.state.tetraThickness = options.tetraThickness ?? DEFAULT_STATE.tetraThickness; this._markAllUniformsDirty(); if (options.geometryType) this.state.geometryType = options.geometryType; if (options.projectionMethod) this.state.projectionMethod = options.projectionMethod; if (options.shaderProgramName) this.state.shaderProgramName = options.shaderProgramName; try { this._setupWebGLState(); this._initBuffers(); this.state.needsShaderUpdate = true; this._updateShaderIfNeeded(); } catch (error) { console.error("HypercubeCore Init Error:", error); this.state.callbacks.onError?.(error); }
    }

    _markAllUniformsDirty() { this.state._dirtyUniforms = new Set(); for (const key in DEFAULT_STATE) { if (['_dirtyUniforms', 'isRendering', 'animationFrameId', 'callbacks', 'startTime', 'lastUpdateTime', 'deltaTime', 'needsShaderUpdate', 'geometryType', 'projectionMethod', 'shaderProgramName'].includes(key)) continue; this._markUniformDirty(key); } }
    _markUniformDirty(stateKey) { let uniformNames = []; switch (stateKey) { case 'time': uniformNames.push('u_time'); break; case 'resolution': uniformNames.push('u_resolution'); break; case 'dimensions': uniformNames.push('u_dimension'); break; case 'morphFactor': uniformNames.push('u_morphFactor'); break; case 'rotationSpeed': uniformNames.push('u_rotationSpeed'); break; case 'universeModifier': uniformNames.push('u_universeModifier'); break; case 'patternIntensity': uniformNames.push('u_patternIntensity'); break; case 'gridDensity': uniformNames.push('u_gridDensity'); break; case 'lineThickness': uniformNames.push('u_lineThickness'); break; case 'shellWidth': uniformNames.push('u_shellWidth'); break; case 'tetraThickness': uniformNames.push('u_tetraThickness'); break; case 'glitchIntensity': uniformNames.push('u_glitchIntensity'); break; case 'colorShift': uniformNames.push('u_colorShift'); break; case 'audioLevels': uniformNames.push('u_audioBass', 'u_audioMid', 'u_audioHigh'); break; case 'colorScheme': uniformNames.push('u_primaryColor', 'u_secondaryColor', 'u_backgroundColor'); break; default: break; } uniformNames.forEach(name => this.state._dirtyUniforms.add(name)); }
    _setupWebGLState() { const gl = this.gl; const bg = this.state.colorScheme.background; gl.clearColor(bg[0], bg[1], bg[2], 1.0); gl.viewport(0, 0, gl.canvas.width, gl.canvas.height); gl.disable(gl.DEPTH_TEST); gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA); }
    _initBuffers() { const gl = this.gl; const pos = new Float32Array([-1,-1, 1,-1, -1,1, 1,1]); this.quadBuffer = gl.createBuffer(); if (!this.quadBuffer) throw new Error("Buffer creation failed."); gl.bindBuffer(gl.ARRAY_BUFFER, this.quadBuffer); gl.bufferData(gl.ARRAY_BUFFER, pos, gl.STATIC_DRAW); gl.bindBuffer(gl.ARRAY_BUFFER, null); }
    _updateShaderIfNeeded() { if (!this.state.needsShaderUpdate) return true; const progName=this.state.shaderProgramName, geomName=this.state.geometryType, projName=this.state.projectionMethod; console.log(`Updating shader '${progName}' (G:${geomName}, P:${projName})`); const program = this.shaderManager.createDynamicProgram(progName, geomName, projName); if (!program) { console.error(`Shader update failed.`); this.state.callbacks.onError?.(new Error(`Shader update failed`)); this.stop(); return false; } this.state.needsShaderUpdate = false; this.shaderManager.useProgram(progName); this.aPositionLoc = this.shaderManager.getAttributeLocation('a_position'); if (this.aPositionLoc === null) { console.warn(`Attr 'a_position' missing.`); } else { try { this.gl.enableVertexAttribArray(this.aPositionLoc); } catch (e) { console.error(`Enable attr error:`, e); this.aPositionLoc = -1; } } this._markAllUniformsDirty(); console.log(`Shader updated.`); return true; }
    updateParameters(newParams) { let shaderNeedsUpdate = false; for (const key in newParams) { if (!Object.hasOwnProperty.call(this.state, key)) continue; const oldValue = this.state[key]; const newValue = newParams[key]; let changed = false; if (typeof oldValue === 'object' && oldValue !== null && !Array.isArray(oldValue)) { if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) { this.state[key] = { ...oldValue, ...newValue }; changed = true; if (key === 'colorScheme') { if (newValue.hasOwnProperty('primary')) this._markUniformDirty('colorScheme.primary'); if (newValue.hasOwnProperty('secondary')) this._markUniformDirty('colorScheme.secondary'); if (newValue.hasOwnProperty('background')) this._markUniformDirty('colorScheme.background'); } else if (key === 'audioLevels') { if (newValue.hasOwnProperty('bass')) this._markUniformDirty('audioLevels.bass'); if (newValue.hasOwnProperty('mid')) this._markUniformDirty('audioLevels.mid'); if (newValue.hasOwnProperty('high')) this._markUniformDirty('audioLevels.high'); } } } else if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) { this.state[key] = newValue; changed = true; this._markUniformDirty(key); if (key === 'geometryType' || key === 'projectionMethod') { shaderNeedsUpdate = true; } } } if (shaderNeedsUpdate) { this.state.needsShaderUpdate = true; } }
    _checkResize() { const gl=this.gl, c=this.canvas, dw=c.clientWidth, dh=c.clientHeight; if(c.width!==dw || c.height!==dh){ c.width=dw; c.height=dh; gl.viewport(0,0,dw,dh); this.state.resolution=[dw,dh]; this._markUniformDirty('resolution'); return true; } return false; }
    _setUniforms() {
        const gl = this.gl; const dirty = this.state._dirtyUniforms; const programName = this.state.shaderProgramName;
        if (!this.shaderManager.useProgram(programName) || this.shaderManager.currentProgramName !== programName) return;
        const timeLoc = this.shaderManager.getUniformLocation('u_time');
        if (timeLoc) {
            gl.uniform1f(timeLoc, this.state.time);
        } else {
            // If u_time is essential and not found, it's a problem.
            // For now, assume ShaderManager caches null if not found, so this path won't be hit often after first try.
            // If it was previously in dirty, it will be processed below.
        }

        const stillDirtyUniforms = new Set();
        this.state._dirtyUniforms.forEach(name => {
            if (name === 'u_time' && timeLoc) return; // Already handled if found

            const loc = this.shaderManager.getUniformLocation(name);
            if (loc !== null) {
                try {
                    switch (name) {
                        case 'u_resolution': gl.uniform2fv(loc, this.state.resolution); break;
                        case 'u_dimension': gl.uniform1f(loc, this.state.dimensions); break;
                        case 'u_morphFactor': gl.uniform1f(loc, this.state.morphFactor); break;
                        case 'u_rotationSpeed': gl.uniform1f(loc, this.state.rotationSpeed); break;
                        case 'u_universeModifier': gl.uniform1f(loc, this.state.universeModifier); break;
                        case 'u_patternIntensity': gl.uniform1f(loc, this.state.patternIntensity); break;
                        case 'u_gridDensity': gl.uniform1f(loc, this.state.gridDensity); break;
                        case 'u_lineThickness': gl.uniform1f(loc, this.state.lineThickness); break;
                        case 'u_shellWidth': gl.uniform1f(loc, this.state.shellWidth); break;
                        case 'u_tetraThickness': gl.uniform1f(loc, this.state.tetraThickness); break;
                        case 'u_glitchIntensity': gl.uniform1f(loc, this.state.glitchIntensity); break;
                        case 'u_colorShift': gl.uniform1f(loc, this.state.colorShift); break;
                        case 'u_audioBass': gl.uniform1f(loc, this.state.audioLevels.bass); break;
                        case 'u_audioMid': gl.uniform1f(loc, this.state.audioLevels.mid); break;
                        case 'u_audioHigh': gl.uniform1f(loc, this.state.audioLevels.high); break;
                        case 'u_primaryColor': gl.uniform3fv(loc, this.state.colorScheme.primary); break;
                        case 'u_secondaryColor': gl.uniform3fv(loc, this.state.colorScheme.secondary); break;
                        case 'u_backgroundColor': gl.uniform3fv(loc, this.state.colorScheme.background); break;
                        default:
                            // console.warn(`Uniform '${name}' marked dirty but not handled in _setUniforms.`);
                            stillDirtyUniforms.add(name); // Keep it dirty if not explicitly handled
                            break;
                    }
                } catch (e) {
                    console.error(`Error setting uniform '${name}':`, e);
                    stillDirtyUniforms.add(name); // Keep it dirty if setting failed
                }
            } else {
                // Uniform location not found by ShaderManager (it will have cached null).
                // This usually means the uniform is not active in the current shader.
                // No need to add to stillDirtyUniforms if it's correctly not found.
                // console.warn(`Uniform '${name}' location not found in shader program '${programName}'. It might be optimized out or misspelled.`);
            }
        });
        this.state._dirtyUniforms = stillDirtyUniforms; // Only retain uniforms that genuinely need retry or were unhandled.
    }
    _render(timestamp) { if (!this.state.isRendering) return; const gl = this.gl; if (!gl || gl.isContextLost()) { console.error(`Context lost.`); this.stop(); this.state.callbacks.onError?.(new Error("WebGL context lost")); return; } if (!this.state.startTime) this.state.startTime = timestamp; const currentTime = (timestamp - this.state.startTime) * 0.001; this.state.deltaTime = currentTime - this.state.time; this.state.time = currentTime; this.state.lastUpdateTime = timestamp; this._markUniformDirty('time'); this._checkResize(); if (this.state.needsShaderUpdate) { if (!this._updateShaderIfNeeded()) { return; } } this._setUniforms(); const bg = this.state.colorScheme.background; gl.clearColor(bg[0], bg[1], bg[2], 1.0); gl.clear(gl.COLOR_BUFFER_BIT); if (this.quadBuffer && this.aPositionLoc !== null && this.aPositionLoc >= 0) { try { gl.bindBuffer(gl.ARRAY_BUFFER, this.quadBuffer); /*gl.enableVertexAttribArray(this.aPositionLoc);*/ gl.vertexAttribPointer(this.aPositionLoc, 2, gl.FLOAT, false, 0, 0); gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4); } catch (e) { console.error("Draw error:", e); this.stop(); this.state.callbacks.onError?.(new Error("WebGL draw error")); } } this.state.callbacks.onRender?.(this.state); this.state.animationFrameId = requestAnimationFrame(this._render.bind(this)); }
    start() { if (this.state.isRendering) return; if (!this.gl || this.gl.isContextLost()) { console.error(`Cannot start, WebGL context invalid.`); return; } console.log(`Starting render loop.`); this.state.isRendering = true; this.state.startTime = performance.now(); this.state.time = 0; this.state.lastUpdateTime = this.state.startTime; if (this.state.needsShaderUpdate) { if (!this._updateShaderIfNeeded()) { console.error(`Initial shader update failed.`); this.state.isRendering = false; return; } } else if (this.aPositionLoc === null || this.aPositionLoc < 0) { this.aPositionLoc = this.shaderManager.getAttributeLocation('a_position'); if (this.aPositionLoc === null || this.aPositionLoc < 0) { console.error(`Attr 'a_position' invalid.`); this.state.isRendering = false; return; } } if (this.aPositionLoc !== null && this.aPositionLoc >=0) { try { this.gl.enableVertexAttribArray(this.aPositionLoc); } catch (e) { console.error("Enable attr error during start:", e); this.state.isRendering = false; return; } } this._markAllUniformsDirty(); this.state.animationFrameId = requestAnimationFrame(this._render.bind(this)); }
    stop() { if (!this.state.isRendering) return; console.log(`Stopping render loop.`); if (this.state.animationFrameId) { cancelAnimationFrame(this.state.animationFrameId); } this.state.isRendering = false; this.state.animationFrameId = null; }
    dispose() { const name = this.state?.shaderProgramName || 'Unknown'; console.log(`Disposing HypercubeCore (${name})...`); this.stop(); if (this.gl && !this.gl.isContextLost()) { try { if (this.quadBuffer) this.gl.deleteBuffer(this.quadBuffer); if (this.shaderManager?.dispose) { this.shaderManager.dispose(); } const loseCtx = this.gl.getExtension('WEBGL_lose_context'); loseCtx?.loseContext(); } catch(e) { console.warn(`WebGL cleanup error:`, e); } } this.quadBuffer = null; this.gl = null; this.canvas = null; this.shaderManager = null; this.state = {}; console.log(`HypercubeCore (${name}) disposed.`); }
}
export default HypercubeCore;
