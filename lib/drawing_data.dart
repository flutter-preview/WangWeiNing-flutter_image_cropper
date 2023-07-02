import 'dart:ui';

class CropperDrawingData {
  Rect viewRect;
  Rect imageRect;
  Rect croppingRect;
  Image image;

  CropperDrawingData({
    required this.viewRect,
    required this.imageRect,
    required this.croppingRect,
    required this.image
  });

}