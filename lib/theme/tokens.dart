import 'package:flutter/widgets.dart';

/// Design tokens ported 1:1 from the prototype's `T` object (shop-ui.jsx).
class AppColors {
  static const accent = Color(0xFF0D9488);
  static const accentDim = Color.fromRGBO(13, 148, 136, 0.10);
  static const bg = Color(0xFFFFFFFF);
  static const fill = Color.fromRGBO(120, 120, 128, 0.10); // input / chip fill
  static const fill2 = Color.fromRGBO(120, 120, 128, 0.16);
  static const text = Color(0xFF0B0B0C);
  static const sec = Color.fromRGBO(60, 60, 67, 0.60);
  static const ter = Color.fromRGBO(60, 60, 67, 0.33);
  static const sep = Color.fromRGBO(60, 60, 67, 0.12);
  static const red = Color(0xFFD63B2F);
  static const green = Color(0xFF1E8A4C);
  static const orange = Color(0xFFE8730C);

  // Page background behind the device in the prototype (kept for parity).
  static const stage = Color(0xFFE8E8E6);
}

class AppRadii {
  static const card = 14.0;
  static const btn = 24.0;
  static const input = 10.0;
}

/// The prototype's font stack is `-apple-system … "SF Pro Text"`. We bundle
/// Inter (an open-source SF substitute with full Cyrillic) so typography is
/// identical on iOS, Android and web — see pubspec `fonts:` / assets/fonts/.
const String kFontFamily = 'Inter';

/// Convenience text-style builder mirroring the inline CSS the prototype uses.
TextStyle ts({
  double size = 17,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
  String? family = kFontFamily,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
  );
}

const String kMonoFamily = 'RobotoMono';
