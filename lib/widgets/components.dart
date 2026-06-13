import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../theme/tokens.dart';
import 'icons.dart';

/// Tab-bar content height (icon + label + padding); the bottom safe-area inset
/// is added on top. Used to pin content (e.g. the cart summary) above the bar.
const double kTabBarContentHeight = 56;
double tabBarHeight(BuildContext context) =>
    kTabBarContentHeight + MediaQuery.of(context).padding.bottom;

/// Shared backdrop blurs (≈ the prototype's `backdrop-filter: blur(Npx)`).
final ImageFilter blur12 = ImageFilter.blur(sigmaX: 12, sigmaY: 12);
final ImageFilter blur16 = ImageFilter.blur(sigmaX: 16, sigmaY: 16);
final ImageFilter blur18 = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

/// Top inset that stands in for the prototype's hardcoded 62–74px status-bar
/// clearance. On notched devices we use the real safe-area inset; on web/desktop
/// (no inset) we fall back to a sensible iOS-like value.
double topInset(BuildContext context) {
  final t = MediaQuery.of(context).padding.top;
  return t > 0 ? t : 24;
}

// ── Image placeholder (neutral striped block + label) ───────────────────────
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.025)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    // Diagonal hatch (≈135° axis) repeating every 14px, 6px line / 8px gap.
    const period = 14.0;
    for (double d = -size.height; d < size.width + size.height; d += period) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductImage extends StatelessWidget {
  /// Absolute image URL; when null/failed the striped placeholder shows.
  final String? imageUrl;

  /// Label drawn on the placeholder (null = no label).
  final String? label;

  /// Screen-reader label for the image (e.g. the product name). When null the
  /// image is treated as decorative and excluded from the semantics tree.
  final String? semanticLabel;
  final double radius;
  final double fontSize;
  final double? width;
  final double? height;
  final double? aspectRatio;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.label,
    this.semanticLabel,
    this.radius = 12,
    this.fontSize = 11,
    this.width,
    this.height,
    this.aspectRatio,
  });

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F3),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.045)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripePainter()),
          if (label != null && label!.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kMonoFamily,
                    fontSize: fontSize,
                    color: const Color.fromRGBO(60, 60, 67, 0.40),
                    letterSpacing: 0.2,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget inner = imageUrl == null
        ? _placeholder()
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _placeholder(),
            errorBuilder: (context, _, _) => _placeholder(),
          );

    Widget child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: inner);
    if (aspectRatio != null) child = AspectRatio(aspectRatio: aspectRatio!, child: child);
    if (width != null || height != null) child = SizedBox(width: width, height: height, child: child);
    return (semanticLabel != null && semanticLabel!.isNotEmpty)
        ? Semantics(image: true, label: semanticLabel, child: child)
        : ExcludeSemantics(child: child);
  }
}

// ── Buttons ─────────────────────────────────────────────────────────────────
class BigButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool disabled;
  final bool loading;
  final bool ghost;
  final double? width;
  final EdgeInsets? padding;
  final double height;
  final EdgeInsets margin;

  const BigButton({
    super.key,
    required this.child,
    this.onTap,
    this.disabled = false,
    this.loading = false,
    this.ghost = false,
    this.width = double.infinity,
    this.padding,
    this.height = 50,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final filled = !widget.ghost;
    final enabled = !widget.disabled && !widget.loading;
    final bg = filled
        ? (widget.disabled ? const Color.fromRGBO(120, 120, 128, 0.18) : AppColors.accent)
        : AppColors.accentDim;
    final fg = filled
        ? (widget.disabled ? const Color.fromRGBO(60, 60, 67, 0.35) : Colors.white)
        : AppColors.accent;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.btn),
          ),
          child: widget.loading
              ? Spinner(color: fg)
              : DefaultTextStyle(
                  style: ts(size: 17, weight: FontWeight.w600, color: fg, letterSpacing: -0.2),
                  child: IconTheme(
                    data: IconThemeData(color: fg),
                    child: widget.child,
                  ),
                ),
        ),
      ),
      ),
    );
  }
}

class ShopTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  const ShopTextButton({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.accent,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: DefaultTextStyle(
            style: ts(size: fontSize, weight: FontWeight.w500, color: color, letterSpacing: -0.2),
            child: IconTheme(data: IconThemeData(color: color), child: child),
          ),
        ),
      ),
    );
  }
}

class Spinner extends StatelessWidget {
  final Color color;
  final double size;
  const Spinner({super.key, this.color = AppColors.accent, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation(color),
        backgroundColor: color.withValues(alpha: 0.25),
      ),
    );
  }
}

// ── Badges / chips ──────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final m = orderStatus[status];
    if (m == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(100)),
      child: Text(tr(m.label),
          style: ts(size: 13, weight: FontWeight.w600, color: m.color)),
    );
  }
}

class StockBadge extends StatelessWidget {
  final bool inStock;
  final bool small;
  const StockBadge({super.key, required this.inStock, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = inStock ? AppColors.green : AppColors.red;
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inStock ? const Color.fromRGBO(30, 138, 76, 0.10) : const Color.fromRGBO(214, 59, 47, 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(inStock ? tr('Мавжуд') : tr('Тугаган'),
          style: ts(size: small ? 12 : 13, weight: FontWeight.w600, color: c)),
    );
  }
}

class ShopChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ShopChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? Colors.transparent : const Color.fromRGBO(60, 60, 67, 0.18),
          ),
        ),
        child: Text(label,
            style: ts(
                size: 14.5,
                weight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.text,
                letterSpacing: -0.15)),
      ),
      ),
    );
  }
}

// ── Option card (payment methods, providers, …) ─────────────────────────────
/// Bordered tappable row: a 36×36 icon tile, a title (+ optional subtitle)
/// and either a radio check (when [selected] is non-null) or a custom
/// [trailing] widget (chevron, spinner, …).
class OptionCard extends StatelessWidget {
  final Widget icon;

  /// Tile fill behind [icon]; defaults to the accent-dim used across the app.
  final Color? tileColor;
  final String title;
  final String? subtitle;

  /// Non-null turns the card into a radio option: accent border + dim fill
  /// when true, with a trailing radio check.
  final bool? selected;
  final Widget? trailing;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.icon,
    this.tileColor,
    required this.title,
    this.subtitle,
    this.selected,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = selected == true;
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentDim : AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: sel ? AppColors.accent : AppColors.sep, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sel ? AppColors.bg : (tileColor ?? AppColors.accentDim),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: ts(size: 15.5, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.2)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: ts(size: 13, color: AppColors.sec, letterSpacing: -0.1, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (selected != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? AppColors.accent : Colors.transparent,
                  border: sel
                      ? null
                      : Border.all(color: const Color.fromRGBO(60, 60, 67, 0.30), width: 1.6),
                ),
                child: sel ? Center(child: Ic.check(Colors.white, 12)) : null,
              )
            else
              ?trailing,
          ],
        ),
      ),
      ),
    );
  }
}

// ── Quantity stepper ────────────────────────────────────────────────────────
class ShopStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChange;
  final bool compact;
  const ShopStepper({super.key, required this.qty, required this.onChange, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final h = compact ? 30.0 : 38.0;
    Widget btn(String label, int delta, String semLabel) => Semantics(
          button: true,
          label: semLabel,
          excludeSemantics: true, // the bare "+/−" glyph would read poorly
          onTap: () => onChange(qty + delta), // exclude drops the child action
          child: GestureDetector(
            onTap: () => onChange(qty + delta),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: h + 4,
              height: h,
              child: Center(
                child: Text(label,
                    style: ts(size: compact ? 17 : 20, weight: FontWeight.w500, color: AppColors.text)),
              ),
            ),
          ),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('−', -1, tr2('Камайтириш', 'Уменьшить')),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 22),
            child: Text(
              formatQty(qty),
              textAlign: TextAlign.center,
              style: ts(size: compact ? 15 : 17, weight: FontWeight.w600, color: AppColors.text)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          btn('+', 1, tr2('Кўпайтириш', 'Увеличить')),
        ],
      ),
    );
  }
}

// ── Form field + input ──────────────────────────────────────────────────────
class Field extends StatelessWidget {
  final String? label;
  final String? error;
  final Widget child;
  const Field({super.key, this.label, this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label!, style: ts(size: 14, weight: FontWeight.w500, color: AppColors.sec)),
          ),
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: ts(size: 13, color: AppColors.red)),
          ),
      ],
    );
  }
}

class ShopTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool error;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final double fontSize;
  final double? height;
  final bool mono;
  final bool tabular;

  const ShopTextField({
    super.key,
    this.controller,
    this.hint,
    this.error = false,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.fontSize = 17,
    this.height = 48,
    this.mono = false,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    return Container(
      height: multiline ? null : height,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: multiline ? 12 : 0),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: error ? AppColors.red : Colors.transparent),
      ),
      alignment: multiline ? null : Alignment.centerLeft,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        keyboardType: keyboardType ?? (multiline ? TextInputType.multiline : null),
        maxLines: maxLines,
        cursorColor: AppColors.accent,
        style: TextStyle(
          fontFamily: mono ? kMonoFamily : kFontFamily,
          fontSize: fontSize,
          color: AppColors.text,
          letterSpacing: -0.2,
          height: multiline ? 1.4 : null,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: mono ? kMonoFamily : kFontFamily,
            fontSize: fontSize,
            color: const Color.fromRGBO(60, 60, 67, 0.45),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Phone input that displays "+998 90 123 45 67" while reporting the raw 9-digit
/// local part via [onChanged] (mirrors the prototype's formatted phone inputs).
class PhoneField extends StatefulWidget {
  final String initialRaw;
  final ValueChanged<String> onChanged;
  final bool error;
  final double fontSize;
  final double height;
  final bool autofocus;
  const PhoneField({
    super.key,
    this.initialRaw = '',
    required this.onChanged,
    this.error = false,
    this.fontSize = 17,
    this.height = 48,
    this.autofocus = false,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: formatPhone(widget.initialRaw));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final r = formatPhoneWithCaret(v, _ctrl.selection.baseOffset);
    _ctrl.value = TextEditingValue(
      text: r.text,
      selection: TextSelection.collapsed(offset: r.offset),
    );
    widget.onChanged(normalizePhoneInput(v));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: widget.error ? AppColors.red : Colors.transparent),
      ),
      child: TextField(
        controller: _ctrl,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.phone,
        cursorColor: AppColors.accent,
        onChanged: _onChanged,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: widget.fontSize,
          color: AppColors.text,
          letterSpacing: -0.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '+998',
          hintStyle: TextStyle(
            fontFamily: kFontFamily,
            fontSize: widget.fontSize,
            color: const Color.fromRGBO(60, 60, 67, 0.45),
          ),
        ),
      ),
    );
  }
}

// ── Dashed borders (prototype uses `border: … dashed`) ──────────────────────
class DashedVLine extends StatelessWidget {
  final Color color;
  const DashedVLine({super.key, required this.color});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(1, double.infinity), painter: _VDashPainter(color));
}

class _VDashPainter extends CustomPainter {
  final Color color;
  _VDashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1;
    const dash = 3.0, gap = 3.0;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(0, size.height)), p);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VDashPainter old) => old.color != color;
}

/// Container with a dashed rounded-rect border (and optional fill).
class DashedRRect extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color? fill;
  final double radius;
  final EdgeInsets padding;
  const DashedRRect({
    super.key,
    required this.child,
    required this.borderColor,
    this.fill,
    this.radius = 12,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(borderColor, radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(radius)),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRRectPainter(this.color, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final src = Path()..addRRect(rrect);
    final dashed = Path();
    const dash = 4.0, gap = 4.0;
    for (final m in src.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        dashed.addPath(m.extractPath(d, (d + dash).clamp(0, m.length)), Offset.zero);
        d += dash + gap;
      }
    }
    canvas.drawPath(dashed, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color || old.radius != radius;
}

// ── Profile menu row ────────────────────────────────────────────────────────
class MenuRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;
  final bool isLast;
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.accentDim, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: ts(size: 16.5, color: AppColors.text, letterSpacing: -0.2))),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(detail!, style: ts(size: 14.5, color: AppColors.sec)),
                  ),
                Ic.chevronR(),
              ],
            ),
          ),
          if (!isLast)
            const Positioned(
              left: 58,
              right: 0,
              bottom: 0,
              child: SizedBox(height: 0.5, child: ColoredBox(color: AppColors.sep)),
            ),
        ],
      ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: ts(size: 13, weight: FontWeight.w600, color: AppColors.sec, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

// ── Compact nav header (pushed screens) ─────────────────────────────────────
class NavHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? right;
  const NavHeader({super.key, required this.title, required this.onBack, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.only(top: topInset(context), bottom: 8, left: 8, right: 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: tr2('Орқага', 'Назад'),
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(width: 44, height: 44, child: Center(child: Ic.chevronL(AppColors.accent))),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(size: 17, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.3),
              ),
            ),
          ),
          SizedBox(width: 44, child: Center(child: right ?? const SizedBox.shrink())),
        ],
      ),
    );
  }
}

// ── Large title (root screens) ──────────────────────────────────────────────
class LargeTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const LargeTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        text,
        style: ts(size: 34, weight: FontWeight.w700, color: AppColors.text, letterSpacing: 0.2, height: 41 / 34),
      ),
    );
    if (trailing == null) return title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: title), trailing!],
    );
  }
}

// ── Entrance fade-up (prototype's `shopFadeUp` keyframe) ────────────────────
class FadeUp extends StatelessWidget {
  final Widget child;
  final int ms;
  const FadeUp({super.key, required this.child, this.ms = 450});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: child,
    );
  }
}

// ── Async states (loading / error+retry) ───────────────────────────────────
class CenterLoader extends StatelessWidget {
  final EdgeInsets padding;
  const CenterLoader({super.key, this.padding = const EdgeInsets.symmetric(vertical: 60)});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: padding, child: const Center(child: Spinner()));
}

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const ErrorView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.ter),
            const SizedBox(height: 14),
            Text(
              message ?? tr2('Маълумотни юклаб бўлмади', 'Не удалось загрузить'),
              textAlign: TextAlign.center,
              style: ts(size: 15.5, color: AppColors.sec, letterSpacing: -0.2),
            ),
            const SizedBox(height: 16),
            BigButton(
              ghost: true,
              width: null,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: onRetry,
              child: Text(tr2('Қайта уриниш', 'Повторить')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toast ───────────────────────────────────────────────────────────────────
class Toast extends StatelessWidget {
  final String message;
  final bool show;
  const Toast({super.key, required this.message, required this.show});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 0.2),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(28, 28, 30, 0.92),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: ts(size: 14.5, weight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
