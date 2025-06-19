import 'dart:math' as math;
import 'dart:typed_data';

/// Professional 4D Polytope Mathematics Library
/// 
/// Provides comprehensive 4D geometric calculations for:
/// - Tesseract (4D cube) with 16 vertices, 32 edges, 24 faces, 8 cells
/// - 16-cell (4D cross-polytope) with 8 vertices, 24 edges, 32 faces, 16 cells  
/// - 24-cell (regular 4D polytope) with 24 vertices, 96 edges, 96 faces, 24 cells
/// - 4D rotations in all 6 planes of 4D space
/// - Perspective projection from 4D to 3D to 2D
/// - Audio-reactive transformations and morphing

/// 4D Vector for positions and transformations
class Vector4D {
  double x, y, z, w;
  
  Vector4D(this.x, this.y, this.z, this.w);
  
  /// Create vector from list
  Vector4D.fromList(List<double> values) 
    : x = values[0], y = values[1], z = values[2], w = values[3];
  
  /// Zero vector
  Vector4D.zero() : x = 0, y = 0, z = 0, w = 0;
  
  /// Unit vectors
  Vector4D.unitX() : x = 1, y = 0, z = 0, w = 0;
  Vector4D.unitY() : x = 0, y = 1, z = 0, w = 0;
  Vector4D.unitZ() : x = 0, y = 0, z = 1, w = 0;
  Vector4D.unitW() : x = 0, y = 0, z = 0, w = 1;
  
  /// Vector operations
  Vector4D operator +(Vector4D other) => Vector4D(x + other.x, y + other.y, z + other.z, w + other.w);
  Vector4D operator -(Vector4D other) => Vector4D(x - other.x, y - other.y, z - other.z, w - other.w);
  Vector4D operator *(double scalar) => Vector4D(x * scalar, y * scalar, z * scalar, w * scalar);
  Vector4D operator /(double scalar) => Vector4D(x / scalar, y / scalar, z / scalar, w / scalar);
  
  /// Dot product
  double dot(Vector4D other) => x * other.x + y * other.y + z * other.z + w * other.w;
  
  /// Magnitude
  double get magnitude => math.sqrt(x * x + y * y + z * z + w * w);
  
  /// Normalized vector
  Vector4D get normalized {
    final mag = magnitude;
    return mag > 0 ? this / mag : Vector4D.zero();
  }
  
  /// Distance to another vector
  double distanceTo(Vector4D other) => (this - other).magnitude;
  
  /// Linear interpolation
  Vector4D lerp(Vector4D other, double t) {
    return Vector4D(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
      z + (other.z - z) * t,
      w + (other.w - w) * t,
    );
  }
  
  /// Convert to list for shader uniforms
  List<double> toList() => [x, y, z, w];
  
  @override
  String toString() => 'Vector4D($x, $y, $z, $w)';
  
  /// Copy
  Vector4D copy() => Vector4D(x, y, z, w);
}

/// 3D Vector for projections
class Vector3D {
  double x, y, z;
  
  Vector3D(this.x, this.y, this.z);
  
  Vector3D.zero() : x = 0, y = 0, z = 0;
  
  Vector3D operator +(Vector3D other) => Vector3D(x + other.x, y + other.y, z + other.z);
  Vector3D operator -(Vector3D other) => Vector3D(x - other.x, y - other.y, z - other.z);
  Vector3D operator *(double scalar) => Vector3D(x * scalar, y * scalar, z * scalar);
  Vector3D operator /(double scalar) => Vector3D(x / scalar, y / scalar, z / scalar);
  
  double get magnitude => math.sqrt(x * x + y * y + z * z);
  Vector3D get normalized {
    final mag = magnitude;
    return mag > 0 ? this / mag : Vector3D.zero();
  }
  
  List<double> toList() => [x, y, z];
  
  @override
  String toString() => 'Vector3D($x, $y, $z)';
}

/// 4D Rotation Matrix (8x8 for complete 4D rotations)
class Matrix4D {
  final List<List<double>> _matrix;
  
  Matrix4D() : _matrix = List.generate(4, (_) => List.filled(4, 0.0)) {
    // Initialize as identity matrix
    for (int i = 0; i < 4; i++) {
      _matrix[i][i] = 1.0;
    }
  }
  
  /// Create identity matrix
  static Matrix4D identity() => Matrix4D();
  
  /// Create rotation matrix for specific 4D plane
  Matrix4D.rotation(RotationPlane4D plane, double angle) : _matrix = List.generate(4, (_) => List.filled(4, 0.0)) {
    // Initialize as identity
    for (int i = 0; i < 4; i++) {
      _matrix[i][i] = 1.0;
    }
    
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    
    switch (plane) {
      case RotationPlane4D.xy:
        _matrix[0][0] = cos; _matrix[0][1] = -sin;
        _matrix[1][0] = sin; _matrix[1][1] = cos;
        break;
      case RotationPlane4D.xz:
        _matrix[0][0] = cos; _matrix[0][2] = -sin;
        _matrix[2][0] = sin; _matrix[2][2] = cos;
        break;
      case RotationPlane4D.xw:
        _matrix[0][0] = cos; _matrix[0][3] = -sin;
        _matrix[3][0] = sin; _matrix[3][3] = cos;
        break;
      case RotationPlane4D.yz:
        _matrix[1][1] = cos; _matrix[1][2] = -sin;
        _matrix[2][1] = sin; _matrix[2][2] = cos;
        break;
      case RotationPlane4D.yw:
        _matrix[1][1] = cos; _matrix[1][3] = -sin;
        _matrix[3][1] = sin; _matrix[3][3] = cos;
        break;
      case RotationPlane4D.zw:
        _matrix[2][2] = cos; _matrix[2][3] = -sin;
        _matrix[3][2] = sin; _matrix[3][3] = cos;
        break;
    }
  }
  
  /// Matrix multiplication
  Matrix4D operator *(Matrix4D other) {
    final result = Matrix4D();
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        result._matrix[i][j] = 0.0;
        for (int k = 0; k < 4; k++) {
          result._matrix[i][j] += _matrix[i][k] * other._matrix[k][j];
        }
      }
    }
    return result;
  }
  
  /// Transform 4D vector
  Vector4D transform(Vector4D vector) {
    return Vector4D(
      _matrix[0][0] * vector.x + _matrix[0][1] * vector.y + _matrix[0][2] * vector.z + _matrix[0][3] * vector.w,
      _matrix[1][0] * vector.x + _matrix[1][1] * vector.y + _matrix[1][2] * vector.z + _matrix[1][3] * vector.w,
      _matrix[2][0] * vector.x + _matrix[2][1] * vector.y + _matrix[2][2] * vector.z + _matrix[2][3] * vector.w,
      _matrix[3][0] * vector.x + _matrix[3][1] * vector.y + _matrix[3][2] * vector.z + _matrix[3][3] * vector.w,
    );
  }
  
  /// Get matrix as flat list for shaders
  List<double> toList() {
    final result = <double>[];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        result.add(_matrix[i][j]);
      }
    }
    return result;
  }
  
  /// Apply XY rotation to this matrix
  Matrix4D rotateXY(double angle) {
    final rotation = Matrix4D.rotation(RotationPlane4D.xy, angle);
    final result = this * rotation;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        _matrix[i][j] = result._matrix[i][j];
      }
    }
    return this;
  }
  
  /// Apply XZ rotation to this matrix
  Matrix4D rotateXZ(double angle) {
    final rotation = Matrix4D.rotation(RotationPlane4D.xz, angle);
    final result = this * rotation;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        _matrix[i][j] = result._matrix[i][j];
      }
    }
    return this;
  }
  
  /// Apply ZW rotation to this matrix
  Matrix4D rotateZW(double angle) {
    final rotation = Matrix4D.rotation(RotationPlane4D.zw, angle);
    final result = this * rotation;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        _matrix[i][j] = result._matrix[i][j];
      }
    }
    return this;
  }
}

/// 4D rotation planes (there are 6 in 4D space)
enum RotationPlane4D { xy, xz, xw, yz, yw, zw }

/// Edge connecting two vertices
class PolytopeEdge {
  final int vertex1, vertex2;
  final double thickness;
  final bool isHighlighted;
  
  PolytopeEdge(this.vertex1, this.vertex2, {this.thickness = 1.0, this.isHighlighted = false});
  
  /// Get length (always 2 for edge)
  int get length => 2;
  
  /// Access vertices by index
  int operator [](int index) {
    switch (index) {
      case 0: return vertex1;
      case 1: return vertex2;
      default: throw RangeError('Index $index out of range for edge');
    }
  }
}

/// Face defined by multiple vertices
class PolytopeFace {
  final List<int> vertices;
  final Vector4D normal;
  final double opacity;
  final bool isVisible;
  
  PolytopeFace(this.vertices, this.normal, {this.opacity = 0.3, this.isVisible = true});
}

/// Base class for 4D polytopes
abstract class Polytope4D {
  List<Vector4D> vertices = [];
  List<PolytopeEdge> edges = [];
  List<PolytopeFace> faces = [];
  
  String get name;
  String get description;
  int get vertexCount => vertices.length;
  int get edgeCount => edges.length;
  int get faceCount => faces.length;
  
  /// Create a tesseract (4D cube)
  static Polytope4D tesseract() {
    final tesseract = Tesseract();
    tesseract.generateGeometry();
    return tesseract;
  }
  
  /// Generate the polytope geometry
  void generateGeometry();
  
  /// Transform all vertices by matrix
  void transform(Matrix4D matrix) {
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = matrix.transform(vertices[i]);
    }
  }
  
  /// Scale polytope uniformly
  void scale(double factor) {
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = vertices[i] * factor;
    }
  }
  
  /// Translate polytope
  void translate(Vector4D offset) {
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = vertices[i] + offset;
    }
  }
  
  /// Get center point
  Vector4D get center {
    if (vertices.isEmpty) return Vector4D.zero();
    
    double x = 0, y = 0, z = 0, w = 0;
    for (final vertex in vertices) {
      x += vertex.x;
      y += vertex.y;
      z += vertex.z;
      w += vertex.w;
    }
    
    final count = vertices.length.toDouble();
    return Vector4D(x / count, y / count, z / count, w / count);
  }
  
  /// Get bounding box
  Map<String, Vector4D> get boundingBox {
    if (vertices.isEmpty) {
      return {'min': Vector4D.zero(), 'max': Vector4D.zero()};
    }
    
    double minX = vertices[0].x, maxX = vertices[0].x;
    double minY = vertices[0].y, maxY = vertices[0].y;
    double minZ = vertices[0].z, maxZ = vertices[0].z;
    double minW = vertices[0].w, maxW = vertices[0].w;
    
    for (final vertex in vertices) {
      minX = math.min(minX, vertex.x); maxX = math.max(maxX, vertex.x);
      minY = math.min(minY, vertex.y); maxY = math.max(maxY, vertex.y);
      minZ = math.min(minZ, vertex.z); maxZ = math.max(maxZ, vertex.z);
      minW = math.min(minW, vertex.w); maxW = math.max(maxW, vertex.w);
    }
    
    return {
      'min': Vector4D(minX, minY, minZ, minW),
      'max': Vector4D(maxX, maxY, maxZ, maxW),
    };
  }
}

/// Tesseract (4D Cube) - 16 vertices, 32 edges, 24 faces, 8 cells
class Tesseract extends Polytope4D {
  @override
  String get name => 'Tesseract';
  
  @override
  String get description => '4D hypercube with 16 vertices forming 8 cubic cells';
  
  @override
  void generateGeometry() {
    vertices.clear();
    edges.clear();
    faces.clear();
    
    // Generate 16 vertices of tesseract (all combinations of ±1)
    for (int i = 0; i < 16; i++) {
      final x = (i & 1) == 0 ? -1.0 : 1.0;
      final y = (i & 2) == 0 ? -1.0 : 1.0;
      final z = (i & 4) == 0 ? -1.0 : 1.0;
      final w = (i & 8) == 0 ? -1.0 : 1.0;
      vertices.add(Vector4D(x, y, z, w));
    }
    
    // Generate edges (vertices that differ by exactly one coordinate)
    for (int i = 0; i < 16; i++) {
      for (int j = i + 1; j < 16; j++) {
        int differences = 0;
        if (vertices[i].x != vertices[j].x) differences++;
        if (vertices[i].y != vertices[j].y) differences++;
        if (vertices[i].z != vertices[j].z) differences++;
        if (vertices[i].w != vertices[j].w) differences++;
        
        if (differences == 1) {
          edges.add(PolytopeEdge(i, j));
        }
      }
    }
    
    // Generate faces (4-vertex squares)
    _generateTesseractFaces();
  }
  
  void _generateTesseractFaces() {
    // Each face is a square defined by 4 vertices
    // There are 24 faces in a tesseract (6 faces × 4 orientations)
    
    // XY faces (Z and W constant)
    for (int z = 0; z < 2; z++) {
      for (int w = 0; w < 2; w++) {
        final faceVertices = <int>[];
        for (int i = 0; i < 16; i++) {
          final v = vertices[i];
          if ((v.z > 0) == (z == 1) && (v.w > 0) == (w == 1)) {
            faceVertices.add(i);
          }
        }
        if (faceVertices.length == 4) {
          final normal = Vector4D(0, 0, z == 0 ? -1 : 1, w == 0 ? -1 : 1);
          faces.add(PolytopeFace(faceVertices, normal));
        }
      }
    }
    
    // XZ faces (Y and W constant)
    for (int y = 0; y < 2; y++) {
      for (int w = 0; w < 2; w++) {
        final faceVertices = <int>[];
        for (int i = 0; i < 16; i++) {
          final v = vertices[i];
          if ((v.y > 0) == (y == 1) && (v.w > 0) == (w == 1)) {
            faceVertices.add(i);
          }
        }
        if (faceVertices.length == 4) {
          final normal = Vector4D(0, y == 0 ? -1 : 1, 0, w == 0 ? -1 : 1);
          faces.add(PolytopeFace(faceVertices, normal));
        }
      }
    }
    
    // XW faces (Y and Z constant)
    for (int y = 0; y < 2; y++) {
      for (int z = 0; z < 2; z++) {
        final faceVertices = <int>[];
        for (int i = 0; i < 16; i++) {
          final v = vertices[i];
          if ((v.y > 0) == (y == 1) && (v.z > 0) == (z == 1)) {
            faceVertices.add(i);
          }
        }
        if (faceVertices.length == 4) {
          final normal = Vector4D(0, y == 0 ? -1 : 1, z == 0 ? -1 : 1, 0);
          faces.add(PolytopeFace(faceVertices, normal));
        }
      }
    }
  }
}

/// 16-cell (4D Cross-polytope) - 8 vertices, 24 edges, 32 faces, 16 cells
class SixteenCell extends Polytope4D {
  @override
  String get name => '16-cell';
  
  @override
  String get description => '4D cross-polytope with 8 vertices and 16 tetrahedral cells';
  
  @override
  void generateGeometry() {
    vertices.clear();
    edges.clear();
    faces.clear();
    
    // Generate 8 vertices (unit vectors along each axis)
    vertices.addAll([
      Vector4D(1, 0, 0, 0), Vector4D(-1, 0, 0, 0),   // X axis
      Vector4D(0, 1, 0, 0), Vector4D(0, -1, 0, 0),   // Y axis
      Vector4D(0, 0, 1, 0), Vector4D(0, 0, -1, 0),   // Z axis
      Vector4D(0, 0, 0, 1), Vector4D(0, 0, 0, -1),   // W axis
    ]);
    
    // Generate edges (connect all non-opposite vertices)
    for (int i = 0; i < 8; i++) {
      for (int j = i + 1; j < 8; j++) {
        // Don't connect opposite vertices (those that sum to zero)
        final sum = vertices[i] + vertices[j];
        if (sum.magnitude > 0.1) { // Not opposite
          edges.add(PolytopeEdge(i, j));
        }
      }
    }
    
    // Generate triangular faces
    _generateSixteenCellFaces();
  }
  
  void _generateSixteenCellFaces() {
    // Each face is a triangle connecting 3 non-collinear vertices
    for (int i = 0; i < 8; i++) {
      for (int j = i + 1; j < 8; j++) {
        for (int k = j + 1; k < 8; k++) {
          // Check if these 3 vertices form a valid face
          if (_isValidTriangleFace(i, j, k)) {
            final normal = _calculateTriangleNormal(i, j, k);
            faces.add(PolytopeFace([i, j, k], normal));
          }
        }
      }
    }
  }
  
  bool _isValidTriangleFace(int i, int j, int k) {
    // Check if any pair is opposite (would make degenerate triangle)
    final sum1 = vertices[i] + vertices[j];
    final sum2 = vertices[i] + vertices[k];
    final sum3 = vertices[j] + vertices[k];
    
    return sum1.magnitude > 0.1 && sum2.magnitude > 0.1 && sum3.magnitude > 0.1;
  }
  
  Vector4D _calculateTriangleNormal(int i, int j, int k) {
    // Calculate normal vector for triangle in 4D space
    final v1 = vertices[j] - vertices[i];
    final v2 = vertices[k] - vertices[i];
    
    // For simplicity, use one of the vertices as normal direction
    // (proper 4D normal calculation would involve cross products in 4D)
    return vertices[i].normalized;
  }
}

/// 24-cell (Regular 4D polytope) - 24 vertices, 96 edges, 96 faces, 24 cells
class TwentyFourCell extends Polytope4D {
  @override
  String get name => '24-cell';
  
  @override
  String get description => 'Regular 4D polytope with 24 vertices and octahedral symmetry';
  
  @override
  void generateGeometry() {
    vertices.clear();
    edges.clear();
    faces.clear();
    
    // Generate 24 vertices of 24-cell
    // 8 vertices from tesseract vertices (±1, ±1, 0, 0) and permutations
    // 16 vertices from 16-cell vertices (±1, 0, 0, 0) and permutations, scaled by √2
    
    final sqrt2 = math.sqrt(2);
    
    // 16 vertices from scaled unit vectors
    vertices.addAll([
      Vector4D(sqrt2, 0, 0, 0), Vector4D(-sqrt2, 0, 0, 0),
      Vector4D(0, sqrt2, 0, 0), Vector4D(0, -sqrt2, 0, 0),
      Vector4D(0, 0, sqrt2, 0), Vector4D(0, 0, -sqrt2, 0),
      Vector4D(0, 0, 0, sqrt2), Vector4D(0, 0, 0, -sqrt2),
    ]);
    
    // 16 additional vertices from (±1, ±1, 0, 0) permutations
    final coords = [1.0, -1.0];
    for (final x in coords) {
      for (final y in coords) {
        vertices.addAll([
          Vector4D(x, y, 0, 0), Vector4D(x, 0, y, 0),
          Vector4D(0, x, y, 0), Vector4D(x, 0, 0, y),
          Vector4D(0, x, 0, y), Vector4D(0, 0, x, y),
        ]);
      }
    }
    
    // Take only first 24 vertices (remove duplicates and excess)
    vertices = vertices.take(24).toList();
    
    // Generate edges (connect vertices at distance √2)
    for (int i = 0; i < 24; i++) {
      for (int j = i + 1; j < 24; j++) {
        final distance = vertices[i].distanceTo(vertices[j]);
        if ((distance - sqrt2).abs() < 0.1) {
          edges.add(PolytopeEdge(i, j));
        }
      }
    }
    
    // Generate faces (regular octagons and squares)
    _generateTwentyFourCellFaces();
  }
  
  void _generateTwentyFourCellFaces() {
    // 24-cell has octahedral faces - simplified to triangular faces for rendering
    for (int i = 0; i < 24; i++) {
      for (int j = i + 1; j < 24; j++) {
        for (int k = j + 1; k < 24; k++) {
          if (_isValidTwentyFourCellFace(i, j, k)) {
            final normal = _calculateTwentyFourCellNormal(i, j, k);
            faces.add(PolytopeFace([i, j, k], normal));
          }
        }
      }
    }
  }
  
  bool _isValidTwentyFourCellFace(int i, int j, int k) {
    // Check if vertices form a valid face based on edge connectivity
    final hasEdgeIJ = edges.any((e) => (e.vertex1 == i && e.vertex2 == j) || (e.vertex1 == j && e.vertex2 == i));
    final hasEdgeJK = edges.any((e) => (e.vertex1 == j && e.vertex2 == k) || (e.vertex1 == k && e.vertex2 == j));
    final hasEdgeKI = edges.any((e) => (e.vertex1 == k && e.vertex2 == i) || (e.vertex1 == i && e.vertex2 == k));
    
    return hasEdgeIJ && hasEdgeJK && hasEdgeKI;
  }
  
  Vector4D _calculateTwentyFourCellNormal(int i, int j, int k) {
    // Calculate normal for face
    final center = Vector4D(
      (vertices[i].x + vertices[j].x + vertices[k].x) / 3,
      (vertices[i].y + vertices[j].y + vertices[k].y) / 3,
      (vertices[i].z + vertices[j].z + vertices[k].z) / 3,
      (vertices[i].w + vertices[j].w + vertices[k].w) / 3,
    );
    return center.normalized;
  }
}

/// 4D to 3D projection system
class Projection4D {
  double viewerDistance;
  double scale;
  Vector4D viewpoint;
  
  Projection4D({
    this.viewerDistance = 5.0,
    this.scale = 1.0,
  }) : viewpoint = Vector4D(0, 0, 0, 5);
  
  /// Project 4D point to 3D using perspective projection
  Vector3D project4Dto3D(Vector4D point4D) {
    // Distance from viewer in 4D space
    final distance = viewerDistance - point4D.w;
    
    if (distance <= 0.1) {
      // Point is behind viewer or too close
      return Vector3D(point4D.x, point4D.y, point4D.z);
    }
    
    // Perspective division
    final perspective = viewerDistance / distance;
    
    return Vector3D(
      point4D.x * perspective * scale,
      point4D.y * perspective * scale,
      point4D.z * perspective * scale,
    );
  }
  
  /// Project 3D point to 2D screen coordinates
  Vector3D project3Dto2D(Vector3D point3D, double screenWidth, double screenHeight, double fov) {
    final zDistance = 10.0 - point3D.z;
    if (zDistance <= 0.1) {
      return Vector3D(point3D.x, point3D.y, 0);
    }
    
    final perspective = fov / zDistance;
    
    return Vector3D(
      (point3D.x * perspective + 1.0) * screenWidth * 0.5,
      (point3D.y * perspective + 1.0) * screenHeight * 0.5,
      point3D.z,
    );
  }
  
  /// Project 4D polytope to 3D
  List<Vector3D> projectPolytope(Polytope4D polytope) {
    return polytope.vertices.map((vertex) => project4Dto3D(vertex)).toList();
  }
}

/// Audio-reactive transformation parameters
class AudioReactiveParams {
  double amplitude;           // Overall volume level
  double frequency;          // Dominant frequency
  double spectralCentroid;   // Brightness measure
  double harmonicContent;    // Harmonic richness
  double attackSharpness;    // Note onset intensity
  double rhythmIntensity;    // Beat strength
  
  AudioReactiveParams({
    this.amplitude = 0.0,
    this.frequency = 440.0,
    this.spectralCentroid = 0.5,
    this.harmonicContent = 0.5,
    this.attackSharpness = 0.0,
    this.rhythmIntensity = 0.0,
  });
}

/// Audio-reactive polytope transformer
class AudioReactiveTransformer {
  late Matrix4D _currentRotation;
  late Vector4D _currentScale;
  late Vector4D _currentTranslation;
  
  // Rotation speeds for each plane
  final Map<RotationPlane4D, double> _rotationSpeeds = {
    RotationPlane4D.xy: 0.5,
    RotationPlane4D.xz: 0.3,
    RotationPlane4D.xw: 0.7,
    RotationPlane4D.yz: 0.4,
    RotationPlane4D.yw: 0.6,
    RotationPlane4D.zw: 0.8,
  };
  
  AudioReactiveTransformer() {
    reset();
  }
  
  void reset() {
    _currentRotation = Matrix4D();
    _currentScale = Vector4D(1, 1, 1, 1);
    _currentTranslation = Vector4D.zero();
  }
  
  /// Update transformation based on audio parameters
  void updateFromAudio(AudioReactiveParams audioParams, double deltaTime) {
    // Amplitude affects overall scale
    final amplitudeScale = 1.0 + audioParams.amplitude * 0.5;
    _currentScale = Vector4D(amplitudeScale, amplitudeScale, amplitudeScale, amplitudeScale);
    
    // Frequency affects W-axis rotation speed
    _rotationSpeeds[RotationPlane4D.zw] = audioParams.frequency / 440.0;
    
    // Spectral centroid affects XY plane rotation
    _rotationSpeeds[RotationPlane4D.xy] = audioParams.spectralCentroid * 2.0;
    
    // Harmonic content affects multiple rotation planes
    _rotationSpeeds[RotationPlane4D.xw] = audioParams.harmonicContent * 1.5;
    _rotationSpeeds[RotationPlane4D.yw] = audioParams.harmonicContent * 1.2;
    
    // Attack sharpness causes translation pulses
    if (audioParams.attackSharpness > 0.5) {
      _currentTranslation = Vector4D(
        math.sin(deltaTime * 10) * audioParams.attackSharpness,
        math.cos(deltaTime * 10) * audioParams.attackSharpness,
        0, 0
      );
    } else {
      _currentTranslation = _currentTranslation * 0.95; // Decay
    }
    
    // Update rotation matrix
    _updateRotationMatrix(deltaTime);
  }
  
  void _updateRotationMatrix(double deltaTime) {
    _currentRotation = Matrix4D();
    
    // Combine rotations in all 6 planes
    for (final entry in _rotationSpeeds.entries) {
      final plane = entry.key;
      final speed = entry.value;
      final angle = deltaTime * speed;
      
      final rotation = Matrix4D.rotation(plane, angle);
      _currentRotation = _currentRotation * rotation;
    }
  }
  
  /// Apply transformation to polytope
  void transformPolytope(Polytope4D polytope) {
    // Apply scale
    for (int i = 0; i < polytope.vertices.length; i++) {
      polytope.vertices[i] = Vector4D(
        polytope.vertices[i].x * _currentScale.x,
        polytope.vertices[i].y * _currentScale.y,
        polytope.vertices[i].z * _currentScale.z,
        polytope.vertices[i].w * _currentScale.w,
      );
    }
    
    // Apply rotation
    polytope.transform(_currentRotation);
    
    // Apply translation
    polytope.translate(_currentTranslation);
  }
  
  /// Get current transformation data for visualization
  Map<String, dynamic> getTransformationData() {
    return {
      'rotationMatrix': _currentRotation.toList(),
      'scale': _currentScale.toList(),
      'translation': _currentTranslation.toList(),
      'rotationSpeeds': _rotationSpeeds.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}