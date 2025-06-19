// Platform stub for html elements on non-web platforms

class CanvasElement {
  int width = 0;
  int height = 0;
  String id = '';
  late Style style = Style();
  
  CanvasElement();
}

class Style {
  String width = '';
  String height = '';
  String position = '';
  String top = '';
  String left = '';
  String zIndex = '';
}