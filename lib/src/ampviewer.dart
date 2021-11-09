/* This is free and unencumbered software released into the public domain. */

import 'dart:async' show Completer;
import 'dart:io' show File, HttpRequest, HttpServer, HttpStatus, InternetAddress, Platform;
import 'dart:typed_data' show Uint8List;

// import 'package:bio_hacking/core/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_android/android_content.dart' as android_content;
// import 'package:get/get.dart';

import 'html_builder.dart';

/// Flutter widget for rendering interactive 3D models.
class AmpViewer extends StatefulWidget {
  AmpViewer(
      {Key? key,
      this.backgroundColor,
      required this.src,
      this.alt,
      this.ar,
      this.arModes,
      this.arScale,
      this.autoRotate,
      this.onCreated,
      this.onPageFinished,
      this.autoRotateDelay,
      this.autoPlay,
      this.cameraControls,
      this.iosSrc,
      this.animationName,
      this.gradient,
      this.opaque})
      : super(key: key);

  /// The background color for the model viewer.
  ///
  /// The theme's [ThemeData.scaffoldBackgroundColor] by default.
  final Color? backgroundColor;

  final bool? opaque;

  final List<Color>? gradient;

  final Function(InAppWebViewController)? onCreated;
  final Function(String?)? onPageFinished;

  /// The URL or path to the 3D model. This parameter is required.
  /// Only glTF/GLB models are supported.
  ///
  /// The parameter value must conform to the following:
  ///
  /// - `http://` and `https://` for HTTP(S) URLs
  ///   (for example, `https://modelviewer.dev/shared-assets/models/Astronaut.glb`)
  ///
  /// - `file://` for local files
  ///
  /// - a relative pathname for Flutter app assets
  ///   (for example, `assets/MyModel.glb`)
  final String src;

  /// Configures the model with custom text that will be used to describe the
  /// model to viewers who use a screen reader or otherwise depend on additional
  /// semantic context to understand what they are viewing.
  final String? alt;

  /// Enable the ability to launch AR experiences on supported devices.
  final bool? ar;

  /// A prioritized list of the types of AR experiences to enable, if available.
  final List<String>? arModes;

  /// Controls the scaling behavior in AR mode in Scene Viewer. Set to "fixed"
  /// to disable scaling of the model, which sets it to always be at 100% scale.
  /// Defaults to "auto" which allows the model to be resized.
  final String? arScale;

  /// Enables the auto-rotation of the model.
  final bool? autoRotate;

  /// Sets the delay before auto-rotation begins. The format of the value is a
  /// number in milliseconds. The default is 3000.
  final int? autoRotateDelay;

  /// If this is true and a model has animations, an animation will
  /// automatically begin to play when this attribute is set (or when the
  /// property is set to true). The default is false.
  final bool? autoPlay;

  /// Enables controls via mouse/touch when in flat view.
  final bool? cameraControls;

  /// The URL to a USDZ model which will be used on supported iOS 12+ devices
  /// via AR Quick Look.
  final String? iosSrc;

  final String? animationName;

  @override
  State<AmpViewer> createState() => _AmpViewerState();
}

class _AmpViewerState extends State<AmpViewer> {
  final Completer<InAppWebViewController> _controller = Completer<InAppWebViewController>();

//   AppStates appStates = Get.put(AppStates());

  HttpServer? _proxy;

  @override
  void initState() {
    _initProxy();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (_proxy != null) {
      _proxy!.close(force: true);
      _proxy = null;
    }
  }

  @override
  void didUpdateWidget(final AmpViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(final BuildContext context) {
    return InAppWebView(
      onWebViewCreated: (final InAppWebViewController webViewController) async {
//         appStates.webController.value = webViewController;

        _controller.complete(webViewController);
        final host = _proxy!.address.address;
        final port = _proxy!.port;
        final url = "http://$host:$port/";
//         appStates.url.value = url;
        print('>>>> ModelViewer initializing... <$url>'); // DEBUG
        await webViewController.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse(url),
          ),
        );
//         await webViewController.scrollTo(100, 100);
        widget.onCreated!(webViewController);
      },
      shouldOverrideUrlLoading: (controller, navigation) async {
        print(navigation);
        if (!Platform.isAndroid) {
          return NavigationActionPolicy.ALLOW;
        }
        if (!navigation.request.url!.isScheme('INTENT')) {
          return NavigationActionPolicy.ALLOW;
        }
        // try {
        //   // See: https://developers.google.com/ar/develop/java/scene-viewer
        //   final intent = android_content.Intent(
        //     action: "android.intent.action.VIEW", // Intent.ACTION_VIEW
        //     data: Uri.parse("https://arvr.google.com/scene-viewer/1.0").replace(
        //       queryParameters: <String, dynamic>{
        //         'file': widget.src,
        //         'mode': 'ar_only',
        //       },
        //     ),
        //     package: "com.google.ar.core",
        //     flags: 0x10000000, // Intent.FLAG_ACTIVITY_NEW_TASK,
        //   );
        //   await intent.startActivity();
        // } catch (error) {
        //   print('>>>> ModelViewer failed to launch AR: $error'); // DEBUG
        // }
        return NavigationActionPolicy.CANCEL;
      },
      onLoadStart: (controller, url) {
        print('>>>> ModelViewer began loading: <$url>'); // DEBUG
      },
      onProgressChanged: (controller, progress) async {
        print(progress);
        if (progress == 100) {
          String? newUrl;
          await controller.getUrl().then((value) => newUrl = value.toString());

          widget.onPageFinished!(newUrl);
          print('>>>> ModelViewer finished to load');
        }
      },
      onLoadError: (controller, url, code, message) {
        print('>>>> ModelViewer failed to load: $message'); // DEBUG
      },
    );
  }

  String _buildHTML(final String htmlTemplate) {
    return HTMLBuilder.build(
        htmlTemplate: htmlTemplate,
        backgroundColor: widget.backgroundColor,
        src: '/model',
        alt: widget.alt,
        ar: widget.ar,
        arModes: widget.arModes,
        arScale: widget.arScale,
        autoRotate: widget.autoRotate,
        autoRotateDelay: widget.autoRotateDelay,
        autoPlay: widget.autoPlay,
        cameraControls: widget.cameraControls,
        iosSrc: widget.iosSrc,
        animationName: widget.animationName,
        gradient: widget.gradient);
  }

  Future<void> _initProxy() async {
    final url = Uri.parse(widget.src);
    _proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _proxy!.listen((final HttpRequest request) async {
      //print("${request.method} ${request.uri}"); // DEBUG
      //print(request.headers); // DEBUG
      print(request.uri.path);
      print(request.uri);
      final response = request.response;

      switch (request.uri.path) {
        case '/':
          final htmlTemplate = await rootBundle.loadString('packages/model_viewer/etc/assets/template.html');
          final html = _buildHTML(htmlTemplate);
          response
            ..statusCode = HttpStatus.ok
            ..headers.add("Content-Type", "text/html")
            ..write(html);
          await response.close();
          break;

        case '/model-viewer.js':
          final code = await rootBundle.loadString('packages/model_viewer/etc/assets/model-viewer.js');
          response
            ..statusCode = HttpStatus.ok
            ..headers.add("Content-Type", "application/javascript;charset=UTF-8")
            ..write(code);
          await response.close();
          break;

        case '/model':
          if (url.isAbsolute && !url.isScheme("file")) {
            await response.redirect(url); // TODO: proxy the resource
          } else {
            final data = await (url.isScheme("file") ? _readFile(url.path) : _readAsset(url.path));
            response
              ..statusCode = HttpStatus.ok
              ..headers.add("Content-Type", "application/octet-stream")
              ..headers.add("Content-Length", data.lengthInBytes.toString())
              ..headers.add("Access-Control-Allow-Origin", "*")
              ..add(data);
            print(response.toString());
            await response.close();
          }
          break;

        case '/favicon.ico':
        default:
          response
            ..statusCode = HttpStatus.notFound
            ..headers.add("Content-Type", "text/plain")
            ..write("Resource '${request.uri}' not found");
          await response.close();
          break;
      }
    });
  }

  Future<Uint8List> _readAsset(final String key) async {
    final data = await rootBundle.load(key);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List> _readFile(final String path) async {
    return await File(path).readAsBytes();
  }
}
