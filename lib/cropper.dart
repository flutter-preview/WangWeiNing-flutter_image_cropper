import 'package:flutter/material.dart';
import "controller.dart";
import "package:image/image.dart" as image;
import "calculator.dart";
import "drawing_data.dart";
import "painter.dart";
import 'dart:math' as math;
import "dart:ui" as ui;


class ImageCropper extends StatefulWidget {


  const ImageCropper({
    super.key, 
    required this.image,
    required this.controller,
    required this.onCropped,
    required this.viewSize,
    this.aspectRatio = 4 / 3,
  });

  final Function(ui.Image image) onCropped;
  final ui.Image image;
  final CropperController controller;
  final double aspectRatio;
  final Size viewSize;


  @override
  State<StatefulWidget> createState() => ImageCropperState();
}

class ImageCropperState extends State<ImageCropper> {

  Offset _lastFocalPoint = Offset.zero;
  double _initialScale = 1.0;
  int _fingersOnScreen = 0;

  late CropperDrawingData _data;
  late Calculator _calculator;


  @override
  void initState() {

    super.initState();

    _calculator = Calculator(
      viewSize: widget.viewSize, 
      image: widget.image, 
      scale: 1.0, 
      aspectRatio: widget.aspectRatio, 
      move: Offset.zero
    );

    _data = _calculator.calculate();

    // set controller delegates
    widget.controller.crop = () => {
      _crop()
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onScaleStart: (details) {
        _lastFocalPoint = details.focalPoint;
        _initialScale = _calculator.scale;
        _fingersOnScreen = details.pointerCount;
      },

      onScaleUpdate: (details) {

        if(_fingersOnScreen == 1){
          var delta = details.focalPoint - _lastFocalPoint;
          _lastFocalPoint = details.focalPoint;
          setState(() {
            _data = (_calculator..move += delta).calculate();
          });
        }

        if(_fingersOnScreen == 2){
          setState((){
            _data = (_calculator..scale = math.max(1.0, _initialScale * details.scale)).calculate();
          });
        }
      },

      child: CustomPaint(
        painter: CropperPainter(
          data: _data
        ),
      ),
    );
  }

  // Crop out of the portion of the image corresponding to the croppring area
  void _crop() async {
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    var src = Rect.fromLTWH(
      0, 
      0,
      _calculator.image.width.toDouble(), 
      _calculator.image.height.toDouble()
    );

    print("Crop");
    print(_data.imageRect);
    print(_data.croppingRect);
    canvas.clipRect(
      _data.croppingRect
    );
    canvas.drawImageRect(
      widget.image, 
      src, 
      _data.imageRect, 
      Paint()
    );
    var picture = recorder.endRecording();
    var croppedImage = await picture.toImage(_data.croppingRect.width ~/ _calculator.test(), (_data.image.height * 0.874).toInt());
    print(croppedImage);
    // var croppedImage = await picture.toImage(768, 1024);

    widget.onCropped(croppedImage);
  }

}
