import 'package:flutter/material.dart';
import "controller.dart";
import "package:image/image.dart" as imageLib;
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
        scale: _initialScale,
        aspectRatio: widget.aspectRatio,
        move: Offset.zero);

    _data = _calculator.calculate();

    // set controller delegates
    widget.controller.crop = () => {_crop()};
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
        if (_fingersOnScreen == 1) {
          var delta = details.focalPoint - _lastFocalPoint;
          _lastFocalPoint = details.focalPoint;
          setState(() {
            _data = (_calculator..move += delta).calculate();
          });
        }

        if (_fingersOnScreen == 2) {
          setState(() {
            _data = (_calculator
                  ..scale = math.max(1.0, _initialScale * details.scale))
                .calculate();
          });
        }
      },
      child: CustomPaint(
        painter: CropperPainter(data: _data),
      ),
    );
  }

  // Crop out of the portion of the image corresponding to the croppring area
  void _crop() async {
    final uiBytes = await _data.image.toByteData();

    final img = imageLib.Image.fromBytes(
        width: _data.image.width,
        height: _data.image.height,
        bytes: uiBytes!.buffer,
        numChannels: 4);

    var imgCropped = imageLib.copyCrop(img,
        x: ((_data.croppingRect.left - _data.imageRect.left) ~/
                _calculator.test() ~/
                _calculator.scale)
            .toInt(),
        y: ((_data.croppingRect.top - _data.imageRect.top) ~/
                _calculator.test() ~/
                _calculator.scale)
            .toInt(),
        width:
            _data.croppingRect.width / _calculator.test() ~/ _calculator.scale,
        height: _data.croppingRect.height /
            _calculator.test() ~/
            _calculator.scale);

    // https://github.com/brendan-duncan/image/blob/main/doc/flutter.md
    Future<ui.Image> convertImageToFlutterUi(imageLib.Image image) async {
      if (img.format != imageLib.Format.uint8 || img.numChannels != 4) {
        final cmd = imageLib.Command()
          ..image(img)
          ..convert(format: imageLib.Format.uint8, numChannels: 4);
        final rgba8 = await cmd.getImageThread();
        if (rgba8 != null) {
          image = rgba8;
        }
      }

      ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

      ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
          height: image.height,
          width: image.width,
          pixelFormat: ui.PixelFormat.rgba8888);

      ui.Codec codec = await id.instantiateCodec(
          targetHeight: image.height, targetWidth: image.width);

      ui.FrameInfo fi = await codec.getNextFrame();
      ui.Image uiImage = fi.image;

      return uiImage;
    }

    widget.onCropped(await convertImageToFlutterUi(imgCropped));
  }
}
