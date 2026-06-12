import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/tokens.dart';

/// Icons ported verbatim from the prototype's `Ic` object (shop-ui.jsx).
///
/// Each SVG is drawn in solid black and tinted to the requested colour via a
/// srcIn [ColorFilter], so the token's alpha (e.g. `sec` at 0.6) carries through
/// exactly as in the CSS original.
Widget _svg(String body, String viewBox, Color color, double size) {
  return SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox" fill="none">$body</svg>',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

class Ic {
  static Widget search([Color c = AppColors.sec, double s = 18]) => _svg(
        '<circle cx="8.5" cy="8.5" r="6" stroke="#000" stroke-width="1.8"/>'
        '<path d="M13 13l4.5 4.5" stroke="#000" stroke-width="1.8" stroke-linecap="round"/>',
        '0 0 20 20', c, s);

  static Widget grid(Color c, [double s = 24]) => _svg(
        '<rect x="3.5" y="3.5" width="7" height="7" rx="2" stroke="#000" stroke-width="1.8"/>'
        '<rect x="13.5" y="3.5" width="7" height="7" rx="2" stroke="#000" stroke-width="1.8"/>'
        '<rect x="3.5" y="13.5" width="7" height="7" rx="2" stroke="#000" stroke-width="1.8"/>'
        '<rect x="13.5" y="13.5" width="7" height="7" rx="2" stroke="#000" stroke-width="1.8"/>',
        '0 0 24 24', c, s);

  static Widget cart(Color c, [double s = 24]) => _svg(
        '<path d="M3 4h2.2l2.1 11.2a1.6 1.6 0 0 0 1.57 1.3h8.46a1.6 1.6 0 0 0 1.56-1.23L20.6 8H6" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>'
        '<circle cx="9.6" cy="20.4" r="1.5" fill="#000"/>'
        '<circle cx="17.2" cy="20.4" r="1.5" fill="#000"/>',
        '0 0 24 24', c, s);

  static Widget person(Color c, [double s = 24]) => _svg(
        '<circle cx="12" cy="8" r="4.2" stroke="#000" stroke-width="1.8"/>'
        '<path d="M4.5 20.4c1.4-3.6 4.2-5.4 7.5-5.4s6.1 1.8 7.5 5.4" stroke="#000" stroke-width="1.8" stroke-linecap="round"/>',
        '0 0 24 24', c, s);

  static Widget chevronL([Color c = AppColors.text, double s = 20]) => _svg(
        '<path d="M12.5 3.5L6 10l6.5 6.5" stroke="#000" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
        '0 0 20 20', c, s);

  static Widget chevronR([Color c = AppColors.ter, double s = 14]) => _svg(
        '<path d="M7.5 3.5L14 10l-6.5 6.5" stroke="#000" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
        '0 0 20 20', c, s);

  static Widget check([Color c = const Color(0xFFFFFFFF), double s = 18]) => _svg(
        '<path d="M4 10.5l4.2 4.2L16.5 6" stroke="#000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
        '0 0 20 20', c, s);

  static Widget phone([Color c = AppColors.accent, double s = 18]) => _svg(
        '<path d="M4.2 3.2C4.6 2.8 5.3 2.8 5.7 3.2L7.8 5.3c.4.4.4 1 .05 1.45l-1 1.2a.9.9 0 0 0-.05 1.1 12.4 12.4 0 0 0 4.15 4.15.9.9 0 0 0 1.1-.05l1.2-1c.45-.35 1.05-.35 1.45.05l2.1 2.1c.4.4.4 1.1 0 1.5l-1 1c-.7.7-1.75.95-2.7.6-2.3-.85-4.5-2.3-6.4-4.2-1.9-1.9-3.35-4.1-4.2-6.4-.35-.95-.1-2 .6-2.7l1-1z" stroke="#000" stroke-width="1.6" stroke-linejoin="round"/>',
        '0 0 20 20', c, s);

  static Widget send([Color c = AppColors.accent, double s = 18]) => _svg(
        '<path d="M17.5 2.5L9 11M17.5 2.5L12 17.5l-3-6.5-6.5-3 15-5.5z" stroke="#000" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>',
        '0 0 20 20', c, s);

  static Widget bell([Color c = AppColors.text, double s = 22]) => _svg(
        '<path d="M12 3.5c-3.3 0-5.5 2.5-5.5 5.6 0 4.2-1.6 5.6-2.5 6.6-.3.35-.05 1 .45 1h15.1c.5 0 .75-.65.45-1-.9-1-2.5-2.4-2.5-6.6 0-3.1-2.2-5.6-5.5-5.6z" stroke="#000" stroke-width="1.8" stroke-linejoin="round"/>'
        '<path d="M9.8 19.5a2.3 2.3 0 0 0 4.4 0" stroke="#000" stroke-width="1.8" stroke-linecap="round"/>',
        '0 0 24 24', c, s);

  static Widget qr(Color c, [double s = 24]) => _svg(
        '<rect x="3.5" y="3.5" width="7" height="7" rx="1.5" stroke="#000" stroke-width="1.8"/>'
        '<rect x="6" y="6" width="2" height="2" fill="#000"/>'
        '<rect x="13.5" y="3.5" width="7" height="7" rx="1.5" stroke="#000" stroke-width="1.8"/>'
        '<rect x="16" y="6" width="2" height="2" fill="#000"/>'
        '<rect x="3.5" y="13.5" width="7" height="7" rx="1.5" stroke="#000" stroke-width="1.8"/>'
        '<rect x="6" y="16" width="2" height="2" fill="#000"/>'
        '<rect x="13.5" y="13.5" width="3" height="3" fill="#000"/>'
        '<rect x="17.5" y="17.5" width="3" height="3" fill="#000"/>'
        '<rect x="17.5" y="13.5" width="3" height="3" stroke="#000" stroke-width="1.4"/>',
        '0 0 24 24', c, s);

  static Widget ticket([Color c = AppColors.accent, double s = 22]) => _svg(
        '<path d="M3.5 9V7A1.5 1.5 0 0 1 5 5.5h14A1.5 1.5 0 0 1 20.5 7v2a3 3 0 0 0 0 6v2a1.5 1.5 0 0 1-1.5 1.5H5A1.5 1.5 0 0 1 3.5 17v-2a3 3 0 0 0 0-6z" stroke="#000" stroke-width="1.8" stroke-linejoin="round"/>'
        '<path d="M14 6v2.5M14 11v2.5M14 15.5V18" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-dasharray="0.1 3.4"/>',
        '0 0 24 24', c, s);

  static Widget gift([Color c = AppColors.accent, double s = 22]) => _svg(
        '<rect x="3.5" y="8" width="17" height="4.5" rx="1" stroke="#000" stroke-width="1.8"/>'
        '<path d="M5 12.5h14V19a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 19v-6.5z" stroke="#000" stroke-width="1.8"/>'
        '<path d="M12 8v12.5M12 8s-1-4-4-4a2 2 0 0 0 0 4h4zm0 0s1-4 4-4a2 2 0 0 1 0 4h-4z" stroke="#000" stroke-width="1.8" stroke-linejoin="round"/>',
        '0 0 24 24', c, s);

  static Widget globe([Color c = AppColors.accent, double s = 22]) => _svg(
        '<circle cx="12" cy="12" r="8.5" stroke="#000" stroke-width="1.8"/>'
        '<ellipse cx="12" cy="12" rx="3.8" ry="8.5" stroke="#000" stroke-width="1.6"/>'
        '<path d="M3.5 12h17" stroke="#000" stroke-width="1.6" stroke-linecap="round"/>',
        '0 0 24 24', c, s);

  static Widget heart([Color c = AppColors.sec, double s = 22]) => _svg(
        '<path d="M12 20.5s-7.8-4.9-9.3-9.8C1.6 7 4 4 7.1 4c2 0 3.8 1.1 4.9 2.9C13.1 5.1 14.9 4 16.9 4 20 4 22.4 7 21.3 10.7c-1.5 4.9-9.3 9.8-9.3 9.8z" stroke="#000" stroke-width="1.8" stroke-linejoin="round"/>',
        '0 0 24 24', c, s);

  static Widget heartFill([Color c = AppColors.red, double s = 22]) => _svg(
        '<path d="M12 20.5s-7.8-4.9-9.3-9.8C1.6 7 4 4 7.1 4c2 0 3.8 1.1 4.9 2.9C13.1 5.1 14.9 4 16.9 4 20 4 22.4 7 21.3 10.7c-1.5 4.9-9.3 9.8-9.3 9.8z" fill="#000"/>',
        '0 0 24 24', c, s);

  static Widget cash([Color c = AppColors.accent, double s = 22]) => _svg(
        '<rect x="2.5" y="5.5" width="19" height="13" rx="2" stroke="#000" stroke-width="1.8"/>'
        '<circle cx="12" cy="12" r="2.7" stroke="#000" stroke-width="1.8"/>'
        '<circle cx="6" cy="12" r="0.9" fill="#000"/>'
        '<circle cx="18" cy="12" r="0.9" fill="#000"/>',
        '0 0 24 24', c, s);

  static Widget card([Color c = AppColors.accent, double s = 22]) => _svg(
        '<rect x="2.5" y="5" width="19" height="14" rx="2.5" stroke="#000" stroke-width="1.8"/>'
        '<path d="M2.5 9.5h19" stroke="#000" stroke-width="1.8"/>'
        '<path d="M6 14.5h4.5" stroke="#000" stroke-width="1.8" stroke-linecap="round"/>',
        '0 0 24 24', c, s);

  static Widget copy([Color c = AppColors.sec, double s = 16]) => _svg(
        '<rect x="7" y="7" width="10" height="10" rx="2.5" stroke="#000" stroke-width="1.6"/>'
        '<path d="M13 4.5V4a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h.5" stroke="#000" stroke-width="1.6"/>',
        '0 0 20 20', c, s);

  static Widget bag([Color c = AppColors.ter, double s = 52]) => _svg(
        '<path d="M11 17h30l-2.2 24a3.2 3.2 0 0 1-3.2 2.9H16.4a3.2 3.2 0 0 1-3.2-2.9L11 17z" stroke="#000" stroke-width="2.6" stroke-linejoin="round"/>'
        '<path d="M18.5 22v-6.5a7.5 7.5 0 0 1 15 0V22" stroke="#000" stroke-width="2.6" stroke-linecap="round"/>',
        '0 0 52 52', c, s);

  static Widget box([Color c = AppColors.ter, double s = 48]) => _svg(
        '<path d="M6 15L24 6l18 9v18l-18 9-18-9V15z" stroke="#000" stroke-width="2.4" stroke-linejoin="round"/>'
        '<path d="M6 15l18 9 18-9M24 24v18" stroke="#000" stroke-width="2.4" stroke-linejoin="round"/>',
        '0 0 48 48', c, s);

  static Widget personBig([Color c = AppColors.ter, double s = 72]) => _svg(
        '<circle cx="36" cy="36" r="33" stroke="#000" stroke-width="3"/>'
        '<circle cx="36" cy="28" r="10" stroke="#000" stroke-width="3"/>'
        '<path d="M16 60c3.4-8.8 10.5-13.5 20-13.5S52.6 51.2 56 60" stroke="#000" stroke-width="3" stroke-linecap="round"/>',
        '0 0 72 72', c, s);
}
