/* This is free and unencumbered software released into the public domain. */

import 'dart:convert' show htmlEscape;

import 'package:flutter/material.dart';
// import 'package:get/state_manager.dart';

abstract class HTMLBuilder {
  HTMLBuilder._();

  static String build(
      {final String htmlTemplate = '',
      required final String src,
      final Color? backgroundColor,
      final String? alt,
      final bool? ar,
      final List<String>? arModes,
      final String? arScale,
      final bool? autoRotate,
      final int? autoRotateDelay,
      final bool? autoPlay,
      final bool? cameraControls,
      final String? iosSrc,
      final String? animationName,
      final List<Color>? gradient}) {
    final html = StringBuffer(htmlTemplate);
    html.write('<script src="https://unpkg.com/focus-visible@5.1.0/dist/focus-visible.js"></script>');
    html.write(
        '<body style="${gradient != null ? 'background: linear-gradient(180deg, rgb(${gradient[0].red}, ${gradient[0].green}, ${gradient[0].blue}) 0%, rgb(${gradient[1].red}, ${gradient[1].green}, ${gradient[1].blue}) 100%);' : 'background-color: rgb(${backgroundColor!.red}, ${backgroundColor.green}, ${backgroundColor.blue})'}">');

    html.write('<amp-3d-gltf layout="fixed" width="320" height="240" src="$src"></amp-3d-gltf>');

    html.writeln('</body>');
    return html.toString();
  }
}
