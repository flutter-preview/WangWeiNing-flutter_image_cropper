import 'package:flutter/material.dart';
import 'dart:math' as math;
import "dart:ui" as ui;

class MyCropper extends StatefulWidget {
  const MyCropper({super.key, required this.image});

  final ui.Image image;

  @override
  State<StatefulWidget> createState() => MyCropperState();
}

class MyCropperState extends State<MyCropper> {

  Offset _lastFocalPoint = Offset.zero;
  double _initialScale = 1.0;
  int _fingersOnScreen = 0;

  late CropperPainterState _painterState;

  @override
  void initState() {
    super.initState();
    _painterState = CropperPainterState(
      image: widget.image
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onScaleStart: (details) {
        _lastFocalPoint = details.focalPoint;
        _initialScale = _painterState.scale;
        _fingersOnScreen = details.pointerCount;
      },

      onScaleUpdate: (details) {
        if(_fingersOnScreen == 1){
          var delta = details.focalPoint - _lastFocalPoint;
          _lastFocalPoint = details.focalPoint;
          setState(() {
            _painterState.move += delta;
          });
        }

        if(_fingersOnScreen == 2){
          setState((){
            _painterState.scale = _initialScale * details.scale;
          });
        }
      },

      onScaleEnd: (details) {
        setState(() {
          
        });
      },
      // },
      child: CustomPaint(
        painter: CropperPainter(
          state: _painterState
        ),
      ),
    );
  }
}

class CropperPainterState {
  ui.Image image;
  Offset move;
  double scale;
  double aspectRatio;

  CropperPainterState(
      {
        required this.image,
        this.move = Offset.zero,
        this.scale = 1.5,
        this.aspectRatio = 768 / 1024
      }
  );
}

class CropperPainter extends CustomPainter {
  CropperPainterState state;

  CropperPainter({required this.state});

  late Size _viewAreaSize;
  late Size _rawImageRectSize;
  late Size _scaledImageRectSize;
  late double _ratioBetweenImageAndView;
  late Rect _cropAreaRect;

  @override
  void paint(Canvas canvas, Size size) {
    state.scale = math.max(1.0, state.scale);

    _viewAreaSize = size;

    _calcRatioBetweenImageAndView();
    _calcImageRect();
    _calcCropRect();

    var viewRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.clipRect(viewRect);
    paintImage(canvas);
    paintMask(canvas);
    paintCropArea(canvas);
  }

  void _calcCropRect() {
    var width = _rawImageRectSize.width;
    var height = _rawImageRectSize.width / state.aspectRatio;

    if (height > _rawImageRectSize.height) {
      height = _rawImageRectSize.height;
      width = _rawImageRectSize.height * state.aspectRatio;
    }

    _cropAreaRect = Rect.fromLTWH(
      (_viewAreaSize.width - width) / 2,
      (_viewAreaSize.height - height) / 2,
      width,
      height,
    );
  }

  void _calcImageRect() {
    _rawImageRectSize = Size(state.image.width * _ratioBetweenImageAndView,
        state.image.height * _ratioBetweenImageAndView);

    _scaledImageRectSize =
        Size(_rawImageRectSize.width * state.scale, _rawImageRectSize.height * state.scale);
  }

  void paintMask(Canvas canvas) {
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, _viewAreaSize.width, _viewAreaSize.height),
        Paint()..blendMode = BlendMode.xor);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, _viewAreaSize.width, _viewAreaSize.height),
        Paint()..color = const Color.fromARGB(133, 0, 0, 0));

    canvas.drawRect(_cropAreaRect, Paint()..blendMode = BlendMode.clear);

    canvas.restore();
  }

  void paintCropArea(Canvas canvas) {
    canvas.drawRect(
        _cropAreaRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    canvas.clipRect(
      _cropAreaRect,
      doAntiAlias: false,
    );

    // draw lines
    double verticalSpace = (_cropAreaRect.height / 3);
    canvas.drawLine(
        Offset(_cropAreaRect.left, _cropAreaRect.top + verticalSpace),
        Offset(_cropAreaRect.right, _cropAreaRect.top + verticalSpace),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    canvas.drawLine(
        Offset(_cropAreaRect.left, _cropAreaRect.top + verticalSpace * 2),
        Offset(_cropAreaRect.right, _cropAreaRect.top + verticalSpace * 2),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    double horizontalSpace = _cropAreaRect.width / 3;

    canvas.drawLine(
        Offset(horizontalSpace + _cropAreaRect.left, _cropAreaRect.top),
        Offset(horizontalSpace + _cropAreaRect.left, _cropAreaRect.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);

    canvas.drawLine(
        Offset(horizontalSpace * 2 + _cropAreaRect.left, _cropAreaRect.top),
        Offset(horizontalSpace * 2 + _cropAreaRect.left, _cropAreaRect.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5);
  }

  void paintImage(Canvas canvas) {
    var imageOffsetInCenterOfView = Offset(
      (_viewAreaSize.width - _scaledImageRectSize.width) / 2,
      (_viewAreaSize.height - _scaledImageRectSize.height) / 2,
    );

    var src =
        Rect.fromLTWH(0, 0, state.image.width.toDouble(), state.image.height.toDouble());

    // boundaries check
    Offset safeMove = Offset(_cropAreaRect.left, _cropAreaRect.top) - imageOffsetInCenterOfView;

    state.move = Offset(
      state.move.dx >= 0 ? math.min(safeMove.dx, state.move.dx) : math.max(-safeMove.dx, state.move.dx),
      state.move.dy >= 0 ? math.min(state.move.dy, safeMove.dy) : math.max(state.move.dy, -safeMove.dy)
    );

    var dstLeft = state.move.dx + imageOffsetInCenterOfView.dx;
    var dstTop = state.move.dy + imageOffsetInCenterOfView.dy;
    var dst = Rect.fromLTWH(
      dstLeft, 
      dstTop, 
      _scaledImageRectSize.width,
      _scaledImageRectSize.height
    );

    canvas.drawImageRect(state.image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void _calcRatioBetweenImageAndView() {
    _ratioBetweenImageAndView = math.min<double>(
        _viewAreaSize.height / state.image.height, _viewAreaSize.width / state.image.width);
  }
}
