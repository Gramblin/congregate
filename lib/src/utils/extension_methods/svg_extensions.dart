import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

extension SvgPictureWithColor on SvgPicture {
  static SvgPicture assetWithColor(
    String assetName, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
    Color? color,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return SvgPicture.asset(
      assetName,
      height: height,
      width: width,
      alignment: alignment,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}
