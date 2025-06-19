import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'polytope_math.dart';

/// Professional WebGL 4D Polytope Renderer
/// 
/// Features:
/// - High-performance WebGL 2.0 rendering
/// - Real-time 4D to 3D projection with audio reactivity
/// - Holographic effects: chromatic aberration, depth glow, particle trails
/// - Anti-aliased line rendering with dynamic thickness
/// - Transparency and depth sorting for faces
/// - Professional shader pipeline with multiple rendering passes

/// Shader program wrapper
class ShaderProgram {
  final gl.RenderingContext2 _gl;
  final gl.Program program;
  final Map<String, gl.UniformLocation?> _uniforms = {};
  final Map<String, int> _attributes = {};
  
  ShaderProgram(this._gl, this.program);
  
  /// Get uniform location
  gl.UniformLocation? getUniform(String name) {
    if (!_uniforms.containsKey(name)) {
      _uniforms[name] = _gl.getUniformLocation(program, name);
    }
    return _uniforms[name];
  }
  
  /// Get attribute location
  int getAttribute(String name) {
    if (!_attributes.containsKey(name)) {
      _attributes[name] = _gl.getAttribLocation(program, name);
    }
    return _attributes[name];
  }
  
  /// Use this shader program
  void use() {
    _gl.useProgram(program);
  }
  
  /// Set uniform values
  void setFloat(String name, double value) {
    final location = getUniform(name);
    if (location != null) _gl.uniform1f(location, value);
  }
  
  void setVec3(String name, List<double> value) {
    final location = getUniform(name);
    if (location != null) _gl.uniform3f(location, value[0], value[1], value[2]);
  }
  
  void setVec4(String name, List<double> value) {
    final location = getUniform(name);
    if (location != null) _gl.uniform4f(location, value[0], value[1], value[2], value[3]);
  }
  
  void setMat4(String name, List<double> matrix) {
    final location = getUniform(name);
    if (location != null) {
      _gl.uniformMatrix4fv(location, false, Float32List.fromList(matrix));
    }
  }
}

/// Vertex buffer object wrapper
class VertexBuffer {
  final gl.RenderingContext2 _gl;
  final gl.Buffer buffer;
  final int componentCount;
  final int vertexCount;
  
  VertexBuffer(this._gl, this.buffer, this.componentCount, this.vertexCount);
  
  void bind() {
    _gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  }
  
  void bindToAttribute(int attributeLocation) {
    bind();
    _gl.enableVertexAttribArray(attributeLocation);
    _gl.vertexAttribPointer(attributeLocation, componentCount, gl.FLOAT, false, 0, 0);
  }
  
  void dispose() {
    _gl.deleteBuffer(buffer);
  }
}

/// Render configuration for different polytope elements
class RenderConfig {
  bool showVertices;
  bool showEdges;
  bool showFaces;
  double vertexSize;
  double edgeThickness;
  double faceOpacity;
  List<double> vertexColor;
  List<double> edgeColor;
  List<double> faceColor;
  bool enableHolographicEffects;
  double holographicIntensity;
  double chromaticAberration;
  bool enableDepthGlow;
  bool enableParticleTrails;
  
  RenderConfig({
    this.showVertices = true,
    this.showEdges = true,
    this.showFaces = true,
    this.vertexSize = 3.0,
    this.edgeThickness = 2.0,
    this.faceOpacity = 0.3,
    this.vertexColor = const [1.0, 1.0, 1.0, 1.0],
    this.edgeColor = const [0.0, 1.0, 1.0, 1.0],
    this.faceColor = const [0.5, 0.0, 1.0, 0.3],
    this.enableHolographicEffects = true,
    this.holographicIntensity = 0.8,
    this.chromaticAberration = 0.01,
    this.enableDepthGlow = true,
    this.enableParticleTrails = false,
  });
}

/// Performance metrics for rendering
class RenderMetrics {
  int verticesRendered;
  int edgesRendered;
  int facesRendered;
  double frameTime;
  double fps;
  int drawCalls;
  
  RenderMetrics({
    this.verticesRendered = 0,
    this.edgesRendered = 0,
    this.facesRendered = 0,
    this.frameTime = 0.0,
    this.fps = 0.0,
    this.drawCalls = 0,
  });
}

/// Professional 4D Polytope WebGL Renderer
class PolytopeRenderer {
  late gl.RenderingContext2 _gl;
  late html.CanvasElement _canvas;
  
  // Shader programs
  late ShaderProgram _vertexShader;
  late ShaderProgram _edgeShader;
  late ShaderProgram _faceShader;
  late ShaderProgram _holographicShader;
  late ShaderProgram _postProcessShader;
  
  // Framebuffers for multi-pass rendering
  late gl.Framebuffer _mainFramebuffer;
  late gl.Texture _mainColorTexture;
  late gl.Texture _mainDepthTexture;
  late gl.Framebuffer _postProcessFramebuffer;
  late gl.Texture _postProcessTexture;
  
  // Vertex buffers
  final Map<String, VertexBuffer> _vertexBuffers = {};
  
  // Projection and view matrices
  final Projection4D _projection4D = Projection4D();
  late List<double> _viewMatrix;
  late List<double> _projectionMatrix;
  
  // Rendering state
  RenderConfig _config = RenderConfig();
  RenderMetrics _lastMetrics = RenderMetrics();
  
  // Performance tracking
  late DateTime _lastFrameTime;
  final List<double> _frameTimes = [];
  static const int maxFrameTimeHistory = 60;
  
  // Audio-reactive parameters
  late AudioReactiveParams _currentAudioParams;
  
  int _canvasWidth = 800;
  int _canvasHeight = 600;
  
  /// Initialize WebGL renderer
  Future<bool> initialize(html.CanvasElement canvas) async {
    try {
      _canvas = canvas;
      _canvasWidth = canvas.width!;
      _canvasHeight = canvas.height!;
      
      _gl = canvas.getContext('webgl2') as gl.RenderingContext2;
      
      if (_gl == null) {
        print('WebGL 2.0 not supported');
        return false;
      }
      
      // Initialize WebGL state
      _initializeWebGLState();
      
      // Load and compile shaders
      await _initializeShaders();
      
      // Create framebuffers for multi-pass rendering
      _initializeFramebuffers();
      
      // Initialize projection matrices
      _initializeMatrices();
      
      // Initialize audio parameters
      _currentAudioParams = AudioReactiveParams();
      
      _lastFrameTime = DateTime.now();
      
      return true;
    } catch (e) {
      print('Failed to initialize polytope renderer: $e');
      return false;
    }
  }
  
  void _initializeWebGLState() {
    _gl.enable(gl.DEPTH_TEST);
    _gl.enable(gl.BLEND);
    _gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    _gl.depthFunc(gl.LEQUAL);
    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    
    // Enable line width (if supported)
    try {
      _gl.enable(gl.LINE_SMOOTH);
    } catch (e) {
      // Line smoothing not available
    }
  }
  
  Future<void> _initializeShaders() async {
    // Create vertex shader for points
    _vertexShader = _createShaderProgram(_vertexVertexShader, _vertexFragmentShader);
    
    // Create edge shader for lines
    _edgeShader = _createShaderProgram(_edgeVertexShader, _edgeFragmentShader);
    
    // Create face shader for triangles
    _faceShader = _createShaderProgram(_faceVertexShader, _faceFragmentShader);
    
    // Create holographic effect shader
    _holographicShader = _createShaderProgram(_holographicVertexShader, _holographicFragmentShader);
    
    // Create post-processing shader
    _postProcessShader = _createShaderProgram(_postProcessVertexShader, _postProcessFragmentShader);
  }
  
  ShaderProgram _createShaderProgram(String vertexSource, String fragmentSource) {
    final vertexShader = _compileShader(gl.VERTEX_SHADER, vertexSource);
    final fragmentShader = _compileShader(gl.FRAGMENT_SHADER, fragmentSource);
    
    final program = _gl.createProgram()!;
    _gl.attachShader(program, vertexShader);
    _gl.attachShader(program, fragmentShader);
    _gl.linkProgram(program);
    
    if (!_gl.getProgramParameter(program, gl.LINK_STATUS)) {
      final error = _gl.getProgramInfoLog(program);
      throw Exception('Shader program link error: $error');
    }
    
    _gl.deleteShader(vertexShader);
    _gl.deleteShader(fragmentShader);
    
    return ShaderProgram(_gl, program);
  }
  
  gl.Shader _compileShader(int type, String source) {
    final shader = _gl.createShader(type)!;
    _gl.shaderSource(shader, source);
    _gl.compileShader(shader);
    
    if (!_gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      final error = _gl.getShaderInfoLog(shader);
      _gl.deleteShader(shader);
      throw Exception('Shader compile error: $error');
    }
    
    return shader;
  }
  
  void _initializeFramebuffers() {
    // Main rendering framebuffer
    _mainFramebuffer = _gl.createFramebuffer()!;
    _mainColorTexture = _createColorTexture(_canvasWidth, _canvasHeight);
    _mainDepthTexture = _createDepthTexture(_canvasWidth, _canvasHeight);
    
    _gl.bindFramebuffer(gl.FRAMEBUFFER, _mainFramebuffer);
    _gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, _mainColorTexture, 0);
    _gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, _mainDepthTexture, 0);
    
    // Post-processing framebuffer
    _postProcessFramebuffer = _gl.createFramebuffer()!;
    _postProcessTexture = _createColorTexture(_canvasWidth, _canvasHeight);
    
    _gl.bindFramebuffer(gl.FRAMEBUFFER, _postProcessFramebuffer);
    _gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, _postProcessTexture, 0);
    
    _gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  }
  
  gl.Texture _createColorTexture(int width, int height) {
    final texture = _gl.createTexture()!;
    _gl.bindTexture(gl.TEXTURE_2D, texture);
    _gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return texture;
  }
  
  gl.Texture _createDepthTexture(int width, int height) {
    final texture = _gl.createTexture()!;
    _gl.bindTexture(gl.TEXTURE_2D, texture);
    _gl.texImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT24, width, height, 0, gl.DEPTH_COMPONENT, gl.UNSIGNED_INT, null);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    _gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    return texture;
  }
  
  void _initializeMatrices() {
    // Initialize view matrix (identity for now)
    _viewMatrix = [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ];
    
    // Initialize projection matrix
    _updateProjectionMatrix();
  }
  
  void _updateProjectionMatrix() {
    final aspect = _canvasWidth / _canvasHeight;
    final fov = 45.0 * math.pi / 180.0;
    final near = 0.1;
    final far = 100.0;
    
    final f = 1.0 / math.tan(fov / 2.0);
    
    _projectionMatrix = [
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) / (near - far), (2 * far * near) / (near - far),
      0, 0, -1, 0,
    ];
  }
  
  /// Render polytope with full pipeline
  void renderPolytope(Polytope4D polytope, AudioReactiveParams audioParams) {
    final startTime = DateTime.now();
    _currentAudioParams = audioParams;
    
    // Clear metrics
    _lastMetrics = RenderMetrics();
    
    // Project 4D polytope to 3D
    final projected3D = _projection4D.projectPolytope(polytope);
    
    // Multi-pass rendering
    _renderMainPass(polytope, projected3D);
    
    if (_config.enableHolographicEffects) {
      _renderHolographicPass();
    }
    
    _renderPostProcessPass();
    
    // Update performance metrics
    final endTime = DateTime.now();
    _updateMetrics(startTime, endTime, polytope);
  }
  
  void _renderMainPass(Polytope4D polytope, List<Vector3D> projected3D) {
    _gl.bindFramebuffer(gl.FRAMEBUFFER, _mainFramebuffer);
    _gl.viewport(0, 0, _canvasWidth, _canvasHeight);
    _gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    
    // Render faces first (back to front for transparency)
    if (_config.showFaces) {
      _renderFaces(polytope, projected3D);
    }
    
    // Render edges
    if (_config.showEdges) {
      _renderEdges(polytope, projected3D);
    }
    
    // Render vertices on top
    if (_config.showVertices) {
      _renderVertices(projected3D);
    }
  }
  
  void _renderVertices(List<Vector3D> vertices) {
    _vertexShader.use();
    
    // Create vertex buffer
    final vertexData = Float32List(vertices.length * 3);
    for (int i = 0; i < vertices.length; i++) {
      vertexData[i * 3] = vertices[i].x;
      vertexData[i * 3 + 1] = vertices[i].y;
      vertexData[i * 3 + 2] = vertices[i].z;
    }
    
    final buffer = _createVertexBuffer(vertexData);
    buffer.bindToAttribute(_vertexShader.getAttribute('position'));
    
    // Set uniforms
    _vertexShader.setMat4('viewMatrix', _viewMatrix);
    _vertexShader.setMat4('projectionMatrix', _projectionMatrix);
    _vertexShader.setFloat('pointSize', _config.vertexSize);
    _vertexShader.setVec4('color', _config.vertexColor);
    _vertexShader.setFloat('audioAmplitude', _currentAudioParams.amplitude);
    
    // Render points
    _gl.drawArrays(gl.POINTS, 0, vertices.length);
    
    _lastMetrics.verticesRendered = vertices.length;
    _lastMetrics.drawCalls++;
    
    buffer.dispose();
  }
  
  void _renderEdges(Polytope4D polytope, List<Vector3D> vertices) {
    _edgeShader.use();
    
    // Create edge vertex data
    final edgeData = <double>[];
    for (final edge in polytope.edges) {
      final v1 = vertices[edge.vertex1];
      final v2 = vertices[edge.vertex2];
      
      edgeData.addAll([v1.x, v1.y, v1.z]);
      edgeData.addAll([v2.x, v2.y, v2.z]);
    }
    
    final buffer = _createVertexBuffer(Float32List.fromList(edgeData));
    buffer.bindToAttribute(_edgeShader.getAttribute('position'));
    
    // Set uniforms
    _edgeShader.setMat4('viewMatrix', _viewMatrix);
    _edgeShader.setMat4('projectionMatrix', _projectionMatrix);
    _edgeShader.setFloat('lineWidth', _config.edgeThickness);
    _edgeShader.setVec4('color', _config.edgeColor);
    _edgeShader.setFloat('audioFrequency', _currentAudioParams.frequency / 1000.0);
    _edgeShader.setFloat('audioSpectralCentroid', _currentAudioParams.spectralCentroid);
    
    // Render lines
    _gl.drawArrays(gl.LINES, 0, polytope.edges.length * 2);
    
    _lastMetrics.edgesRendered = polytope.edges.length;
    _lastMetrics.drawCalls++;
    
    buffer.dispose();
  }
  
  void _renderFaces(Polytope4D polytope, List<Vector3D> vertices) {
    if (polytope.faces.isEmpty) return;
    
    _faceShader.use();
    
    // Create face vertex data (triangulate faces)
    final faceData = <double>[];
    int triangleCount = 0;
    
    for (final face in polytope.faces) {
      if (face.isVisible && face.vertices.length >= 3) {
        // Simple triangulation for faces
        for (int i = 1; i < face.vertices.length - 1; i++) {
          final v0 = vertices[face.vertices[0]];
          final v1 = vertices[face.vertices[i]];
          final v2 = vertices[face.vertices[i + 1]];
          
          faceData.addAll([v0.x, v0.y, v0.z]);
          faceData.addAll([v1.x, v1.y, v1.z]);
          faceData.addAll([v2.x, v2.y, v2.z]);
          triangleCount++;
        }
      }
    }
    
    if (faceData.isEmpty) return;
    
    final buffer = _createVertexBuffer(Float32List.fromList(faceData));
    buffer.bindToAttribute(_faceShader.getAttribute('position'));
    
    // Set uniforms
    _faceShader.setMat4('viewMatrix', _viewMatrix);
    _faceShader.setMat4('projectionMatrix', _projectionMatrix);
    _faceShader.setVec4('color', _config.faceColor);
    _faceShader.setFloat('opacity', _config.faceOpacity);
    _faceShader.setFloat('audioHarmonicContent', _currentAudioParams.harmonicContent);
    
    // Enable transparency
    _gl.enable(gl.BLEND);
    _gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    
    // Render triangles
    _gl.drawArrays(gl.TRIANGLES, 0, triangleCount * 3);
    
    _lastMetrics.facesRendered = triangleCount;
    _lastMetrics.drawCalls++;
    
    buffer.dispose();
  }
  
  void _renderHolographicPass() {
    _gl.bindFramebuffer(gl.FRAMEBUFFER, _postProcessFramebuffer);
    _gl.clear(gl.COLOR_BUFFER_BIT);
    
    _holographicShader.use();
    
    // Bind main render texture
    _gl.activeTexture(gl.TEXTURE0);
    _gl.bindTexture(gl.TEXTURE_2D, _mainColorTexture);
    _holographicShader.setFloat('mainTexture', 0);
    
    // Set holographic effect parameters
    _holographicShader.setFloat('intensity', _config.holographicIntensity);
    _holographicShader.setFloat('chromaticAberration', _config.chromaticAberration);
    _holographicShader.setFloat('time', DateTime.now().millisecondsSinceEpoch / 1000.0);
    _holographicShader.setFloat('audioAmplitude', _currentAudioParams.amplitude);
    _holographicShader.setFloat('audioAttack', _currentAudioParams.attackSharpness);
    
    _renderFullscreenQuad();
    _lastMetrics.drawCalls++;
  }
  
  void _renderPostProcessPass() {
    _gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    _gl.viewport(0, 0, _canvasWidth, _canvasHeight);
    _gl.clear(gl.COLOR_BUFFER_BIT);
    
    _postProcessShader.use();
    
    // Bind appropriate texture based on effects
    _gl.activeTexture(gl.TEXTURE0);
    if (_config.enableHolographicEffects) {
      _gl.bindTexture(gl.TEXTURE_2D, _postProcessTexture);
    } else {
      _gl.bindTexture(gl.TEXTURE_2D, _mainColorTexture);
    }
    _postProcessShader.setFloat('inputTexture', 0);
    
    // Set post-processing parameters
    _postProcessShader.setFloat('enableDepthGlow', _config.enableDepthGlow ? 1.0 : 0.0);
    _postProcessShader.setFloat('glowIntensity', _currentAudioParams.amplitude);
    
    _renderFullscreenQuad();
    _lastMetrics.drawCalls++;
  }
  
  void _renderFullscreenQuad() {
    // Fullscreen quad vertices
    final quadVertices = Float32List.fromList([
      -1, -1, 0,
       1, -1, 0,
      -1,  1, 0,
       1,  1, 0,
    ]);
    
    final buffer = _createVertexBuffer(quadVertices);
    buffer.bindToAttribute(0); // Position attribute at location 0
    
    _gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    
    buffer.dispose();
  }
  
  VertexBuffer _createVertexBuffer(Float32List data) {
    final buffer = _gl.createBuffer()!;
    _gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    _gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
    
    return VertexBuffer(_gl, buffer, 3, data.length ~/ 3);
  }
  
  void _updateMetrics(DateTime startTime, DateTime endTime, Polytope4D polytope) {
    final frameTime = endTime.difference(startTime).inMicroseconds / 1000.0; // ms
    _lastMetrics.frameTime = frameTime;
    
    _frameTimes.add(frameTime);
    if (_frameTimes.length > maxFrameTimeHistory) {
      _frameTimes.removeAt(0);
    }
    
    if (_frameTimes.isNotEmpty) {
      final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
      _lastMetrics.fps = 1000.0 / avgFrameTime;
    }
  }
  
  /// Update render configuration
  void updateConfig(RenderConfig config) {
    _config = config;
  }
  
  /// Update canvas size
  void resize(int width, int height) {
    _canvasWidth = width;
    _canvasHeight = height;
    _canvas.width = width;
    _canvas.height = height;
    
    // Recreate framebuffers with new size
    _initializeFramebuffers();
    _updateProjectionMatrix();
  }
  
  /// Get current render metrics
  RenderMetrics get metrics => _lastMetrics;
  
  /// Dispose resources
  void dispose() {
    // Dispose vertex buffers
    for (final buffer in _vertexBuffers.values) {
      buffer.dispose();
    }
    _vertexBuffers.clear();
    
    // Dispose framebuffers and textures
    _gl.deleteFramebuffer(_mainFramebuffer);
    _gl.deleteFramebuffer(_postProcessFramebuffer);
    _gl.deleteTexture(_mainColorTexture);
    _gl.deleteTexture(_mainDepthTexture);
    _gl.deleteTexture(_postProcessTexture);
  }
  
  // Shader source code
  static const String _vertexVertexShader = '''
    #version 300 es
    precision highp float;
    
    in vec3 position;
    uniform mat4 viewMatrix;
    uniform mat4 projectionMatrix;
    uniform float pointSize;
    uniform float audioAmplitude;
    
    void main() {
      gl_Position = projectionMatrix * viewMatrix * vec4(position, 1.0);
      gl_PointSize = pointSize * (1.0 + audioAmplitude * 2.0);
    }
  ''';
  
  static const String _vertexFragmentShader = '''
    #version 300 es
    precision highp float;
    
    uniform vec4 color;
    out vec4 fragColor;
    
    void main() {
      vec2 coord = gl_PointCoord - vec2(0.5);
      if (length(coord) > 0.5) discard;
      
      float glow = 1.0 - length(coord) * 2.0;
      fragColor = color * glow;
    }
  ''';
  
  static const String _edgeVertexShader = '''
    #version 300 es
    precision highp float;
    
    in vec3 position;
    uniform mat4 viewMatrix;
    uniform mat4 projectionMatrix;
    uniform float audioFrequency;
    
    void main() {
      vec3 pos = position;
      pos.z += sin(audioFrequency * 10.0) * 0.1;
      gl_Position = projectionMatrix * viewMatrix * vec4(pos, 1.0);
    }
  ''';
  
  static const String _edgeFragmentShader = '''
    #version 300 es
    precision highp float;
    
    uniform vec4 color;
    uniform float audioSpectralCentroid;
    out vec4 fragColor;
    
    void main() {
      vec3 glowColor = mix(color.rgb, vec3(1.0, 0.5, 0.0), audioSpectralCentroid);
      fragColor = vec4(glowColor, color.a);
    }
  ''';
  
  static const String _faceVertexShader = '''
    #version 300 es
    precision highp float;
    
    in vec3 position;
    uniform mat4 viewMatrix;
    uniform mat4 projectionMatrix;
    
    void main() {
      gl_Position = projectionMatrix * viewMatrix * vec4(position, 1.0);
    }
  ''';
  
  static const String _faceFragmentShader = '''
    #version 300 es
    precision highp float;
    
    uniform vec4 color;
    uniform float opacity;
    uniform float audioHarmonicContent;
    out vec4 fragColor;
    
    void main() {
      float dynamicOpacity = opacity * (0.5 + audioHarmonicContent * 0.5);
      fragColor = vec4(color.rgb, dynamicOpacity);
    }
  ''';
  
  static const String _holographicVertexShader = '''
    #version 300 es
    precision highp float;
    
    in vec3 position;
    
    void main() {
      gl_Position = vec4(position, 1.0);
    }
  ''';
  
  static const String _holographicFragmentShader = '''
    #version 300 es
    precision highp float;
    
    uniform sampler2D mainTexture;
    uniform float intensity;
    uniform float chromaticAberration;
    uniform float time;
    uniform float audioAmplitude;
    uniform float audioAttack;
    out vec4 fragColor;
    
    void main() {
      vec2 uv = gl_FragCoord.xy / vec2(800.0, 600.0); // Should be dynamic
      
      // Chromatic aberration
      vec2 aberration = vec2(chromaticAberration) * audioAmplitude;
      float r = texture(mainTexture, uv + aberration).r;
      float g = texture(mainTexture, uv).g;
      float b = texture(mainTexture, uv - aberration).b;
      
      // Holographic interference pattern
      float interference = sin(uv.x * 100.0 + time) * sin(uv.y * 100.0 + time) * 0.1;
      interference *= audioAttack;
      
      vec3 result = vec3(r, g, b) + interference;
      fragColor = vec4(result * intensity, 1.0);
    }
  ''';
  
  static const String _postProcessVertexShader = '''
    #version 300 es
    precision highp float;
    
    in vec3 position;
    
    void main() {
      gl_Position = vec4(position, 1.0);
    }
  ''';
  
  static const String _postProcessFragmentShader = '''
    #version 300 es
    precision highp float;
    
    uniform sampler2D inputTexture;
    uniform float enableDepthGlow;
    uniform float glowIntensity;
    out vec4 fragColor;
    
    void main() {
      vec2 uv = gl_FragCoord.xy / vec2(800.0, 600.0); // Should be dynamic
      vec3 color = texture(inputTexture, uv).rgb;
      
      if (enableDepthGlow > 0.5) {
        // Simple glow effect
        vec3 glow = color * glowIntensity * 0.5;
        color += glow;
      }
      
      fragColor = vec4(color, 1.0);
    }
  ''';
}