import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);

enum BarcodeFormat {
  /// Aztec 2D barcode format.
  aztec,

  /// CODABAR 1D format.
  codabar,

  /// Code 39 1D format.
  code39,

  /// Code 93 1D format.
  code93,

  /// Code 128 1D format.
  code128,

  /// Data Matrix 2D barcode format.
  dataMatrix,

  /// EAN-8 1D format.
  ean8,

  /// EAN-13 1D format.
  ean13,

  /// ITF (Interleaved Two of Five) 1D format.
  itf,

  /// MaxiCode 2D barcode format.
  maxicode,

  /// PDF417 format.
  pdf417,

  /// QR Code 2D barcode format.
  qrcode,

  /// RSS 14
  rss14,

  /// RSS EXPANDED
  rssExpanded,

  /// UPC-A 1D format.
  upcA,

  /// UPC-E 1D format.
  upcE,

  /// UPC/EAN extension format. Not a stand-alone format.
  upcEanExtension
}

const _formatNames = <String, BarcodeFormat>{
  'AZTEC': BarcodeFormat.aztec,
  'CODABAR': BarcodeFormat.codabar,
  'CODE_39': BarcodeFormat.code39,
  'CODE_93': BarcodeFormat.code93,
  'CODE_128': BarcodeFormat.code128,
  'DATA_MATRIX': BarcodeFormat.dataMatrix,
  'EAN_8': BarcodeFormat.ean8,
  'EAN_13': BarcodeFormat.ean13,
  'ITF': BarcodeFormat.itf,
  'MAXICODE': BarcodeFormat.maxicode,
  'PDF_417': BarcodeFormat.pdf417,
  'QR_CODE': BarcodeFormat.qrcode,
  'RSS_14': BarcodeFormat.rss14,
  'RSS_EXPANDED': BarcodeFormat.rssExpanded,
  'UPC_A': BarcodeFormat.upcA,
  'UPC_E': BarcodeFormat.upcE,
  'UPC_EAN_EXTENSION': BarcodeFormat.upcEanExtension,
};

class Barcode {
  Barcode(this.code, this.format, this.rawBytes);

  final String code;
  final BarcodeFormat format;

  /// Raw bytes are only supported by Android.
  final List<int> rawBytes;
}

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.boxLineColor = const Color(0xFFE20073),
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final Color boxLineColor;

  final ShapeBorder overlay;
  final EdgeInsetsGeometry overlayMargin;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> with TickerProviderStateMixin {

  AnimationController _animationController;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void dispose() {
    _clearAnimation();
    super.dispose();
  }

  void _upState() {
    setState(() {});
  }

  void _initAnimation() {
    setState(() {
      _animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 1000));
    });
    _animationController
      ..addListener(_upState)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          _timer = Timer(Duration(seconds: 1), () {
            _animationController?.reverse(from: 1.0);
          });
        } else if (state == AnimationStatus.dismissed) {
          _timer = Timer(Duration(seconds: 1), () {
            _animationController?.forward(from: 0.0);
          });
        }
      });
    _animationController.forward(from: 0.0);
  }

  void _clearAnimation() {
    _timer?.cancel();
    if (_animationController != null) {
      _animationController?.dispose();
      _animationController = null;
    }
  }

  List<Widget> _childrenStacks() {
    if (widget.overlay != null) {
      return [
        Container(
          padding: widget.overlayMargin,
          decoration: ShapeDecoration(
            shape: widget.overlay,
          ),
        ),
        Positioned(
          left: (MediaQuery
              .of(context)
              .size
              .width - 260) / 2.0,
          top: (MediaQuery
              .of(context)
              .size
              .height - 260) / 2.0 - 40,
          child: CustomPaint(
            painter: QrScanBoxPainter(
              boxLineColor: widget.boxLineColor,
              animationValue: _animationController?.value ?? 0,
              isForward:
              _animationController?.status == AnimationStatus.forward,
            ),
            child: SizedBox(
              width: 260,
              height: 260,
            ),
          ),
        ),
      ];
    } else {
      return [
        Container(),
      ];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(widget.key),
        if (widget.overlay != null)
          Container(
            padding: widget.overlayMargin,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          ),
          Positioned(
            left: (MediaQuery
                .of(context)
                .size
                .width - 260) / 2.0,
            top: (MediaQuery
                .of(context)
                .size
                .height - 260) / 2.0 - 40,
            child: CustomPaint(
              painter: QrScanBoxPainter(
                boxLineColor: widget.boxLineColor,
                animationValue: _animationController?.value ?? 0,
                isForward:
                _animationController?.status == AnimationStatus.forward,
              ),
              child: SizedBox(
                width: 260,
                height: 260,
              ),
            ),
          ),
        // else
        //
      ],
    );
  }

  Widget _getPlatformQrView(GlobalKey key) {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams:
              _CreationParams.fromWidget(MediaQuery.of(context).size.width, 400)
                  .toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }

    // We pass the cutout size so that the scanner respects the scan area.
    var cutOutSize = 0.0;
    if (widget.overlay != null) {
      cutOutSize = (widget.overlay as QrScannerOverlayShape).cutOutSize;
    }

    widget.onQRViewCreated(QRViewController._(id, widget.key, cutOutSize));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  QRViewController._(int id, GlobalKey qrKey, double scanArea)
      : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    updateDimensions(qrKey, scanArea: scanArea, offset: 40);
    _channel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              final args = call.arguments as Map;
              final code = args['code'] as String;
              final rawType = args['type'] as String;
              // Raw bytes are only supported by Android.
              final rawBytes = args['rawBytes'] as List<int>;
              final format = _formatNames[rawType];
              if (format != null) {
                final barcode = Barcode(code, format, rawBytes);
                _scanUpdateController.sink.add(barcode);
              } else {
                throw Exception('Unexpected barcode type $rawType');
              }
            }
        }
      },
    );
  }

  static const scanMethodCall = 'onRecognizeQR';

  final MethodChannel _channel;

  final StreamController<Barcode> _scanUpdateController =
      StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _scanUpdateController.stream;

  void flipCamera() {
    _channel.invokeMethod('flipCamera');
  }

  void toggleFlash() {
    _channel.invokeMethod('toggleFlash');
  }

  void pauseCamera() {
    _channel.invokeMethod('pauseCamera');
  }

  void resumeCamera() {
    _channel.invokeMethod('resumeCamera');
  }

  void dispose() {
    _scanUpdateController.close();
  }

  void updateDimensions(GlobalKey key, {double scanArea, double offset}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = key.currentContext.findRenderObject();
      _channel.invokeMethod('setDimensions', {
        'width': renderBox.size.width,
        'height': renderBox.size.height,
        'scanArea': scanArea ?? 0,
        'offset': offset ?? 0,
      });
    }
  }
}


class QrScanBoxPainter extends CustomPainter {
  final double animationValue;
  final bool isForward;
  final Color boxLineColor;

  QrScanBoxPainter(
      {@required this.animationValue,
        @required this.isForward,
        this.boxLineColor})
      : assert(animationValue != null),
        assert(isForward != null);

  @override
  void paint(Canvas canvas, Size size) {

    canvas.clipRRect(
        BorderRadius.all(Radius.circular(0)).toRRect(Offset.zero & size));

    final linePaint = Paint();
    final lineSize = 70.0;
    final leftPress = (size.height + lineSize) * animationValue - lineSize;
    linePaint.style = PaintingStyle.fill;
    linePaint.strokeWidth = lineSize;

    linePaint.shader = LinearGradient(
      colors: [Color(0x00E20073),Color(0xD6ED4199), Color(0xFFE20073), Color(0xFFE20073)],
      stops: [0.0, 0.7, 68.0/70.0, 1.0],
      begin: isForward ? Alignment.topCenter: Alignment.bottomCenter,
      end: isForward ? Alignment.bottomCenter : Alignment.topCenter
    ).createShader(Rect.fromLTWH(0, leftPress, size.width, lineSize));


    canvas.drawLine(
      Offset(0, leftPress+lineSize*0.5),
      Offset(size.width, leftPress+lineSize*0.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(QrScanBoxPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(QrScanBoxPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
