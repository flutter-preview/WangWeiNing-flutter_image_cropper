import 'package:flutter/material.dart';
import 'package:flutter_image_cropper/src/drawing_data.dart';

class CropperPainter extends CustomPainter {
  
  CropperDrawingData data;

  CropperPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(data.viewRect);
    paintImage(canvas);
    paintMask(canvas);
    paintCropArea(canvas);
  }

  void paintCropArea(Canvas canvas) {
    canvas.drawRect(
        data.croppingRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    canvas.clipRect(
      data.croppingRect,
      doAntiAlias: false,
    );

    // draw lines
    double verticalSpace = (data.croppingRect.height / 3);
    canvas.drawLine(
        Offset(data.croppingRect.left, data.croppingRect.top + verticalSpace),
        Offset(data.croppingRect.right, data.croppingRect.top + verticalSpace),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    canvas.drawLine(
        Offset(data.croppingRect.left, data.croppingRect.top + verticalSpace * 2),
        Offset(data.croppingRect.right, data.croppingRect.top + verticalSpace * 2),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    double horizontalSpace = data.croppingRect.width / 3;

    canvas.drawLine(
        Offset(horizontalSpace + data.croppingRect.left, data.croppingRect.top),
        Offset(horizontalSpace + data.croppingRect.left, data.croppingRect.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    canvas.drawLine(
        Offset(horizontalSpace * 2 + data.croppingRect.left, data.croppingRect.top),
        Offset(horizontalSpace * 2 + data.croppingRect.left, data.croppingRect.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);
  }


  void paintMask(Canvas canvas) {
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, data.viewRect.width, data.viewRect.height),
        Paint()..blendMode = BlendMode.xor);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, data.viewRect.width, data.viewRect.height),
        Paint()..color = const Color.fromARGB(133, 0, 0, 0));

    canvas.drawRect(data.croppingRect, Paint()..blendMode = BlendMode.clear);

    canvas.restore();
  }


  void paintImage(Canvas canvas) {

    var src = Rect.fromLTWH(0, 0, data.image.width.toDouble(), data.image.height.toDouble());
    canvas.drawImageRect(data.image, src, data.imageRect, Paint());
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
